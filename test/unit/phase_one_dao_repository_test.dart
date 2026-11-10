import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/database/repository_providers.dart';
import 'package:bhumi_kajer_hisab/core/errors/app_failure.dart';
import 'package:bhumi_kajer_hisab/core/utils/money.dart';
import 'package:bhumi_kajer_hisab/core/utils/validators.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase createTestDb() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

void main() {
  group('Phase 1: AppFailure ও এরর ম্যাপিং (Non-Technical Natural Bengali)', () {
    test('ডুপ্লিকেট আবেদন নম্বরের জন্য সঠিক বাংলা বার্তা প্রদান করে', () {
      final failure = AppFailure.fromException(
        SqliteException(
          extendedResultCode: 19,
          message: 'UNIQUE constraint failed: applications.app_number',
        ),
      );
      expect(
        failure.message,
        'এই আবেদন নম্বরটি ইতিমধ্যে এই অফিসে সংরক্ষিত আছে। অনুগ্রহ করে নম্বরটি পরীক্ষা করুন।',
      );
      expect(failure.code, 'duplicateAppNumber');
    });

    test('ডিস্ক ফুল এররে প্রাকৃতিক বাংলা বার্তা প্রদান করে', () {
      final failure = AppFailure.fromException(
        SqliteException(
          extendedResultCode: 13,
          message: 'database or disk is full',
        ),
      );
      expect(
        failure.message,
        'আপনার ফোনের মেমোরি পূর্ণ হয়ে গেছে। অনুগ্রহ করে কিছু অপ্রয়োজনীয় ফাইল মুছে পুনরায় চেষ্টা করুন।',
      );
      expect(failure.code, 'diskFull');
    });

    test('স্ন্যাপশট পরিবর্তনের চেষ্টায় সঠিক বার্তা প্রদান করে', () {
      final failure = AppFailure.fromException(
        SqliteException(
          extendedResultCode: 1,
          message: 'application snapshot columns are immutable',
        ),
      );
      expect(
        failure.message,
        'আবেদনকারীর নাম, ফোন, ঠিকানা, রেফারেন্স বা অফিসের নাম একবার সংরক্ষণ করার পর পরিবর্তন করা যায় না।',
      );
    });

    test('পেমেন্ট ও খরচ পরিবর্তনের চেষ্টায় সঠিক বার্তা প্রদান করে', () {
      final payFailure = AppFailure.fromException(
        SqliteException(
          extendedResultCode: 1,
          message: 'payments are immutable; use soft-delete and a new entry',
        ),
      );
      expect(payFailure.code, 'paymentImmutable');

      final expFailure = AppFailure.fromException(
        SqliteException(
          extendedResultCode: 1,
          message: 'expenses are immutable; use soft-delete and a new entry',
        ),
      );
      expect(expFailure.code, 'expenseImmutable');
    });

    test('ডিফল্ট ক্যাটাগরি ডিলিট প্রটেকশন বার্তা', () {
      final failure = AppFailure.cannotDeleteDefaultCategory('সরকারি ফি');
      expect(failure.message, '"সরকারি ফি" সিস্টেমের ডিফল্ট খাত, এটি মুছে ফেলা যাবে না।');
    });

    test('ফরম্যাট এক্সেপশনে টাকার অংক ত্রুটি বার্তা', () {
      final failure = AppFailure.fromException(const FormatException('invalid int'));
      expect(failure.code, 'invalidAmount');
      expect(failure.message, 'টাকার অংকটি সঠিক নয়। অনুগ্রহ করে শুধুমাত্র সংখ্যা লিখুন (যেমন: ৫০০০)।');
    });
  });

  group('Phase 1: ফোন নম্বর স্ট্যান্ডার্ডাইজেশন (বাংলা ও ইংরেজি)', () {
    test('বাংলা ডিজিট ফোন নম্বরকে আদর্শ ১১-ডিজিট ইংরেজিতে রূপান্তর করে', () {
      expect(AppValidators.standardizePhone('০১৭১১২২৩৩৪৪'), '01711223344');
      expect(AppValidators.standardizePhone('০১৮১৯-৯৯৮৮৭৭'), '01819998877');
      expect(AppValidators.standardizePhone('+৮৮০১৯১১০০২২৩৩'), '01911002233');
      expect(AppValidators.standardizePhone('8801819112233'), '01819112233');
    });
  });

  group('Phase 1: ApplicationDao ও ApplicationRepository', () {
    late AppDatabase db;
    late ApplicationRepository appRepo;
    late OfficeRepository officeRepo;
    late PersonRepository personRepo;
    late ReferenceRepository refRepo;

    setUp(() async {
      db = createTestDb();
      appRepo = ApplicationRepository(db);
      officeRepo = OfficeRepository(db);
      personRepo = PersonRepository(db);
      refRepo = ReferenceRepository(db);
    });

    tearDown(() => db.close());

    test('নতুন আবেদন তৈরি ও অপরিবর্তনীয় স্ন্যাপশট স্বয়ংক্রিয় সংরক্ষণ', () async {
      final office = await officeRepo.createOffice(name: 'উপজেলা ভূমি অফিস, সাভার');
      final person = await personRepo.createPerson(
        name: 'মো. রফিকুল ইসলাম',
        phone: '০১৭১১-২২৩৩৪৪',
        address: 'সাভার, ঢাকা',
      );
      final ref = await refRepo.createReference(
        name: 'হাজী আব্দুল করিম',
        phone: '০১৮১৯-০০১১২২',
      );

      final app = await appRepo.createApplication(
        applicantId: person.id,
        applicantName: person.name,
        applicantPhone: person.phone,
        applicantAddress: person.address,
        referenceId: ref.id,
        referenceName: ref.name,
        officeId: office.id,
        officeName: office.name,
        workType: 'ই-নামজারি',
        agreedAmountPaisa: 800000, // ৳৮,০০০
        initialPaymentPaisa: 300000, // ৳৩,০০০
        appNumber: 'APP-1001',
      );

      expect(app.applicantName, 'মো. রফিকুল ইসলাম');
      expect(app.applicantPhone, '01711223344');
      expect(app.officeName, 'উপজেলা ভূমি অফিস, সাভার');
      expect(app.referenceName, 'হাজী আব্দুল করিম');
      expect(app.agreedAmount, 800000);

      // প্রাথমিক জমা স্বয়ংক্রিয় রেকর্ড হয়েছে
      final payments = await db.financeDao.getPaymentsForApplication(app.id);
      expect(payments.length, 1);
      expect(payments.first.amount, 300000);

      // প্রাথমিক স্ট্যাটাস হিস্টোরি রেকর্ড হয়েছে
      final history = await appRepo.getStatusHistory(app.id);
      expect(history.length, 1);
      expect(history.first.newStatus, 'আবেদন');
    });

    test('ডুপ্লিকেট আবেদন নম্বর দিলে AppFailure.duplicateAppNumber ছুড়ে দেয়', () async {
      final office = await officeRepo.createOffice(name: 'কেরানীগঞ্জ রাজস্ব সার্কেল');

      await appRepo.createApplication(
        applicantName: 'আবেদনকারী ১',
        applicantPhone: '01711000000',
        officeId: office.id,
        officeName: office.name,
        workType: 'জমাভাগ',
        agreedAmountPaisa: 500000,
        appNumber: 'DUP-999',
      );

      expect(
        () => appRepo.createApplication(
          applicantName: 'আবেদনকারী ২',
          applicantPhone: '01811000000',
          officeId: office.id,
          officeName: office.name,
          workType: 'জমাভাগ',
          agreedAmountPaisa: 600000,
          appNumber: 'DUP-999',
        ),
        throwsA(isA<AppFailure>().having(
          (f) => f.code,
          'code',
          'duplicateAppNumber',
        )),
      );
    });

    test('বকেয়া মওকুফ ও নিষ্পত্তি (Mark as Paid)', () async {
      final office = await officeRepo.createOffice(name: 'সাভার ভূমি অফিস');
      final app = await appRepo.createApplication(
        applicantName: 'আবেদনকারী',
        applicantPhone: '01711223344',
        officeId: office.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 700000,
      );

      expect(app.isMarkedAsPaid, 0);

      await appRepo.markAsPaid(app.id, true);
      final updated = await appRepo.getApplication(app.id);
      expect(updated!.isMarkedAsPaid, 1);

      await appRepo.markAsPaid(app.id, false);
      final restored = await appRepo.getApplication(app.id);
      expect(restored!.isMarkedAsPaid, 0);
    });

    test('পর্যায়ক্রমিক অবস্থা পরিবর্তন একক ACID ট্রানজ্যাকশনে সম্পন্ন হয়', () async {
      final office = await officeRepo.createOffice(name: 'সাভার ভূমি অফিস');
      final app = await appRepo.createApplication(
        applicantName: 'আবেদনকারী',
        applicantPhone: '01711223344',
        officeId: office.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 800000,
      );

      // অবস্থা পরিবর্তন: আবেদন -> ডিসিআর প্রস্তুত
      // সাথে সরকারি ফি খরচ ৳১,১০০ এবং শুনানির টাস্ক
      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'ডিসিআর প্রস্তুত',
        note: 'শুনানি সম্পন্ন হয়েছে',
        feeExpensePaisa: 110000,
        feeExpenseCategory: 'ডিসিআর ও খতিয়ান ফি',
        paymentReceivedPaisa: 200000,
        hearingTaskTitle: 'ডিসিআর সংগ্রহ',
      );

      final updatedApp = await appRepo.getApplication(app.id);
      expect(updatedApp!.status, 'ডিসিআর প্রস্তুত');

      final history = await appRepo.getStatusHistory(app.id);
      expect(history.length, 2);
      expect(history.first.newStatus, 'ডিসিআর প্রস্তুত');

      final expenses = await db.financeDao.getExpensesForApplication(app.id);
      expect(expenses.length, 1);
      expect(expenses.first.amount, 110000);
      expect(expenses.first.isStatusExp, 1);

      final payments = await db.financeDao.getPaymentsForApplication(app.id);
      expect(payments.length, 1);
      expect(payments.first.amount, 200000);
      expect(payments.first.isStatusFee, 1);

      final tasks = await db.taskDao.getTasks(applicationId: app.id);
      expect(tasks.length, 1);
      expect(tasks.first.title, 'ডিসিআর সংগ্রহ');
    });

    test('আবেদন সফট ডিলিট হলে মেটাডাটা অক্ষত থাকে কিন্তু সংযুক্ত PDF পার্জ (Purge) হয় (সমাধান ক)', () async {
      final office = await officeRepo.createOffice(name: 'কেরানীগঞ্জ ভূমি অফিস');
      final app = await appRepo.createApplication(
        applicantName: 'মোতালেব হোসেন',
        applicantPhone: '01811223344',
        officeId: office.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 600000,
      );

      // ১টি ডামি পিডিএফ ডকুমেন্ট যোগ করি
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.documents).insert(
            DocumentsCompanion.insert(
              id: 'doc-pdf-test-1',
              applicationId: app.id,
              fileName: 'Namjari_Online_Copy.pdf',
              fileType: 'pdf',
              fileData: Uint8List.fromList([37, 80, 68, 70, 45]), // '%PDF-'
              fileSize: '5.2 MB',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // যাচাই করি ডকুমেন্টটি সংরক্ষিত আছে
      final docsBefore = await (db.select(db.documents)..where((t) => t.applicationId.equals(app.id))).get();
      expect(docsBefore.length, 1);

      // আবেদন ডিলিট (সফট ডিলিট + পার্জ)
      await appRepo.deleteApplication(app.id);

      // ১. যাচাই: আবেদন সফট ডিলিট হয়েছে (deletedAt সেট হয়েছে, মেটাডাটা অক্ষত)
      final softDeletedApp = await appRepo.getApplication(app.id, includeDeleted: true);
      expect(softDeletedApp, isNotNull);
      expect(softDeletedApp!.deletedAt, isNotNull);
      expect(softDeletedApp.applicantName, 'মোতালেব হোসেন');

      // ২. যাচাই: সংযুক্ত ভারী পিডিএফ ডেটাবেজ স্টোরেজ থেকে স্থায়ীভাবে মুছে (Purge) গেছে
      final docsAfter = await (db.select(db.documents)..where((t) => t.applicationId.equals(app.id))).get();
      expect(docsAfter, isEmpty);
    });

    test('আবেদনের কোনো ডকুমেন্ট ডিলিট করলে সরাসরি হার্ড ডিলিট (Hard Delete) হয়', () async {
      final office = await officeRepo.createOffice(name: 'কেরানীগঞ্জ ভূমি অফিস');
      final app = await appRepo.createApplication(
        applicantName: 'মোতালেব হোসেন',
        applicantPhone: '01811223344',
        officeId: office.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 600000,
      );

      final doc = await appRepo.addDocument(
        applicationId: app.id,
        fileName: 'DCR_Slip.pdf',
        fileType: 'pdf',
        fileData: Uint8List.fromList([1, 2, 3]),
        fileSize: '1.2 MB',
      );

      // যাচাই: ডকুমেন্ট যোগ হয়েছে
      final before = await appRepo.getDocuments(app.id);
      expect(before.length, 1);

      // ডকুমেন্ট ডিলিট
      await appRepo.deleteDocument(doc.id);

      // যাচাই: ডেটাবেজ টেবিল থেকে রো সরাসরি হার্ড ডিলিট হয়েছে (কোনো সফট ডিলিট নয়)
      final allDocs = await db.select(db.documents).get();
      expect(allDocs, isEmpty);
    });
  });

  group('Phase 1: FinanceDao ও FinanceRepository (100% Strict Accounting Rules)', () {
    late AppDatabase db;
    late FinanceRepository finRepo;
    late ApplicationRepository appRepo;
    late OfficeRepository officeRepo;

    setUp(() async {
      db = createTestDb();
      finRepo = FinanceRepository(db);
      appRepo = ApplicationRepository(db);
      officeRepo = OfficeRepository(db);
    });

    tearDown(() => db.close());

    test('প্রকৃত ইনকাম হিসাব: মোট আদায় - মোট কাজের খরচ (Golden rule §1.2)', () async {
      final office = await officeRepo.createOffice(name: 'মিরপুর ভূমি অফিস');
      final app = await appRepo.createApplication(
        applicantName: 'করিম সাহেব',
        applicantPhone: '01711223344',
        officeId: office.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 800000, // চুক্তি ৳৮,০০০
      );

      // গ্রাহক দিয়েছেন ৳৫,০০০
      await finRepo.addPayment(
        applicationId: app.id,
        amountPaisa: 500000,
      );

      // ফাইলে খরচ হয়েছে ৳২,০০০
      await finRepo.addApplicationExpense(
        applicationId: app.id,
        amountPaisa: 200000,
        category: 'সরকারি ফি',
      );

      final financials = await finRepo.getApplicationFinancials(app.id);
      expect(financials.received, Money.fromTaka(5000));
      expect(financials.expense, Money.fromTaka(2000));
      // প্রকৃত ইনকাম = ৳৫,০০০ - ৳২,০০০ = ৳৩,০০০
      expect(financials.actualIncome, Money.fromTaka(3000));
      // বকেয়া = ৳৮,০০০ - ৳৫,০০০ = ৳৩,০০০
      expect(financials.effectiveDue, Money.fromTaka(3000));
      // সম্ভাব্য চুক্তি ইনকাম = ৳৮,০০০ - ৳২,০০০ = ৳৬,০০০
      expect(financials.estimatedIncome, Money.fromTaka(6000));
    });

    test('দোকানের সামগ্রিক নিট ইনকাম হিসাব (Golden rule §1.2 নিয়ম ৫)', () async {
      final office = await officeRepo.createOffice(name: 'মিরপুর ভূমি অফিস');
      final app = await appRepo.createApplication(
        applicantName: 'করিম সাহেব',
        applicantPhone: '01711223344',
        officeId: office.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 1000000, // চুক্তি ৳১০,০০০
      );

      // ১. আবেদন আদায়: ৳৭,০০০
      await finRepo.addPayment(applicationId: app.id, amountPaisa: 700000);
      // ২. আবেদন খরচ: ৳২,০০০
      await finRepo.addApplicationExpense(
        applicationId: app.id,
        amountPaisa: 200000,
        category: 'কোর্ট ফি',
      );
      // ৩. স্বতন্ত্র দোকান আয়: ৳১,৫০০ (ফটোকপি ও টাইপিং)
      await finRepo.addIndependentIncome(
        category: 'টাইপিং ও প্রিন্টিং',
        amountPaisa: 150000,
      );
      // ৪. দোকানের সাধারণ খরচ: ৳৮০০ (নাস্তা ও চা)
      await finRepo.addGeneralExpense(
        amountPaisa: 80000,
        category: 'নাস্তা',
      );

      final overview = await finRepo.getShopFinancialOverview();

      expect(overview.totalApplicationReceived, 700000);
      expect(overview.totalIndependentIncome, 150000);
      expect(overview.totalApplicationExpense, 200000);
      expect(overview.totalGeneralExpense, 80000);

      // ক্যাশ আয় = ৳৭,০০০ + ৳১,৫০০ = ৳৮,৫০০
      expect(overview.totalCashIncome, Money.fromTaka(8500));
      // ক্যাশ খরচ = ৳২,০০০ + ৳৮০০ = ৳২,৮০০
      expect(overview.totalCashExpense, Money.fromTaka(2800));
      // সামগ্রিক প্রকৃত নিট ইনকাম = ৳৮,৫০০ - ৳২,৮০০ = ৳৫,৭০০
      expect(overview.netRealizedIncome, Money.fromTaka(5700));
    });

    test('আর্থিক লেনদেন সফট ডিলিট ক্যাশবই অডিট ট্রেইল অক্ষত রাখে', () async {
      final office = await officeRepo.createOffice(name: 'মিরপুর ভূমি অফিস');
      final app = await appRepo.createApplication(
        applicantName: 'করিম সাহেব',
        applicantPhone: '01711223344',
        officeId: office.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 1000000,
      );

      final payment = await finRepo.addPayment(
        applicationId: app.id,
        amountPaisa: 400000,
      );

      // সফট ডিলিট
      await finRepo.deletePayment(payment.id);

      // সক্রিয় পেমেন্ট লিস্টে থাকবে না
      final active = await db.financeDao.getPaymentsForApplication(app.id);
      expect(active.isEmpty, true);

      // কিন্তু ডেটাবেজে অডিট ট্রেইল হিসেবে থাকবে
      final allRows = await db.select(db.payments).get();
      expect(allRows.length, 1);
      expect(allRows.first.deletedAt, isNotNull);

      // পুনরুদ্ধার (Undo)
      await finRepo.restorePayment(payment.id);
      final restored = await db.financeDao.getPaymentsForApplication(app.id);
      expect(restored.length, 1);
      expect(restored.first.deletedAt, isNull);
    });
  });

  group('Phase 1: PersonDao ও ReferenceDao স্মার্ট ডিলিট পলিসি', () {
    late AppDatabase db;
    late PersonRepository personRepo;
    late ReferenceRepository refRepo;
    late ApplicationRepository appRepo;
    late OfficeRepository officeRepo;

    setUp(() async {
      db = createTestDb();
      personRepo = PersonRepository(db);
      refRepo = ReferenceRepository(db);
      appRepo = ApplicationRepository(db);
      officeRepo = OfficeRepository(db);
    });

    tearDown(() => db.close());

    test('কোনো ফাইল না থাকলে গ্রাহক সরাসরি হার্ড ডিলিট (SQL DELETE)', () async {
      final person = await personRepo.createPerson(
        name: 'নতুন কাস্টমার',
        phone: '01700112233',
      );

      final deleted = await personRepo.deletePerson(person.id);
      expect(deleted, true);

      // ডেটাবেজ থেকে সম্পূর্ণ মুছে যাবে
      final inDb = await db.personDao.getPersonById(person.id, includeDeleted: true);
      expect(inDb, isNull);
    });

    test('ফাইল থাকলে গ্রাহক সফট ডিলিট হয় এবং অতীত আবেদনে নাম স্ন্যাপশট অক্ষত থাকে', () async {
      final office = await officeRepo.createOffice(name: 'সাভার ভূমি অফিস');
      final person = await personRepo.createPerson(
        name: 'জামাল উদ্দিন',
        phone: '01711223344',
      );

      final app = await appRepo.createApplication(
        applicantId: person.id,
        applicantName: person.name,
        applicantPhone: person.phone,
        officeId: office.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 500000,
      );

      // স্মার্ট ডিলিট
      final deleted = await personRepo.deletePerson(person.id);
      expect(deleted, true);

      // গ্রাহক টেবিলে সফট ডিলিট হিসেবে থাকবে
      final inDb = await db.personDao.getPersonById(person.id, includeDeleted: true);
      expect(inDb, isNotNull);
      expect(inDb!.deletedAt, isNotNull);

      // আবেদনের স্ন্যাপশট অক্ষত থাকে (BACKEND_MASTER_PLAN.md §1.3)
      final existingApp = await appRepo.getApplication(app.id);
      expect(existingApp!.applicantName, 'জামাল উদ্দিন');
      expect(existingApp.applicantPhone, '01711223344');
    });

    test('রেফারেন্স খাতা হিসাব (Reference Ledger Statistics)', () async {
      final office = await officeRepo.createOffice(name: 'সাভার ভূমি অফিস');
      final ref = await refRepo.createReference(
        name: 'মতিউর রহমান',
        phone: '01819000111',
      );

      // ২ টি ফাইল রেফার করলেন
      await appRepo.createApplication(
        applicantName: 'ক্লায়েন্ট ১',
        applicantPhone: '01711111111',
        referenceId: ref.id,
        referenceName: ref.name,
        officeId: office.id,
        officeName: office.name,
        workType: 'ই-নামজারি',
        agreedAmountPaisa: 600000, // ৳৬,০০০
        initialPaymentPaisa: 400000, // জমা ৳৪,০০০
      );

      await appRepo.createApplication(
        applicantName: 'ক্লায়েন্ট ২',
        applicantPhone: '01722222222',
        referenceId: ref.id,
        referenceName: ref.name,
        officeId: office.id,
        officeName: office.name,
        workType: 'খতিয়ান সংশোধন',
        agreedAmountPaisa: 400000, // ৳৪,০০০
        initialPaymentPaisa: 400000, // সম্পূর্ণ পরিশোধ
      );

      final stats = await refRepo.getReferenceStats(ref.id);
      expect(stats.applicationCount, 2);
      expect(stats.totalAgreed, Money.fromTaka(10000));
      expect(stats.totalReceived, Money.fromTaka(8000));
      expect(stats.totalDue, Money.fromTaka(2000));
    });
  });

  group('Phase 1: CategoryDao ও CategoryRepository সফট ডিলিট', () {
    late AppDatabase db;
    late CategoryRepository catRepo;

    setUp(() async {
      db = createTestDb();
      catRepo = CategoryRepository(db);

      // ডিফল্ট ক্যাটাগরি ও কাজের ধরন তৈরি
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.expenseCategories).insert(
            ExpenseCategoriesCompanion.insert(
              id: 'def-exp-1',
              name: 'সরকারি ফি',
              isGeneral: const Value(0),
              isDefault: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.workTypes).insert(
            WorkTypesCompanion.insert(
              id: 'def-wt-1',
              name: 'নামজারি',
              isDefault: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    tearDown(() => db.close());

    test('ডিফল্ট ক্যাটাগরি ও কাজের ধরন সফট ডিলিট করা যায় এবং পুরনো রেকর্ড অক্ষত থাকে',
        () async {
      final expDeleted = await catRepo.deleteExpenseCategory('def-exp-1');
      expect(expDeleted, true);

      final activeExp = await catRepo.getExpenseCategories();
      expect(activeExp.where((c) => c.id == 'def-exp-1'), isEmpty);

      final allExp = await catRepo.getExpenseCategories(includeDeleted: true);
      expect(allExp.singleWhere((c) => c.id == 'def-exp-1').deletedAt, isNotNull);

      final wtDeleted = await catRepo.deleteWorkType('def-wt-1');
      expect(wtDeleted, true);

      final activeWt = await catRepo.getWorkTypes();
      expect(activeWt.where((w) => w.id == 'def-wt-1'), isEmpty);

      final allWt = await catRepo.getWorkTypes(includeDeleted: true);
      expect(allWt.singleWhere((w) => w.id == 'def-wt-1').deletedAt, isNotNull);
    });

    test('ব্যবহারকারীর তৈরি কাস্টম ক্যাটাগরি সফলভাবে তৈরি ও মোছা যায়', () async {
      final custom = await catRepo.createExpenseCategory(
        name: 'সার্ভেয়ার খরচ',
        isGeneral: false,
      );

      expect(custom.name, 'সার্ভেয়ার খরচ');
      expect(custom.isDefault, 0);

      final deleted = await catRepo.deleteExpenseCategory(custom.id);
      expect(deleted, true);
    });
  });

  group('Phase 1: TaskDao ও TaskRepository', () {
    late AppDatabase db;
    late TaskRepository taskRepo;

    setUp(() async {
      db = createTestDb();
      taskRepo = TaskRepository(db);
    });

    tearDown(() => db.close());

    test('টাস্ক তৈরি, সম্পন্ন ও আজকের কাজের গণনা', () async {
      final today = DateTime.now();
      final task = await taskRepo.createTask(
        title: 'এসি ল্যান্ড অফিসে শুনানি',
        dueDate: today,
        priority: 'জরুরি',
        category: 'শুনানি',
      );

      expect(task.title, 'এসি ল্যান্ড অফিসে শুনানি');
      expect(task.status, 'করতে হবে');

      final countBefore = await taskRepo.getTodayTasksCount();
      expect(countBefore, 1);

      await taskRepo.markCompleted(task.id, true);
      final countAfter = await taskRepo.getTodayTasksCount();
      expect(countAfter, 0);

      // অপ্রয়োজনীয় কাজ হার্ড ডিলিট
      await taskRepo.deleteTask(task.id);
      final inDb = await taskRepo.getTask(task.id);
      expect(inDb, isNull);
    });
  });

  group('Phase 1: ShopSettingsDao ও ShopSettingsRepository', () {
    late AppDatabase db;
    late ShopSettingsRepository settingsRepo;

    setUp(() async {
      db = createTestDb();
      settingsRepo = ShopSettingsRepository(db);
    });

    tearDown(() => db.close());

    test('দোকানের সেটিংস আপসার্ট ও সংগ্রহ', () async {
      await settingsRepo.setSetting('shop_name', 'রজব ভূমি সেবা ঘর');
      await settingsRepo.setSetting('proprietor_name', 'রজব আলী');

      final shopName = await settingsRepo.getSetting('shop_name');
      expect(shopName, 'রজব ভূমি সেবা ঘর');

      final all = await settingsRepo.getAllSettings();
      expect(all['shop_name'], 'রজব ভূমি সেবা ঘর');
      expect(all['proprietor_name'], 'রজব আলী');

      // আপডেট
      await settingsRepo.setSetting('shop_name', 'রজব ডিজিটাল ভূমি সেবা');
      final updated = await settingsRepo.getSetting('shop_name');
      expect(updated, 'রজব ডিজিটাল ভূমি সেবা');
    });
  });
}
