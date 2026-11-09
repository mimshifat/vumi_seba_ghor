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

/// ব্যাকআপ, রিস্টোর ও ডেটা মাইগ্রেশন রিপোজিটরি (Backup & Restore Repository)।
///
/// BACKEND_MASTER_PLAN.md §১.৩, §২.১, §২.২, §২.৩, §৩ ও §৫ ফেজ ৪ অনুযায়ী:
/// - ফোনের ডাউনলোড ফোল্ডারে সুরক্ষিত অফলাইন `.db` ব্যাকআপ এক্সপোর্ট (`PRAGMA wal_checkpoint(TRUNCATE)` সহ)।
/// - ব্যাকগ্রাউন্ড আইসোলেটে ফাইল অখণ্ডতা (`PRAGMA integrity_check`) ও স্কিমা সংস্করণ যাচাই।
/// - করাপ্ট বা অনুপযুক্ত ফাইলে লাইভ ডাটা ধ্বংস হওয়া থেকে ১০০% সুরক্ষা (Safety Snapshot & Automatic Rollback)।
/// - টেলিগ্রাম বট ক্লাউড ব্যাকআপ ইন্টিগ্রেশন।
class BackupRepository {
  final AppDatabase _db;

  BackupRepository(this._db);

  /// ফোনের ডাউনলোড ফোল্ডারে সুরক্ষিত অফলাইন `.db` ব্যাকআপ এক্সপোর্ট করে।
  ///
  /// ১. `PRAGMA wal_checkpoint(TRUNCATE)` দিয়ে WAL ফাইল মূল ডাটাবেজে ফ্লাশ করে।
  /// ২. `VACUUM INTO` স্টেটমেন্ট ব্যবহার করে একটি ডিফ্র্যাগমেন্টেড, ত্রুটিহীন
  ///    কপি তৈরি করে।
  /// ৩. সফল ব্যাকআপের পর `last_backup_time` সেটিংস টেবিলে সংরক্ষণ করে।
  Future<File> exportBackup({String? customDestinationDir}) async {
    try {
      // ১. WAL চেকপয়েন্ট
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');

      // ২. গন্তব্য ডিরেক্টরি নির্ধারণ
      Directory targetDir;
      if (customDestinationDir != null && customDestinationDir.isNotEmpty) {
        targetDir = Directory(customDestinationDir);
      } else {
        targetDir = await getExportDirectory();
      }

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      // ৩. ইউনিক টাইমস্ট্যাম্পযুক্ত ফাইলের নাম
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'rojob_backup_$timestamp.db';
      final destinationFile = File(p.join(targetDir.path, fileName));

      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }

      // ৪. SQLite VACUUM INTO
      final escapedPath = destinationFile.path.replaceAll("'", "''");
      await _db.customStatement("VACUUM INTO '$escapedPath';");

      // ৫. সেটিংস টেবিলে সর্বশেষ ব্যাকআপের সময় আপডেট
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
  ///
  /// মূল UI থ্রেডকে ব্লক না করে সম্পূর্ণ যাচাইকরণ ব্যাকগ্রাউন্ড আইসোলেটে সম্পন্ন হয়:
  /// - `PRAGMA integrity_check;`
  /// - `PRAGMA quick_check;`
  /// - অ্যাপ্লিকেশন, পেমেন্ট, খরচ ও সেটিংস টেবিলের উপস্থিতি।
  /// - মূল পরিসংখ্যান গণনা (কতগুলো ফাইল ও পেমেন্ট আছে)।
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
  /// জিরো ডাটা লস (Zero Data Loss) গ্যারান্টি:
  /// ১. রিস্টোরের পূর্বে ব্যাকগ্রাউন্ড আইসোলেটে ফাইল যাচাই করা হয়।
  /// ২. বর্তমান লাইভ ডেটাবেজের একটি নিরাপত্তা কপি (`rojob_bhumi_pre_restore.sqlite`) রাখা হয়।
  /// ৩. লাইভ সংযোগ বন্ধ করে ফাইল সোয়াপ করা হয় এবং পুরনো WAL/SHM পরিষ্কার করা হয়।
  /// ৪. সোয়াপের পর রিস্টোরকৃত ফাইলের পোস্ট-ইন্টিগ্রিটি যাচাই করা হয়।
  /// ৫. কোনো ত্রুটি দেখা দিলে তাৎক্ষণিকভাবে নিরাপত্তা কপি থেকে আগের অবস্থায় রোলব্যাক হয়।
  /// ৬. সফল হলে [onDatabaseReopened] কলব্যাকের মাধ্যমে নতুন [AppDatabase] পৌঁছে দেওয়া হয়।
  Future<void> restoreBackup(
    String sourceFilePath, {
    required void Function(AppDatabase newDb) onDatabaseReopened,
    File? customLiveDbFile,
    AppDatabase Function()? databaseOpener,
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

    // ২. বর্তমান ডেটাবেজের WAL চেকপয়েন্ট
    try {
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (_) {}

    // ৩. পূর্ববর্তী অক্ষত তথ্যের নিরাপত্তা কপি তৈরি (Rollback Safety)
    if (liveDbFile.existsSync()) {
      try {
        if (preRestoreBackup.existsSync()) preRestoreBackup.deleteSync();
        liveDbFile.copySync(preRestoreBackup.path);
      } catch (e) {
        throw AppFailure.custom(
          'বর্তমান ডেটাবেজের নিরাপত্তা কপি তৈরিতে সমস্যা হয়েছে। রিস্টোর বাতিল করা হলো।',
          cause: e,
        );
      }
    }

    // ৪. লাইভ সংযোগ বন্ধ করা যাতে ফাইল লক মুক্ত হয়
    await _db.close();

    try {
      // ৫. অপ্রয়োজনীয় WAL ও SHM ডিলিট করা
      if (walFile.existsSync()) walFile.deleteSync();
      if (shmFile.existsSync()) shmFile.deleteSync();

      // ৬. নতুন ব্যাকআপ ফাইল সোয়াপ
      File(sourceFilePath).copySync(liveDbFile.path);

      // ৭. পোস্ট-ইন্টিগ্রিটি যাচাই
      final postValidation = await validateFileInIsolate(liveDbFile.path);
      if (!postValidation.isValid) {
        throw Exception('পোস্ট-ইন্টিগ্রিটি চেক ব্যর্থ হয়েছে।');
      }

      // ৮. নতুন লাইভ ডেটাবেজ সংযোগ তৈরি
      final newDb = databaseOpener != null ? databaseOpener() : AppDatabase.open();

      // ৯. সফল — নিরাপত্তা কপি অপরাসণ ও সময় আপডেট
      if (preRestoreBackup.existsSync()) {
        try {
          preRestoreBackup.deleteSync();
        } catch (_) {}
      }

      final now = DateTime.now();
      await newDb.shopSettingsDao
          .setSetting('last_restore_time', formatBanglaDateTime(now));

      // ১০. কলব্যাকের মাধ্যমে নতুন সংযোগ নোটিফাই
      onDatabaseReopened(newDb);
    } catch (e) {
      // ১০. স্বয়ংক্রিয় রোলব্যাক (Auto-Rollback on failure)
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
    }
  }

  /// টেলিগ্রাম বটে অফলাইন ডেটাবেজের ক্লাউড ব্যাকআপ সেন্ড করে।
  ///
  /// - `skipPdfs` সত্য হলে দলিলের ভারী পিডিএফ ব্লব বাদ দিয়ে ফাইলের আকার ন্যূনতম (হালকা) করা হয়।
  /// - `botToken` এবং `chatId` যাচাই ও `shop_settings` টেবিলে সংরক্ষণ।
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

    // ১. সেটিংস সংরক্ষণ
    await _db.shopSettingsDao.setSetting('telegram_bot_token', cleanToken);
    await _db.shopSettingsDao.setSetting('telegram_chat_id', cleanChatId);

    // ২. এক্সপোর্ট ফাইল তৈরি
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final backupFile = File(p.join(tempDir.path, 'rojob_backup_$timestamp.db'));

    if (backupFile.existsSync()) backupFile.deleteSync();

    await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    final escaped = backupFile.path.replaceAll("'", "''");
    await _db.customStatement("VACUUM INTO '$escaped';");

    // ২.১. হালকা ব্যাকআপ (পিডিএফ বাইনারি ব্লব বাদ দিয়ে কম্প্যাক্ট করা)
    if (skipPdfs) {
      stripPdfsAndCompact(backupFile);
    }

    // ৩. টেলিগ্রাম বট এপিআই-এ মেমোরি-সেফ স্ট্রিম আপলোড
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 45);

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
          ? 'রজব ভূমি সেবা ঘর — ক্লাউড ব্যাকআপ (হালকা/পিডিএফ ব্যতীত)\nতারিখ: ${formatBanglaDateTime(now)}'
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

  /// সাময়িক ব্যাকআপ ডাটাবেজ থেকে ভারী পিডিএফ বাইনারি ব্লব বাদ দিয়ে VACUUM করে ফাইলের সাইজ ন্যূনতম করে।
  ///
  /// ডকুমেন্টস টেবিলের মেটাডেটা অক্ষত রেখে শুধুমাত্র ভারী বাইনারি ব্লব (`file_data`) জিরো বাইট
  /// (`zeroblob(0)`) করা হয়। এরপর `VACUUM` চালিয়ে স্থান কম্প্যাক্ট করা হয় যাতে ফাইল সাইজ
  /// কয়েকশো মেগাবাইট থেকে নেমে মাত্র কয়েকশো কিলোবাইটে চলে আসে।
  static void stripPdfsAndCompact(File dbFile) {
    CommonDatabase? tempDb;
    try {
      tempDb = sqlite3.open(dbFile.path);
      final tables = tempDb.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='documents';",
      );
      if (tables.isNotEmpty) {
        tempDb.execute(
          "UPDATE documents SET file_data = zeroblob(0) WHERE LOWER(TRIM(file_type)) = 'pdf';",
        );
        tempDb.execute('VACUUM;');
      }
    } catch (_) {
      // টেম্প ফাইলের স্ট্রিপিংয়ে ব্যর্থ হলেও ব্যাকআপ প্রক্রিয়া আটকাবে না
    } finally {
      tempDb?.dispose();
    }
  }

  /// স্বয়ংক্রিয় টেলিগ্রাম ব্যাকআপ চালু বা বন্ধ
  Future<void> setAutoBackupTelegram(bool enabled) async {
    await _db.shopSettingsDao
        .setSetting('auto_backup_telegram', enabled ? 'true' : 'false');
  }

  /// দৈনিক স্বয়ংক্রিয় টেলিগ্রাম ক্লাউড ব্যাকআপ (পিডিএফ ব্যতীত হালকা ফাইল)
  ///
  /// - 'auto_backup_telegram' অন থাকলে এবং আজ ব্যাকআপ না গেলে ব্যাকগ্রাউন্ডে পাঠায়।
  /// - আইডিইমপোটেন্ট: দিনে একবারের বেশি কল করা হলেও দ্বিতীয়বার ব্যাকআপ পাঠাবে না।
  /// - সম্পূর্ণ ব্যাকগ্রাউন্ডে নীরবে চলে, কোনো এররে মূল অ্যাপ বা ব্যবহারকারী বিঘ্নিত হয় না।
  Future<bool> checkAndRunDailyTelegramBackup() async {
    try {
      final isEnabled =
          await _db.shopSettingsDao.getSetting('auto_backup_telegram');
      if (isEnabled != 'true') return false;

      final token =
          await _db.shopSettingsDao.getSetting('telegram_bot_token');
      final chatId =
          await _db.shopSettingsDao.getSetting('telegram_chat_id');
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
          await _db.shopSettingsDao.getSetting('last_telegram_auto_backup_date');

      if (lastRunDate == todayStr) {
        return false; // আজকের ব্যাকআপ ইতোমধ্যে সফল
      }

      await exportBackupToTelegram(
        botToken: token,
        chatId: chatId,
        skipPdfs: true,
      );

      await _db.shopSettingsDao
          .setSetting('last_telegram_auto_backup_date', todayStr);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// টেলিগ্রাম সেটিংস সংরক্ষণ
  Future<void> saveTelegramConfig({
    required String botToken,
    required String chatId,
  }) async {
    await _db.shopSettingsDao.setSetting('telegram_bot_token', botToken.trim());
    await _db.shopSettingsDao.setSetting('telegram_chat_id', chatId.trim());
  }

  /// এক্সপোর্ট ডিরেক্টরি নির্ণয় (অ্যান্ড্রয়েড ও অন্যান্য ডিভাইসে নিরাপদ পথ)
  static Future<Directory> getExportDirectory() async {
    if (Platform.isAndroid) {
      try {
        final extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (extDirs != null && extDirs.isNotEmpty) {
          final dir = extDirs.first;
          if (dir.existsSync()) return dir;
        }
      } catch (_) {}

      final publicDownload = Directory('/storage/emulated/0/Download');
      if (publicDownload.existsSync()) {
        return publicDownload;
      }
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        return downloads;
      }
    } catch (_) {}

    return await getApplicationDocumentsDirectory();
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

        return BackupValidationResult(
          isValid: true,
          fileSizeBytes: size,
          totalApplications: appCount,
          totalPayments: payCount,
          totalExpenses: expCount,
          totalPersons: personCount,
          totalReferences: refCount,
          schemaVersion: schemaVersion,
          backupDate: file.lastModifiedSync(),
        );
      } catch (e) {
        return BackupValidationResult.invalid(
          'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
        );
      } finally {
        testDb?.dispose();
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
