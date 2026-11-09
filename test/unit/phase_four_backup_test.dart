import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/database/database_seeder.dart';
import 'package:bhumi_kajer_hisab/core/errors/app_failure.dart';
import 'package:bhumi_kajer_hisab/features/backup/data/repositories/backup_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File liveDbFile;
  late AppDatabase db;
  late BackupRepository repo;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('rojob_phase4_test_');
    liveDbFile = File('${tempDir.path}/rojob_bhumi.sqlite');
    db = AppDatabase(NativeDatabase(liveDbFile));
    await DatabaseSeeder.seed(db);
    repo = BackupRepository(db);
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 4: অফলাইন .db ব্যাকআপ এক্সপোর্ট (PRAGMA wal_checkpoint ও VACUUM INTO)', () {
    test('সুরক্ষিত .db ব্যাকআপ ফাইল তৈরি হয় এবং সব টেবিল ও রেকর্ড থাকে', () async {
      final exportDir = Directory('${tempDir.path}/exports');
      final backupFile = await repo.exportBackup(
        customDestinationDir: exportDir.path,
      );

      expect(backupFile.existsSync(), isTrue);
      expect(backupFile.lengthSync(), greaterThan(0));
      expect(backupFile.path.endsWith('.db'), isTrue);

      // ব্যাকআপ ফাইল খুলে রেকর্ড যাচাই
      final sqlite = sqlite3.open(backupFile.path, mode: OpenMode.readOnly);
      final check = sqlite.select('PRAGMA integrity_check;');
      expect(check.first.values.first, 'ok');

      final appsCount = sqlite.select('SELECT COUNT(*) as c FROM applications;').first['c'] as int;
      expect(appsCount, greaterThan(0));

      final settingsCount = sqlite.select('SELECT COUNT(*) as c FROM shop_settings;').first['c'] as int;
      expect(settingsCount, greaterThan(0));

      sqlite.close();
    });

    test('ব্যাকআপ সফল হলে shop_settings টেবিলে last_backup_time সংরক্ষিত হয়', () async {
      final exportDir = Directory('${tempDir.path}/exports');
      await repo.exportBackup(customDestinationDir: exportDir.path);

      final lastBackup = await db.shopSettingsDao.getSetting('last_backup_time');
      expect(lastBackup, isNotNull);
      expect(lastBackup, contains('২০২৬'));
    });
  });

  group('Phase 4: ব্যাকগ্রাউন্ড আইসোলেটে ফাইল ইন্টিগ্রিটি ও স্কিমা সংস্করণ যাচাই', () {
    test('বৈধ ব্যাকআপ ফাইলে সব প্রয়োজনীয় টেবিল ও পরিসংখ্যান সঠিকভাবে সংগৃহীত হয়', () async {
      final exportDir = Directory('${tempDir.path}/exports');
      final backupFile = await repo.exportBackup(
        customDestinationDir: exportDir.path,
      );

      final result = await repo.validateBackupFile(backupFile.path);

      expect(result.isValid, isTrue);
      expect(result.totalApplications, greaterThan(0));
      expect(result.totalPayments, greaterThan(0));
      expect(result.fileSizeBytes, greaterThan(0));
      expect(result.schemaVersion, 1);
    });

    test('করাপ্ট বা নষ্ট ফাইলে isValid false হয় এবং সম্মানজনক বাংলা বার্তা দেয়', () async {
      final corruptFile = File('${tempDir.path}/corrupt.db');
      corruptFile.writeAsStringSync('THIS IS CORRUPT DATA NOT A SQLITE DB');

      final result = await repo.validateBackupFile(corruptFile.path);

      expect(result.isValid, isFalse);
      expect(
        result.errorMessage,
        'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
      );
    });

    test('অন্য কোনো অ্যাপের SQLite ফাইল দিলে (আবশ্যক টেবিল না থাকলে) বাতিল করে', () async {
      final alienDbFile = File('${tempDir.path}/alien.db');
      final alienSqlite = sqlite3.open(alienDbFile.path);
      try {
        alienSqlite.execute('CREATE TABLE dummy (id INT, text TEXT);');
        alienSqlite.execute("INSERT INTO dummy VALUES (1, 'hello');");
      } finally {
        alienSqlite.close();
      }

      final result = await repo.validateBackupFile(alienDbFile.path);

      expect(result.isValid, isFalse);
      expect(
        result.errorMessage,
        'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
      );
    });

    test('অস্তিত্বহীন ফাইল পাথে invalid ফলাফল প্রদান করে', () async {
      final result = await repo.validateBackupFile('${tempDir.path}/non_existent.db');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('পাওয়া যায়নি'));
    });
  });

  group('Phase 4: রিস্টোর প্রসেস ও নিরাপত্তা (জিরো ডাটা লস ও অটোমেটিক রোলব্যাক)', () {
    test('বৈধ ব্যাকআপ থেকে সফলভাবে ডেটা রিস্টোর সম্পন্ন হয়', () async {
      // ১. প্রাথমিক ডেটাবেজ থেকে ব্যাকআপ তৈরি
      final exportDir = Directory('${tempDir.path}/exports');
      final backupFile = await repo.exportBackup(
        customDestinationDir: exportDir.path,
      );

      // ২. বর্তমান ডেটাবেজে অতিরিক্ত নতুন আবেদন সংযোজন
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.applications).insert(
        ApplicationsCompanion.insert(
          id: 'temp-app-999',
          applicantName: 'অস্থায়ী ব্যক্তি',
          applicantPhone: '01899999999',
          officeName: 'সদর ভূমি অফিস',
          workType: 'নামজারি',
          applicationDate: now,
          status: 'আবেদন',
          agreedAmount: 500000,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final appsBefore = await db.select(db.applications).get();
      expect(appsBefore.any((a) => a.id == 'temp-app-999'), isTrue);

      // ৩. রিস্টোর কার্যকর করা
      AppDatabase? reopenedDb;
      await repo.restoreBackup(
        backupFile.path,
        customLiveDbFile: liveDbFile,
        databaseOpener: () => AppDatabase(NativeDatabase(liveDbFile)),
        onDatabaseReopened: (newDb) {
          reopenedDb = newDb;
        },
      );

      expect(reopenedDb, isNotNull);
      final appsAfter = await reopenedDb!.select(reopenedDb!.applications).get();
      // অস্থায়ী আবেদন আর নেই — পূর্বাবস্থায় ফিরে গেছে
      expect(appsAfter.any((a) => a.id == 'temp-app-999'), isFalse);

      await reopenedDb!.close();
    });

    test('নষ্ট ব্যাকআপ ফাইল দিয়ে রিস্টোর চেষ্টা করলে তা প্রত্যাখ্যাত হয় এবং বর্তমান তথ্য অক্ষত থাকে', () async {
      final appsBefore = await db.select(db.applications).get();
      final originalCount = appsBefore.length;

      final corruptFile = File('${tempDir.path}/corrupt_attempt.db');
      corruptFile.writeAsStringSync('CORRUPTED BYTES');

      expect(
        () => repo.restoreBackup(
          corruptFile.path,
          customLiveDbFile: liveDbFile,
          onDatabaseReopened: (_) {},
        ),
        throwsA(isA<AppFailure>()),
      );

      // লাইভ ডেটাবেজ অক্ষত রয়েছে কিনা যাচাই
      final appsAfter = await db.select(db.applications).get();
      expect(appsAfter.length, originalCount);
    });
  });

  group('Phase 4: টেলিগ্রাম সেটিংস ও প্রাকৃতিক বাংলা ফরম্যাটিং', () {
    test('টেলিগ্রাম বট সেটিংস সংরক্ষণ ও পুনরুদ্ধার', () async {
      await repo.saveTelegramConfig(
        botToken: '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
        chatId: '987654321',
      );

      final token = await db.shopSettingsDao.getSetting('telegram_bot_token');
      final chat = await db.shopSettingsDao.getSetting('telegram_chat_id');

      expect(token, '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11');
      expect(chat, '987654321');
    });

    test('ফাঁকা টেলিগ্রাম সেটিংস দিলে AppFailure নিক্ষেপ করে', () async {
      expect(
        () => repo.exportBackupToTelegram(botToken: '', chatId: ''),
        throwsA(isA<AppFailure>()),
      );
    });

    test('formatBanglaDateTime প্রাকৃতিক বাংলায় রূপান্তর করে', () {
      final testDate = DateTime(2026, 11, 9, 15, 30);
      final formatted = BackupRepository.formatBanglaDateTime(testDate);
      expect(formatted, contains('০৯'));
      expect(formatted, contains('নভেম্বর'));
      expect(formatted, contains('২০২৬'));
      expect(formatted, contains('বিকাল ০৩:৩০'));
    });

    test('stripPdfsAndCompact পিডিএফ বাইনারি ব্লব খালি করে কিন্তু অন্যান্য রেকর্ড অক্ষত রাখে', () async {
      final exportDir = Directory('${tempDir.path}/strip_test');
      final backupFile = await repo.exportBackup(customDestinationDir: exportDir.path);

      // ব্যাকআপ ফাইলে একটি ডামি পিডিএফ ও ইমেজ ডকুমেন্ট ইনসার্ট করি
      final sqlite = sqlite3.open(backupFile.path);
      final appRow = sqlite.select('SELECT id FROM applications LIMIT 1;');
      final appId = appRow.first['id'] as String;

      sqlite.execute('''
        INSERT INTO documents (id, application_id, file_name, file_type, file_data, file_size, created_at, updated_at)
        VALUES ('doc-pdf-1', '$appId', 'porcha.pdf', 'pdf', zeroblob(1024 * 50), '50 KB', 1700000000, 1700000000),
               ('doc-img-1', '$appId', 'photo.jpg', 'image', zeroblob(1024 * 10), '10 KB', 1700000000, 1700000000);
      ''');
      sqlite.close();

      // stripPdfsAndCompact কল করি
      BackupRepository.stripPdfsAndCompact(backupFile);

      // ফাইল পুনরায় খুলে যাচাই করি
      final verifyDb = sqlite3.open(backupFile.path, mode: OpenMode.readOnly);
      final pdfDoc = verifyDb.select("SELECT file_data, file_name FROM documents WHERE id='doc-pdf-1';").first;
      final pdfBytes = pdfDoc['file_data'] as List<int>;
      expect(pdfBytes.length, 0); // পিডিএফ বাইনারি ০ বাইট হয়েছে
      expect(pdfDoc['file_name'], 'porcha.pdf'); // ফাইলের নাম ও মেটাডেটা অক্ষত

      final imgDoc = verifyDb.select("SELECT file_data FROM documents WHERE id='doc-img-1';").first;
      final imgBytes = imgDoc['file_data'] as List<int>;
      expect(imgBytes.length, 1024 * 10); // ইমেজ বাইনারি অক্ষত আছে

      verifyDb.close();
    });

    test('দৈনিক অটো-ব্যাকআপ সেটিং ও চেকার সঠিকভাবে আচরণ করে', () async {
      await repo.setAutoBackupTelegram(true);
      final isEnabled = await db.shopSettingsDao.getSetting('auto_backup_telegram');
      expect(isEnabled, 'true');

      // বট টোকেন ছাড়া checkAndRunDailyTelegramBackup false রিটার্ন করে
      final resultWithoutToken = await repo.checkAndRunDailyTelegramBackup();
      expect(resultWithoutToken, isFalse);
    });
  });
}
