import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/common.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../domain/models/backup_validation_result.dart';
import '../datasources/telegram_config_store.dart';

/// ব্যাকআপ, রিস্টোর ও ডেটা মাইগ্রেশন রিপোজিটরি (Backup & Restore Repository)।
///
/// BACKEND_MASTER_PLAN.md §১.৩, §২.১, §২.২, §২.৩, §৩ ও §৫ ফেজ ৪ অনুযায়ী:
/// - ফোনের নিরাপদ ফোল্ডারে অফলাইন `.db` ব্যাকআপ এক্সপোর্ট (`PRAGMA wal_checkpoint(TRUNCATE)` সহ)।
/// - ব্যাকআপ ফাইলের স্টোরেজ প্রুনিং (অতিরিক্ত ফাইল জমা হওয়া রোধে সর্বশেষ ৫টি ফাইল সংরক্ষণ)।
/// - ব্যাকগ্রাউন্ড আইসোলেটে ফাইল অখণ্ডতা (`PRAGMA integrity_check`) ও স্কিমা সংস্করণ যাচাই।
/// - করাপ্ট বা ভুল ফাইলে লাইভ ডাটা ধ্বংস হওয়া থেকে ১০০% সুরক্ষা (Safety Archive Snapshot & Automatic Rollback)।
/// - টেলিগ্রাম বট ক্লাউড ব্যাকআপ ইন্টিগ্রেশন (বট ক্রেডেনশিয়াল SQLite-এর বাইরে নিরাপদ App-Private স্টোরেজে সংরক্ষিত)।
class BackupRepository {
  final AppDatabase _db;
  final TelegramConfigStore _configStore;

  BackupRepository(this._db, {TelegramConfigStore? configStore})
      : _configStore = configStore ?? TelegramConfigStore.instance;

  TelegramConfigStore get configStore => _configStore;

  /// ফোনের নিরাপদ ফোল্ডারে অফলাইন `.db` ব্যাকআপ এক্সপোর্ট করে।
  ///
  /// ১. ব্যাকআপ ফাইলের নিরাপত্তা নিশ্চিত করতে SQLite ডাটাবেজ থেকে যদি কোনো পূর্ববর্তী
  ///    টেলিগ্রাম টোকেন বা চ্যাট আইডি থাকে তা মুছে ফেলে।
  /// ২. `PRAGMA wal_checkpoint(TRUNCATE)` দিয়ে WAL ফাইল মূল ডাটাবেজে ফ্লাশ করে।
  /// ৩. `VACUUM INTO` স্টেটমেন্ট ব্যবহার করে একটি ডিফ্র্যাগমেন্টেড, ত্রুটিহীন কপি তৈরি করে।
  /// ৪. ডিভাইসের স্টোরেজ বাঁচাতে পুরনো ব্যাকআপ ফাইল প্রুন করে (সর্বশেষ ৫টি রাখা হয়)।
  /// ৫. সফল ব্যাকআপের পর `last_backup_time` সেটিংস টেবিলে সংরক্ষণ করে।
  Future<File> exportBackup({String? customDestinationDir}) async {
    try {
      // ১. টোকেন যাতে ডেটাবেজে কখনই না যায় তা নিশ্চিত করা
      try {
        await _db.customStatement(
          "DELETE FROM shop_settings WHERE key IN ('telegram_bot_token', 'telegram_chat_id');",
        );
      } catch (_) {}

      // ২. WAL চেকপয়েন্ট
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

      // ৩. গন্তব্য ডিরেক্টরি নির্ধারণ
      Directory targetDir;
      if (customDestinationDir != null && customDestinationDir.isNotEmpty) {
        targetDir = Directory(customDestinationDir);
      } else {
        targetDir = await getExportDirectory();
      }

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      // ৪. ইউনিক টাইমস্ট্যাম্পযুক্ত ফাইলের নাম
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'rojob_backup_$timestamp.db';
      final destinationFile = File(p.join(targetDir.path, fileName));

      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }

      // ৫. SQLite VACUUM INTO
      final escapedPath = destinationFile.path.replaceAll("'", "''");
      await _db.customStatement("VACUUM INTO '$escapedPath';");

      // ৬. অতিরিক্ত পুরনো ব্যাকআপ প্রুনিং (সর্বোচ্চ ৫টি ফাইল রাখা)
      _pruneOldBackups(targetDir, maxKeep: 5);

      // ৭. সেটিংস টেবিলে সর্বশেষ ব্যাকআপের সময় আপডেট
      final formattedTime = formatBanglaDateTime(now);
      await _db.shopSettingsDao.setSetting('last_backup_time', formattedTime);

      return destinationFile;
    } on FileSystemException catch (e) {
      throw AppFailure.diskFull(e);
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      throw AppFailure.fromException(e, stack);
    }
  }

  /// ব্যাকআপ ফাইলের বৈধতা ও অখণ্ডতা পরীক্ষা করে (Background Isolate-এ)।
  Future<BackupValidationResult> validateBackupFile(String filePath) async {
    try {
      return await validateFileInIsolate(filePath);
    } catch (e) {
      return BackupValidationResult.invalid(
        'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
      );
    }
  }

  /// ব্যাকআপ ফাইল থেকে সম্পূর্ণ ডেটাবেজ রিস্টোর করে।
  ///
  /// জিরো ডাটা লস (Zero Data Loss) ও অ্যাকসিডেন্টাল ওভাররাইট প্রটেকশন:
  /// ১. রিস্টোরের পূর্বে ব্যাকগ্রাউন্ড আইসোলেটে ফাইল যাচাই করা হয়।
  /// ২. বর্তমান লাইভ ডেটাবেজের একটি টাইমস্ট্যাম্পযুক্ত নিরাপত্তা আর্কাইভ রাখা হয়
  ///    (`rojob_bhumi_pre_restore_[timestamp].sqlite`), যাতে ইউজার ভুল ফাইল রিস্টোর করলেও রিভার্ট করতে পারেন।
  /// ৩. লাইভ সংযোগ বন্ধ করে ফাইল সোয়াপ করা হয় এবং পুরনো WAL/SHM পরিষ্কার করা হয়।
  /// ৪. সোয়াপের পর রিস্টোরকৃত ফাইলের পোস্ট-ইন্টিগ্রিটি যাচাই করা হয়।
  /// ৫. কোনো ত্রুটি দেখা দিলে তাৎক্ষণিকভাবে নিরাপত্তা কপি থেকে আগের অবস্থায় রোলব্যাক হয়।
  /// ৬. রিস্টোরকৃত ডাটাবেজে পুরনো কোনো টেলিগ্রাম ক্রেডেনশিয়াল থাকলে তা স্বয়ংক্রিয়ভাবে মুছে ফেলা হয়।
  /// ৭. সফল হলে [onDatabaseReopened] কলব্যাকের মাধ্যমে নতুন [AppDatabase] পৌঁছে দেওয়া হয়।
  Future<void> restoreBackup(
    String sourceFilePath, {
    required void Function(AppDatabase newDb) onDatabaseReopened,
    File? customLiveDbFile,
    AppDatabase Function()? databaseOpener,
    bool preserveCurrentSettings = true,
  }) async {
    // ১. ব্যাকগ্রাউন্ড আইসোলেটে ইনপুট ফাইল ভ্যালিডেশন
    final validation = await validateFileInIsolate(sourceFilePath);
    if (!validation.isValid) {
      throw AppFailure.corruptBackup(validation.errorMessage);
    }

    final liveDbFile = customLiveDbFile ?? await AppDatabase.getDatabaseFile();
    final liveDbDir = liveDbFile.parent;
    final walFile = File('${liveDbFile.path}-wal');
    final shmFile = File('${liveDbFile.path}-shm');
    final preRestoreBackup =
        File(p.join(liveDbDir.path, 'rojob_bhumi_pre_restore.sqlite'));
    final stagingFile =
        File(p.join(liveDbDir.path, 'rojob_bhumi_restore_stage.sqlite'));

    // ২. বর্তমান ডেটাবেজের WAL চেকপয়েন্ট
    try {
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (_) {}

    // ৩. পূর্ববর্তী অক্ষত তথ্যের নিরাপত্তা কপি তৈরি (Rollback Safety & Accidental Restore Archive)
    if (liveDbFile.existsSync()) {
      try {
        if (preRestoreBackup.existsSync()) preRestoreBackup.deleteSync();
        liveDbFile.copySync(preRestoreBackup.path);

        // ভুল ব্যাকআপ রিস্টোরের ক্ষতিপূরণে স্থায়ী টাইমস্ট্যাম্পড আর্কাইভ কপি রাখা
        _archivePreRestoreSnapshot(liveDbFile, liveDbDir, maxKeep: 3);
      } catch (e) {
        throw AppFailure.custom(
          'বর্তমান ডেটাবেজের নিরাপত্তা কপি তৈরিতে সমস্যা হয়েছে। রিস্টোর বাতিল করা হলো।',
          cause: e,
        );
      }
    }

    // ৪. নিরাপদ স্টেজিং ফাইলে কপি
    try {
      if (stagingFile.existsSync()) stagingFile.deleteSync();
      File(sourceFilePath).copySync(stagingFile.path);
    } catch (e) {
      throw AppFailure.custom('রিস্টোর ফাইলটি লোড করা যায়নি।', cause: e);
    }

    // ৫. লাইভ সংযোগ বন্ধ করা যাতে ফাইল লক মুক্ত হয়
    await _db.close();

    try {
      // ৬. অপ্রয়োজনীয় WAL ও SHM ডিলিট করা
      if (walFile.existsSync()) walFile.deleteSync();
      if (shmFile.existsSync()) shmFile.deleteSync();

      // ৭. স্টেজিং ফাইল থেকে মূল লাইভ ডেটাবেজে সোয়াপ
      stagingFile.copySync(liveDbFile.path);
      if (stagingFile.existsSync()) stagingFile.deleteSync();

      // ৮. পোস্ট-ইন্টিগ্রিটি যাচাই
      final postValidation = await validateFileInIsolate(liveDbFile.path);
      if (!postValidation.isValid) {
        throw Exception('পোস্ট-ইন্টিগ্রিটি চেক ব্যর্থ হয়েছে।');
      }

      // ৯. নতুন লাইভ ডেটাবেজ সংযোগ তৈরি
      final newDb =
          databaseOpener != null ? databaseOpener() : AppDatabase.open();

      // ১০. রিস্টোরকৃত ডাটাবেজে পুরনো কোনো টেলিগ্রাম টোকেন থাকলে তা মুছে ফেলা
      try {
        await newDb.customStatement(
          "DELETE FROM shop_settings WHERE key IN ('telegram_bot_token', 'telegram_chat_id');",
        );
      } catch (_) {}

      // ১১. সফল — সময় আপডেট
      final now = DateTime.now();
      await newDb.shopSettingsDao
          .setSetting('last_restore_time', formatBanglaDateTime(now));

      // সাময়িক প্রি-রিস্টোর ফাইলটি সরানো (তবে টাইমস্ট্যাম্পড সেফটি আর্কাইভ অক্ষত থাকবে)
      if (preRestoreBackup.existsSync()) {
        try {
          preRestoreBackup.deleteSync();
        } catch (_) {}
      }

      // ১২. কলব্যাকের মাধ্যমে নতুন সংযোগ নোটিফাই
      onDatabaseReopened(newDb);
    } catch (e) {
      // স্বয়ংক্রিয় রোলব্যাক (Auto-Rollback on failure)
      try {
        if (preRestoreBackup.existsSync()) {
          if (walFile.existsSync()) walFile.deleteSync();
          if (shmFile.existsSync()) shmFile.deleteSync();
          preRestoreBackup.copySync(liveDbFile.path);
          preRestoreBackup.deleteSync();
        }
      } catch (_) {}

      // পূর্বের মূল ডেটাবেজ পুনরায় চালু রাখা
      try {
        final restoredDb =
            databaseOpener != null ? databaseOpener() : AppDatabase.open();
        onDatabaseReopened(restoredDb);
      } catch (_) {}

      if (e is AppFailure) rethrow;
      throw AppFailure.corruptBackup(e);
    } finally {
      if (stagingFile.existsSync()) {
        try {
          stagingFile.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// টেলিগ্রাম বটে অফলাইন ডেটাবেজের ক্লাউড ব্যাকআপ সেন্ড করে।
  ///
  /// - `skipPdfs` সত্য হলে দলিলের ভারী পিডিএফ ব্লব বাদ দিয়ে ফাইলের আকার ন্যূনতম (হালকা) করা হয়।
  /// - `botToken` এবং `chatId` যাচাই ও ডেডিকেটেড অ্যাপ-প্রাইভেট কনফিগে সংরক্ষণ (SQLite-এ নয়)।
  /// - সাময়িক ডিফ্র্যাগমেন্টেড `.db` ফাইল তৈরি ও মেমোরি-সেফ ফাইল স্ট্রিমিংয়ের মাধ্যমে টেলিগ্রামে আপলোড।
  /// - সফল হলে `last_backup_time` আপডেট ও সাময়িক ফাইল অপরাসণ।
  Future<void> exportBackupToTelegram({
    required String botToken,
    required String chatId,
    bool skipPdfs = true,
  }) async {
    final cleanToken = botToken.trim();
    final cleanChatId = chatId.trim();

    if (cleanToken.isEmpty || cleanChatId.isEmpty) {
      throw AppFailure.custom(
        'টেলিগ্রাম বট টোকেন ও চ্যাট আইডি প্রদান করুন।',
        code: 'invalidTelegramSettings',
      );
    }

    // ১. সেটিংস সংরক্ষণ (SQLite-এ নয়, ডেডিকেটেড অ্যাপ-প্রাইভেট কনফিগ স্টোরে)
    await _configStore.saveCredentials(botToken: cleanToken, chatId: cleanChatId);

    // ২. এক্সপোর্ট ফাইল তৈরি (পূর্বে ফেলে রাখা কোনো অনাথ টেম্প ফাইল থাকলে তা পরিষ্কার)
    final tempDir = await getTemporaryDirectory();
    _cleanupOrphanedTempBackups(tempDir);

    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}_${now.second.toString().padLeft(2, '0')}_${now.microsecond}';
    final backupFile = File(p.join(tempDir.path, 'rojob_backup_$timestamp.db'));

    if (backupFile.existsSync()) backupFile.deleteSync();

    // টোকেন ডাটাবেজে নেই নিশ্চিত করে VACUUM INTO চালানো
    try {
      await _db.customStatement(
        "DELETE FROM shop_settings WHERE key IN ('telegram_bot_token', 'telegram_chat_id');",
      );
    } catch (_) {}

    await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    final escaped = backupFile.path.replaceAll("'", "''");
    await _db.customStatement("VACUUM INTO '$escaped';");

    // ২.১. হালকা ব্যাকআপ (সব ধরনের ভারী বাইনারি ব্লব বাদ দিয়ে কম্প্যাক্ট করা)
    if (skipPdfs) {
      stripDocumentsAndCompact(backupFile);
    }

    // ৩. টেলিগ্রাম বট এপিআই-এ মেমোরি-সেফ স্ট্রিম আপলোড
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 60);

      final uri =
          Uri.parse('https://api.telegram.org/bot$cleanToken/sendDocument');
      final request = await client.postUrl(uri);

      final boundary =
          '----RojobBackupBoundary${DateTime.now().millisecondsSinceEpoch}';
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      final caption = skipPdfs
          ? 'রজব ভূমি সেবা ঘর — ক্লাউড ব্যাকআপ (হালকা/পিডিএফ ও ছবি ব্যতীত)\nতারিখ: ${formatBanglaDateTime(now)}'
          : 'রজব ভূমি সেবা ঘর — ক্লাউড ব্যাকআপ\nতারিখ: ${formatBanglaDateTime(now)}';
      final fileName = skipPdfs
          ? 'rojob_backup_light_$timestamp.db'
          : 'rojob_backup_$timestamp.db';
      final fileSize = backupFile.lengthSync();

      final part1 = utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="chat_id"\r\n\r\n'
        '$cleanChatId\r\n'
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="caption"\r\n\r\n'
        '$caption\r\n'
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="document"; filename="$fileName"\r\n'
        'Content-Type: application/octet-stream\r\n\r\n',
      );
      final part2 = utf8.encode('\r\n--$boundary--\r\n');

      request.contentLength = part1.length + fileSize + part2.length;
      request.add(part1);
      await request.addStream(backupFile.openRead());
      request.add(part2);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        throw AppFailure.custom(
          'টেলিগ্রাম বটে ফাইল পাঠানো যায়নি। অনুগ্রহ করে টোকেন ও চ্যাট আইডি যাচাই করুন।',
          code: 'telegramApiError',
          cause: responseBody,
        );
      }

      // ৪. সফল হলে সর্বশেষ ব্যাকআপ সময় আপডেট
      final formattedTime = formatBanglaDateTime(now);
      await _db.shopSettingsDao.setSetting('last_backup_time', formattedTime);
    } on SocketException catch (e) {
      throw AppFailure.custom(
        'ইন্টারনেট সংযোগ পাওয়া যায়নি। ক্লাউড ব্যাকআপের জন্য ইন্টারনেট সংযোগ প্রয়োজন।',
        code: 'noInternet',
        cause: e,
      );
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure.custom(
        'টেলিগ্রামে ব্যাকআপ পাঠাতে সমস্যা হয়েছে। ইন্টারনেট সংযোগ ও বট সেটিংস পরীক্ষা করুন।',
        cause: e,
      );
    } finally {
      if (backupFile.existsSync()) {
        try {
          backupFile.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// সাময়িক ব্যাকআপ ডাটাবেজ থেকে ভারী পিডিএফ ও ইমেজ বাইনারি ব্লব বাদ দিয়ে VACUUM করে ফাইলের সাইজ ন্যূনতম করে।
  static void stripDocumentsAndCompact(File dbFile) {
    CommonDatabase? tempDb;
    try {
      tempDb = sqlite3.open(dbFile.path);
      final tables = tempDb.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='documents';",
      );
      if (tables.isNotEmpty) {
        tempDb.execute(
          "UPDATE documents SET file_data = zeroblob(0);",
        );
        tempDb.execute('VACUUM;');
      }
    } catch (_) {
    } finally {
      tempDb?.close();
    }
  }

  static void stripPdfsAndCompact(File dbFile) =>
      stripDocumentsAndCompact(dbFile);

  /// স্বয়ংক্রিয় টেলিগ্রাম ব্যাকআপ চালু বা বন্ধ
  Future<void> setAutoBackupTelegram(bool enabled) async {
    await _configStore.setAutoBackup(enabled);
  }

  /// দৈনিক স্বয়ংক্রিয় টেলিগ্রাম ক্লাউড ব্যাকআপ (পিডিএফ ও ছবি ব্যতীত হালকা ফাইল)
  ///
  /// - 'auto_backup_telegram' অন থাকলে এবং আজ ব্যাকআপ না গেলে ব্যাকগ্রাউন্ডে পাঠায়।
  /// - আইডিইমপোটেন্ট: দিনে একবারের বেশি কল করা হলেও দ্বিতীয়বার ব্যাকআপ পাঠাবে না।
  /// - সম্পূর্ণ ব্যাকগ্রাউন্ডে চলে এবং ব্যর্থ হলেও এরর রেকর্ড রাখে যাতে ইউজার সতর্ক হতে পারে।
  Future<bool> checkAndRunDailyTelegramBackup() async {
    try {
      final isEnabled =
          await _configStore.getSetting('auto_backup_telegram');
      if (isEnabled != 'true') return false;

      final token =
          await _configStore.getSetting('telegram_bot_token');
      final chatId =
          await _configStore.getSetting('telegram_chat_id');
      if (token == null ||
          token.trim().isEmpty ||
          chatId == null ||
          chatId.trim().isEmpty) {
        return false;
      }

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastRunDate =
          await _configStore.getSetting('last_telegram_auto_backup_date');

      if (lastRunDate == todayStr) {
        return false; // আজকের ব্যাকআপ ইতোমধ্যে সফল
      }

      await exportBackupToTelegram(
        botToken: token,
        chatId: chatId,
        skipPdfs: true,
      );

      await _configStore.recordBackupSuccess(todayStr);
      return true;
    } catch (e) {
      try {
        final now = DateTime.now();
        final errTime = formatBanglaDateTime(now);
        final errMsg = e is AppFailure
            ? e.message
            : 'টেলিগ্রামে ব্যাকআপ পাঠানো যায়নি। ইন্টারনেট সংযোগ পরীক্ষা করুন।';
        await _configStore.recordBackupFailure(
          errorMessage: errMsg,
          attemptTime: errTime,
        );
      } catch (_) {}
      return false;
    }
  }

  /// টেলিগ্রাম সেটিংস সংরক্ষণ
  Future<void> saveTelegramConfig({
    required String botToken,
    required String chatId,
  }) async {
    await _configStore.saveCredentials(botToken: botToken, chatId: chatId);
    try {
      await _db.customStatement(
        "DELETE FROM shop_settings WHERE key IN ('telegram_bot_token', 'telegram_chat_id');",
      );
    } catch (_) {}
  }

  /// এক্সপোর্ট ডিরেক্টরি নির্ণয় (অ্যান্ড্রয়েড ১০/১১+ ও অন্যান্য ডিভাইসে নিরাপদ পথ)
  static Future<Directory> getExportDirectory() async {
    if (Platform.isAndroid) {
      // প্রথমে সরাসরি পাবলিক ডাউনলোড ফোল্ডারে লেখার অনুমতি পরীক্ষা করা
      final publicDownload = Directory('/storage/emulated/0/Download');
      if (publicDownload.existsSync()) {
        try {
          final probe = File(p.join(publicDownload.path, '.rojob_write_probe'));
          probe.writeAsStringSync('probe');
          probe.deleteSync();
          return publicDownload;
        } catch (_) {}
      }

      // Scoped Storage থাকলে অ্যাপের নিজস্ব এক্সটার্নাল স্টোরেজ ব্যবহার করা
      try {
        final extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (extDirs != null && extDirs.isNotEmpty) {
          final dir = extDirs.first;
          if (dir.existsSync()) return dir;
        }
      } catch (_) {}
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        return downloads;
      }
    } catch (_) {}

    return await getApplicationDocumentsDirectory();
  }

  /// সর্বশেষ সংরক্ষিত ব্যাকআপ ফাইল পাওয়া (যদি থাকে)
  Future<File?> getLatestBackupFile() async {
    try {
      final targetDir = await getExportDirectory();
      if (!targetDir.existsSync()) return null;
      final files = targetDir
          .listSync()
          .whereType<File>()
          .where((f) =>
              p.basename(f.path).startsWith('rojob_backup_') &&
              f.path.endsWith('.db'))
          .toList();
      if (files.isEmpty) return null;
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files.first;
    } catch (_) {
      return null;
    }
  }

  /// পুরনো ব্যাকআপ প্রুনিং (সর্বোচ্চ [maxKeep] টি ব্যাকআপ ফাইল রেখে অতিরিক্ত পুরনো ফাইল মুছে ফেলা)
  static void _pruneOldBackups(Directory dir, {int maxKeep = 5}) {
    try {
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) =>
              p.basename(f.path).startsWith('rojob_backup_') &&
              f.path.endsWith('.db'))
          .toList();

      if (files.length <= maxKeep) return;

      // সর্বশেষ পরিবর্তনের সময় অনুসারে সাজানো (নতুন থেকে পুরনো)
      files.sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // অতিরিক্ত পুরনো ফাইলগুলো ডিলিট করা
      for (int i = maxKeep; i < files.length; i++) {
        try {
          files[i].deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// ভুল রিস্টোরের বিপরীতে লাইভ ডেটাবেজের স্থায়ী টাইমস্ট্যাম্পড নিরাপত্তা আর্কাইভ কপি রাখা
  static void _archivePreRestoreSnapshot(
      File sourceDb, Directory targetDir, {int maxKeep = 3}) {
    try {
      final now = DateTime.now();
      final ts =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final archiveFile =
          File(p.join(targetDir.path, 'rojob_bhumi_pre_restore_$ts.sqlite'));
      sourceDb.copySync(archiveFile.path);

      // ৩টির বেশি পুরনো প্রাক-রিস্টোর কপি থাকলে প্রুন করা
      final oldArchives = targetDir
          .listSync()
          .whereType<File>()
          .where((f) =>
              p.basename(f.path).startsWith('rojob_bhumi_pre_restore_') &&
              f.path.endsWith('.sqlite'))
          .toList();

      if (oldArchives.length > maxKeep) {
        oldArchives.sort((a, b) =>
            b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        for (int i = maxKeep; i < oldArchives.length; i++) {
          try {
            oldArchives[i].deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// সাময়িক টেম্প ব্যাকআপ ফাইল মুছে পরিষ্কার করা
  static void _cleanupOrphanedTempBackups(Directory tempDir) {
    try {
      final orphaned = tempDir
          .listSync()
          .whereType<File>()
          .where((f) =>
              p.basename(f.path).startsWith('rojob_backup_') &&
              f.path.endsWith('.db'))
          .toList();
      for (final f in orphaned) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// ব্যাকগ্রাউন্ড আইসোলেটে SQLite ফাইলের অখণ্ডতা পরীক্ষা
  static Future<BackupValidationResult> validateFileInIsolate(
      String filePath) async {
    return await Isolate.run(() {
      final file = File(filePath);
      if (!file.existsSync()) {
        return BackupValidationResult.invalid('ফাইলটি পাওয়া যায়নি।');
      }
      final size = file.lengthSync();
      if (size == 0) {
        return BackupValidationResult.invalid('ফাইলটি সম্পূর্ণ খালি।');
      }

      CommonDatabase? testDb;
      try {
        testDb = sqlite3.open(filePath, mode: OpenMode.readOnly);

        // ১. PRAGMA integrity_check
        final integrityRows = testDb.select('PRAGMA integrity_check;');
        if (integrityRows.isEmpty || integrityRows.first.values.first != 'ok') {
          return BackupValidationResult.invalid(
            'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
          );
        }

        // ২. PRAGMA quick_check
        final quickRows = testDb.select('PRAGMA quick_check;');
        if (quickRows.isEmpty || quickRows.first.values.first != 'ok') {
          return BackupValidationResult.invalid(
            'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
          );
        }

        // ৩. আবশ্যক টেবিলসমূহের যাচাই
        final requiredTables = [
          'applications',
          'payments',
          'expenses',
          'persons',
          'references',
          'offices',
          'shop_settings',
        ];
        final tableRows = testDb.select(
          "SELECT name FROM sqlite_master WHERE type='table';",
        );
        final existingTables =
            tableRows.map((r) => r['name'] as String).toSet();
        for (final t in requiredTables) {
          if (!existingTables.contains(t)) {
            return BackupValidationResult.invalid(
              'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
            );
          }
        }

        // ৪. রেকর্ড পরিসংখ্যান সংগ্রহ
        final appCount = (testDb
                    .select('SELECT COUNT(*) as c FROM applications;')
                    .first['c'] as int?) ??
            0;
        final payCount = (testDb
                    .select('SELECT COUNT(*) as c FROM payments;')
                    .first['c'] as int?) ??
            0;
        final expCount = (testDb
                    .select('SELECT COUNT(*) as c FROM expenses;')
                    .first['c'] as int?) ??
            0;
        final personCount = (testDb
                    .select('SELECT COUNT(*) as c FROM persons;')
                    .first['c'] as int?) ??
            0;
        final refCount = (testDb
                    .select('SELECT COUNT(*) as c FROM "references";')
                    .first['c'] as int?) ??
            0;

        int schemaVersion = 1;
        try {
          final versionRows = testDb.select('PRAGMA user_version;');
          if (versionRows.isNotEmpty) {
            schemaVersion = (versionRows.first.values.first as int?) ?? 1;
          }
        } catch (_) {}

        // স্কিমা সংস্করণ বর্তমান অ্যাপের চেয়ে বেশি হলে রিজেক্ট করা
        if (schemaVersion > AppDatabase.currentSchemaVersion) {
          return BackupValidationResult.invalid(
            'বাছাইকৃত ব্যাকআপ ফাইলটি অ্যাপের নতুন সংস্করণ (Version $schemaVersion) থেকে তৈরি। '
            'ফাইলটি রিস্টোর করতে অনুগ্রহ করে অ্যাপটি প্লে-স্টোর থেকে সর্বশেষ সংস্করণে আপডেট করুন।',
          );
        }

        // ৫. হালকা ব্যাকআপ শনাক্তকরণ (ডকুমেন্টস টেবিলের সব বাইনারি ব্লব শূন্য কিনা)
        bool isLightweight = false;
        try {
          final docStats = testDb.select(
            "SELECT COUNT(*) as total_docs, "
            "SUM(CASE WHEN length(file_data) = 0 THEN 1 ELSE 0 END) as empty_docs "
            "FROM documents WHERE deleted_at IS NULL;",
          );
          if (docStats.isNotEmpty) {
            final totalDocs = (docStats.first['total_docs'] as int?) ?? 0;
            final emptyDocs = (docStats.first['empty_docs'] as int?) ?? 0;
            if (totalDocs > 0 && emptyDocs == totalDocs) {
              isLightweight = true;
            }
          }
        } catch (_) {}

        return BackupValidationResult(
          isValid: true,
          fileSizeBytes: size,
          totalApplications: appCount,
          totalPayments: payCount,
          totalExpenses: expCount,
          totalPersons: personCount,
          totalReferences: refCount,
          schemaVersion: schemaVersion,
          isLightweight: isLightweight,
          backupDate: file.lastModifiedSync(),
        );
      } catch (e) {
        return BackupValidationResult.invalid(
          'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
        );
      } finally {
        testDb?.close();
      }
    });
  }

  /// প্রাকৃতিক বাংলায় তারিখ ও সময় ফরম্যাটিং
  static String formatBanglaDateTime(DateTime dt) {
    final day = BengaliDigits.toBengali(dt.day.toString().padLeft(2, '0'));
    const months = [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    final month = months[dt.month - 1];
    final year = BengaliDigits.toBengali(dt.year.toString());

    final period = dt.hour < 12
        ? 'সকাল'
        : (dt.hour < 15 ? 'দুপুর' : (dt.hour < 18 ? 'বিকাল' : 'রাত'));
    final displayHour =
        dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final hour = BengaliDigits.toBengali(displayHour.toString().padLeft(2, '0'));
    final minute = BengaliDigits.toBengali(dt.minute.toString().padLeft(2, '0'));

    return '$day $month $year, $period $hour:$minute';
  }
}
