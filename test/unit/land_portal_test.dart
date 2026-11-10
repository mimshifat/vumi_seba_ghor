import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/errors/app_failure.dart';
import 'package:bhumi_kajer_hisab/features/applications/data/repositories/application_repository.dart';
import 'package:bhumi_kajer_hisab/features/applications/data/services/land_portal_helper.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
