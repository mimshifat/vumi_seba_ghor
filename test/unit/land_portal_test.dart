import 'dart:io';

import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/errors/app_failure.dart';
import 'package:bhumi_kajer_hisab/features/applications/data/repositories/application_repository.dart';
import 'package:bhumi_kajer_hisab/features/applications/data/services/land_portal_helper.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw_sqlite;

AppDatabase _createTestDb() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

void main() {
  group('LandPortalHelper Tests', () {
    test('বাংলা, +880, 00880 এবং ০-যুক্ত মোবাইল নম্বরকে ১০ ডিজিটে রূপান্তর করে', () {
      expect(LandPortalHelper.toTenDigitPortalMobile('01711223344'), '1711223344');
      expect(LandPortalHelper.toTenDigitPortalMobile('০১৭১১২২৩৩৪৪'), '1711223344');
      expect(LandPortalHelper.toTenDigitPortalMobile('+8801711223344'), '1711223344');
      expect(LandPortalHelper.toTenDigitPortalMobile('008801711223344'), '1711223344');
      expect(LandPortalHelper.toTenDigitPortalMobile('8801812-345678'), '1812345678');
      expect(LandPortalHelper.toTenDigitPortalMobile('1911223344'), '1911223344');
      expect(LandPortalHelper.toTenDigitPortalMobile('user@example.com'), 'user@example.com');
    });

    test('Content-Disposition এবং ফাইলনেম স্যানিটাইজেশন সঠিকভাবে কাজ করে', () {
      expect(
        LandPortalHelper.extractFileNameFromContentDisposition(
          'attachment; filename="dcr_receipt.pdf"',
        ),
        'dcr_receipt.pdf',
      );
      expect(
        LandPortalHelper.extractFileNameFromContentDisposition(
          "attachment; filename*=UTF-8''khatian%20copy.pdf",
        ),
        'khatian copy.pdf',
      );
      expect(
        LandPortalHelper.sanitizeFileName('khatian:2026/01?.pdf'),
        'khatian_2026_01_.pdf',
      );
      expect(
        LandPortalHelper.sanitizeFileName('receipt_123', fallbackExtension: 'pdf'),
        'receipt_123.pdf',
      );
    });

    test('buildLsgAutofillScript বিশেষ ক্যারেক্টার নিরাপদে এস্কেপ করে, onlyIfEmpty সমর্থন করে এবং ক্যাপচা স্পর্শ করে না', () {
      const trickyPass = r'''A$bc'45"d3\n&!''';
      final autoScript = LandPortalHelper.buildLsgAutofillScript(
        mobile: '০১৭১১২২৩৩৪৪',
        password: trickyPass,
        onlyIfEmpty: true,
      );

      expect(autoScript, contains('"1711223344"'));
      expect(autoScript, contains('onlyIfEmpty = true'));
      expect(autoScript, contains('see-password'));
      expect(autoScript, contains('mobile'));
      expect(autoScript, isNot(contains('mainCaptcha')));
      expect(autoScript, isNot(contains('txtInput')));

      final manualScript = LandPortalHelper.buildLsgAutofillScript(
        mobile: '01711223344',
        password: 'pass',
        onlyIfEmpty: false,
      );
      expect(manualScript, contains('onlyIfEmpty = false'));
      expect(manualScript, contains('isEmail = false'));

      final emailScript = LandPortalHelper.buildLsgAutofillScript(
        mobile: 'user@example.com',
        password: 'pass',
        onlyIfEmpty: true,
      );
      expect(emailScript, contains('"user@example.com"'));
      expect(emailScript, contains('isEmail = true'));
    });

    test('isInternalWebScheme এবং extractIntentFallbackUrl নিরাপদে কাজ করে', () {
      expect(LandPortalHelper.isInternalWebScheme('https'), isTrue);
      expect(LandPortalHelper.isInternalWebScheme('http'), isTrue);
      expect(LandPortalHelper.isInternalWebScheme('blob'), isTrue);
      expect(LandPortalHelper.isInternalWebScheme('data'), isTrue);
      expect(LandPortalHelper.isInternalWebScheme('intent'), isFalse);
      expect(LandPortalHelper.isInternalWebScheme('tel'), isFalse);

      expect(
        LandPortalHelper.extractIntentFallbackUrl(
          'intent://pay#Intent;scheme=bkash;S.browser_fallback_url=https%3A%2F%2Fpay.land.gov.bd%2Fcheckout;end',
        ),
        'https://pay.land.gov.bd/checkout',
      );
      expect(
        LandPortalHelper.extractIntentFallbackUrl(
          'intent://pay#Intent;S.browser_fallback_url=javascript%3Aalert(1);end',
        ),
        isNull,
      );
      expect(
        LandPortalHelper.extractIntentFallbackUrl('https://land.gov.bd'),
        isNull,
      );
    });
  });

  group('Portal Credentials Database Persistence Tests', () {
    late AppDatabase db;
    late ApplicationRepository repo;

    setUp(() {
      db = _createTestDb();
      repo = ApplicationRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('আবেদনে আলাদা পোর্টাল নম্বর ও পাসওয়ার্ড ডেটাবেজে সংরক্ষিত হয় এবং fallback কাজ করে', () async {
      final appWithCustom = await repo.createApplication(
        applicantName: 'করিম মিয়া',
        applicantPhone: '01711223344',
        officeName: 'উপজেলা ভূমি অফিস, সাভার',
        workType: 'নামজারি',
        appNumber: 'APP-001',
        agreedAmountPaisa: 500000,
        portalPhone: '০১৮৯৯৮৮৭৭৬৬',
        portalPassword: r'Pass$1234!',
      );

      expect(appWithCustom.applicantPhone, '01711223344');
      expect(appWithCustom.portalPhone, '01899887766');
      expect(appWithCustom.portalPassword, r'Pass$1234!');

      final withFinCustom = await repo.getApplicationWithFinancials(appWithCustom.id);
      expect(withFinCustom, isNotNull);
      expect(withFinCustom!.toDemoApplication().effectivePortalPhone, '01899887766');

      final appWithSamePhone = await repo.createApplication(
        applicantName: 'রহিম উদ্দিন',
        applicantPhone: '01755667788',
        officeName: 'উপজেলা ভূমি অফিস, সাভার',
        workType: 'নামজারি',
        appNumber: 'APP-002',
        agreedAmountPaisa: 500000,
        portalPassword: 'MyPassword99',
      );

      expect(appWithSamePhone.portalPhone, isNull);
      expect(appWithSamePhone.portalPassword, 'MyPassword99');

      final withFinSame = await repo.getApplicationWithFinancials(appWithSamePhone.id);
      expect(withFinSame!.toDemoApplication().effectivePortalPhone, '01755667788');
    });

    test('আবেদন সম্পাদনা করে পোর্টাল নম্বর ও পাসওয়ার্ড আপডেট করা যায় এবং অবৈধ নম্বর প্রত্যাখ্যাত হয়', () async {
      final created = await repo.createApplication(
        applicantName: 'জামাল হোসেন',
        applicantPhone: '01711000111',
        officeName: 'উপজেলা ভূমি অফিস, সাভার',
        workType: 'নামজারি',
        appNumber: 'APP-003',
        agreedAmountPaisa: 600000,
      );

      await repo.updateApplication(
        id: created.id,
        portalPhone: '01911222333',
        portalPassword: 'NewSecret#1',
        updatePortalCredentials: true,
      );

      final updated = await repo.getApplication(created.id);
      expect(updated, isNotNull);
      expect(updated!.portalPhone, '01911222333');
      expect(updated.portalPassword, 'NewSecret#1');
      expect(updated.applicantPhone, '01711000111');

      await expectLater(
        () => repo.updateApplication(
          id: created.id,
          portalPhone: '12345',
          updatePortalCredentials: true,
        ),
        throwsA(isA<AppFailure>()),
      );

      await expectLater(
        () => repo.createApplication(
          applicantName: 'টেস্ট',
          applicantPhone: '01711000222',
          officeName: 'উপজেলা ভূমি অফিস, সাভার',
          workType: 'নামজারি',
          appNumber: 'APP-004',
          agreedAmountPaisa: 500000,
          portalPhone: '123',
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('পুরনো v2 ডেটাবেজ আপগ্রেড করলে আগের আবেদন অক্ষত থাকে ও পোর্টাল তথ্য যোগ করা যায়', () async {
      final tempDir = Directory.systemTemp.createTempSync('rojob_v2_upgrade_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final dbFile = File('${tempDir.path}/rojob_v2.sqlite');

      // ১. পুরনো v2 স্কিমা (portal_phone/portal_password ছাড়া) ও পুরনো আবেদন তৈরি
      final raw = raw_sqlite.sqlite3.open(dbFile.path);
      final now = DateTime.now().millisecondsSinceEpoch;
      raw.execute('''
        CREATE TABLE persons (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          address TEXT,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE "references" (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          address TEXT,
          photo BLOB,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE offices (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE applications (
          id TEXT PRIMARY KEY NOT NULL,
          applicant_id TEXT REFERENCES persons(id) ON DELETE SET NULL,
          applicant_name TEXT NOT NULL,
          applicant_phone TEXT NOT NULL,
          applicant_address TEXT,
          reference_id TEXT REFERENCES "references"(id) ON DELETE SET NULL,
          reference_name TEXT,
          office_id TEXT REFERENCES offices(id) ON DELETE SET NULL,
          office_name TEXT NOT NULL,
          mouza TEXT,
          app_number TEXT,
          case_number TEXT,
          work_type TEXT NOT NULL,
          application_date INTEGER NOT NULL,
          status TEXT NOT NULL,
          agreed_amount INTEGER NOT NULL,
          is_marked_as_paid INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE payments (
          id TEXT PRIMARY KEY NOT NULL,
          application_id TEXT NOT NULL REFERENCES applications(id),
          amount INTEGER NOT NULL,
          date INTEGER NOT NULL,
          method TEXT NOT NULL,
          note TEXT,
          status_history_id TEXT,
          status_name TEXT,
          is_status_fee INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE expenses (
          id TEXT PRIMARY KEY NOT NULL,
          application_id TEXT REFERENCES applications(id),
          amount INTEGER NOT NULL,
          category TEXT NOT NULL,
          date INTEGER NOT NULL,
          is_general INTEGER NOT NULL DEFAULT 0,
          note TEXT,
          status_history_id TEXT,
          status_name TEXT,
          is_status_exp INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE proposal_print_batches (
          id TEXT PRIMARY KEY NOT NULL,
          office_name TEXT,
          printed_at INTEGER NOT NULL,
          item_count INTEGER NOT NULL DEFAULT 0,
          note TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE proposal_print_batch_items (
          id TEXT PRIMARY KEY NOT NULL,
          batch_id TEXT NOT NULL REFERENCES proposal_print_batches(id),
          application_id TEXT NOT NULL REFERENCES applications(id),
          status_history_id TEXT,
          applicant_name TEXT NOT NULL,
          case_number TEXT,
          office_name TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TRIGGER applications_snapshot_immutable
        BEFORE UPDATE ON applications
        FOR EACH ROW
        WHEN OLD.applicant_name IS NOT NEW.applicant_name
          OR OLD.applicant_phone IS NOT NEW.applicant_phone
          OR OLD.applicant_address IS NOT NEW.applicant_address
          OR OLD.reference_name IS NOT NEW.reference_name
          OR OLD.office_name IS NOT NEW.office_name
        BEGIN
          SELECT RAISE(ABORT, 'application snapshot columns are immutable');
        END;
        INSERT INTO applications (
          id, applicant_name, applicant_phone, office_name, work_type,
          application_date, status, agreed_amount, is_marked_as_paid,
          created_at, updated_at
        ) VALUES (
          'old-app-1', 'পুরনো গ্রাহক', '01712345678', 'উপজেলা ভূমি অফিস, সাভার',
          'নামজারি', $now, 'আবেদন', 800000, 0, $now, $now
        );
        PRAGMA user_version = 2;
      ''');
      raw.close();

      // ২. নতুন v3 AppDatabase দিয়ে খোলা ও আপগ্রেড যাচাই
      final upgradedDb = AppDatabase(NativeDatabase(dbFile));
      try {
        final upgradedRepo = ApplicationRepository(upgradedDb);
        final oldWithFin =
            await upgradedRepo.getApplicationWithFinancials('old-app-1');
        expect(oldWithFin, isNotNull);
        expect(oldWithFin!.application.applicantName, 'পুরনো গ্রাহক');
        expect(oldWithFin.application.portalPhone, isNull);
        expect(oldWithFin.application.portalPassword, isNull);
        expect(oldWithFin.toDemoApplication().effectivePortalPhone, '01712345678');

        // ৩. পুরনো আবেদনে পরে পোর্টাল পাসওয়ার্ড যোগ করা যায়
        await upgradedRepo.updateApplication(
          id: 'old-app-1',
          portalPassword: 'UpgradedPass#1',
          updatePortalCredentials: true,
        );
        final updated = await upgradedRepo.getApplication('old-app-1');
        expect(updated!.portalPassword, 'UpgradedPass#1');

        final ver =
            await upgradedDb.customSelect('PRAGMA user_version;').getSingle();
        expect(ver.read<int>('user_version'), 3);
      } finally {
        await upgradedDb.close();
      }
    });
  });
}
