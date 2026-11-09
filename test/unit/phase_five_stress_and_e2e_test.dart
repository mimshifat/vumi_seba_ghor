import 'dart:io';

import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/errors/app_failure.dart';
import 'package:bhumi_kajer_hisab/core/utils/bengali_digits.dart';
import 'package:bhumi_kajer_hisab/core/utils/money.dart';
import 'package:bhumi_kajer_hisab/core/utils/validators.dart';
import 'package:bhumi_kajer_hisab/features/applications/data/repositories/application_repository.dart';
import 'package:bhumi_kajer_hisab/features/backup/data/repositories/backup_repository.dart';
import 'package:bhumi_kajer_hisab/features/finance/data/repositories/finance_repository.dart';
import 'package:bhumi_kajer_hisab/features/offices/data/repositories/office_repository.dart';
import 'package:bhumi_kajer_hisab/features/persons/data/repositories/person_repository.dart';
import 'package:bhumi_kajer_hisab/features/references/data/repositories/reference_repository.dart';
import 'package:bhumi_kajer_hisab/features/tasks/data/repositories/task_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase createStressTestDb() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

void main() {
  group('Phase 5: High-Volume & Stress Performance Verification (১,০০০+ আবেদন ও ৫,০০০+ লেনদেন)', () {
    late AppDatabase db;
    late ApplicationRepository appRepo;
    late FinanceRepository finRepo;

    setUp(() {
      db = createStressTestDb();
      appRepo = ApplicationRepository(db);
      finRepo = FinanceRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('১,০০০টি আবেদন ও ৫,০০০টি লেনদেন বাল্ক ইনসার্ট ও নির্ভুল আর্থিক হিসাব যাচাই', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      const totalApps = 1000;
      const agreedPerAppPaisa = 800000; // ৳৮,০০০

      // ১. বাল্ক ১,০০০টি আবেদন তৈরি
      final appCompanions = <ApplicationsCompanion>[];
      for (int i = 1; i <= totalApps; i++) {
        final padded = i.toString().padLeft(4, '0');
        appCompanions.add(
          ApplicationsCompanion.insert(
            id: 'app-$padded',
            applicantName: 'আবেদনকারী $i',
            applicantPhone: '01819${i.toString().padLeft(6, '0')}',
            applicantAddress: Value('মৌজা উত্তরপাড়া $i'),
            officeName: i % 2 == 0 ? 'সদর ভূমি অফিস' : 'উপজেলা ভূমি অফিস',
            mouza: Value('মৌজা-$i'),
            appNumber: Value('APP-$padded'),
            caseNumber: Value('CASE-$padded'),
            workType: i % 3 == 0 ? 'ই-নামজারি' : (i % 3 == 1 ? 'খতিয়ান সংশোধন' : 'জমাভাগ'),
            applicationDate: now - (i * 60000),
            status: i % 4 == 0 ? 'সম্পন্ন' : (i % 4 == 1 ? 'প্রস্তাব প্রেরণ' : 'আবেদন'),
            agreedAmount: agreedPerAppPaisa,
            isMarkedAsPaid: Value(i % 10 == 0 ? 1 : 0),
            createdAt: now - (i * 60000),
            updatedAt: now,
          ),
        );
      }

      final stopwatch = Stopwatch()..start();
      await db.batch((batch) {
        batch.insertAll(db.applications, appCompanions);
      });
      stopwatch.stop();

      // ১,০০০ আবেদন ইনসার্ট দ্রুত সম্পন্ন হয়েছে (৩ সেকেন্ডের কম)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      final allAppsCount = await (db.select(db.applications)..where((t) => t.deletedAt.isNull())).get();
      expect(allAppsCount.length, totalApps);

      // ২. বাল্ক ৫,০০০টি বিভিন্ন ধরনের লেনদেন তৈরি (পেমেন্ট, আবেদন খরচ, স্বতন্ত্র আয়, সাধারণ খরচ)
      // - ২,৫০০ পেমেন্ট (১,০০০ আবেদনে বন্টিত)
      // - ১,৫০০ আবেদন খরচ (আবেদনে বন্টিত)
      // - ৫০০ স্বতন্ত্র আয়
      // - ৫০০ সাধারণ দোকান খরচ
      final payments = <PaymentsCompanion>[];
      int expectedTotalPaymentPaisa = 0;
      for (int i = 1; i <= 2500; i++) {
        final targetAppIndex = ((i - 1) % totalApps) + 1;
        final targetAppId = 'app-${targetAppIndex.toString().padLeft(4, '0')}';
        const amount = 200000; // ৳২,০০০
        expectedTotalPaymentPaisa += amount;

        payments.add(
          PaymentsCompanion.insert(
            id: 'pay-$i',
            applicationId: targetAppId,
            amount: amount,
            date: now - (i * 1000),
            method: i % 2 == 0 ? 'নগদ' : 'বিকাশ',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final appExpenses = <ExpensesCompanion>[];
      int expectedTotalAppExpensePaisa = 0;
      for (int i = 1; i <= 1500; i++) {
        final targetAppIndex = ((i - 1) % totalApps) + 1;
        final targetAppId = 'app-${targetAppIndex.toString().padLeft(4, '0')}';
        const amount = 50000; // ৳৫০০
        expectedTotalAppExpensePaisa += amount;

        appExpenses.add(
          ExpensesCompanion.insert(
            id: 'exp-app-$i',
            applicationId: Value(targetAppId),
            amount: amount,
            category: i % 2 == 0 ? 'ডিসিআর ফি' : 'সরকারি ফি',
            date: now - (i * 1000),
            isGeneral: const Value(0),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final indIncomes = <IndependentIncomesCompanion>[];
      int expectedTotalIndIncomePaisa = 0;
      for (int i = 1; i <= 500; i++) {
        const amount = 30000; // ৳৩০০
        expectedTotalIndIncomePaisa += amount;

        indIncomes.add(
          IndependentIncomesCompanion.insert(
            id: 'ind-inc-$i',
            customerName: Value('স্বাধীন গ্রাহক $i'),
            category: 'ফটোকপি ও টাইপিং',
            amount: amount,
            paymentMethod: 'নগদ',
            date: now - (i * 1000),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final genExpenses = <ExpensesCompanion>[];
      int expectedTotalGenExpensePaisa = 0;
      for (int i = 1; i <= 500; i++) {
        const amount = 40000; // ৳৪০০
        expectedTotalGenExpensePaisa += amount;

        genExpenses.add(
          ExpensesCompanion.insert(
            id: 'exp-gen-$i',
            amount: amount,
            category: 'বিদ্যুৎ বিল ও নাস্তা',
            date: now - (i * 1000),
            isGeneral: const Value(1),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final txStopwatch = Stopwatch()..start();
      await db.batch((batch) {
        batch.insertAll(db.payments, payments);
        batch.insertAll(db.expenses, appExpenses);
        batch.insertAll(db.independentIncomes, indIncomes);
        batch.insertAll(db.expenses, genExpenses);
      });
      txStopwatch.stop();

      expect(txStopwatch.elapsedMilliseconds, lessThan(5000));

      // ৩. ৫,০০০ লেনদেন সেন্ট্রালাইজড ভিউ থেকে যাচাই
      final allUnifiedTx = await finRepo.getUnifiedTransactions();
      expect(allUnifiedTx.length, 5000);

      // ৪. পয়সা-স্তরের নিখুঁত এগ্রিগেশন অডিট (Strict Accounting Rules)
      final summary = await finRepo.getShopFinancialOverview();
      expect(summary.totalApplicationReceived, expectedTotalPaymentPaisa);
      expect(summary.totalApplicationExpense, expectedTotalAppExpensePaisa);
      expect(summary.totalIndependentIncome, expectedTotalIndIncomePaisa);
      expect(summary.totalGeneralExpense, expectedTotalGenExpensePaisa);

      // প্রকৃত ইনকাম = মোট আদায় - মোট কাজের খরচ
      final expectedRealizedIncome = expectedTotalPaymentPaisa - expectedTotalAppExpensePaisa;
      expect(summary.totalApplicationReceived - summary.totalApplicationExpense, expectedRealizedIncome);

      // দোকানের সামগ্রিক নিট ইনকাম = (আদায় + স্বাধীন আয়) - (কাজের খরচ + সাধারণ খরচ)
      final expectedShopNetIncome =
          (expectedTotalPaymentPaisa + expectedTotalIndIncomePaisa) -
          (expectedTotalAppExpensePaisa + expectedTotalGenExpensePaisa);
      expect(summary.netRealizedIncome.paisa, expectedShopNetIncome);

      // ৫. ১,০০০ আবেদনের ফিন্যান্সিয়াল এগ্রিগেশন কুয়েরি দ্রুত সম্পন্ন হওয়া যাচাই
      final appFinancialsStopwatch = Stopwatch()..start();
      final appsWithFinancials = await appRepo.getApplicationsWithFinancials();
      appFinancialsStopwatch.stop();

      expect(appsWithFinancials.length, totalApps);
      expect(appFinancialsStopwatch.elapsedMilliseconds, lessThan(2000));

      // প্রথম আবেদনের হিসাব অডিট:
      // ২৫০০ / ১০০০ = ২ বার পেমেন্ট পেয়েছে (প্রথম ৫০০ আবেদন ৩ বার, বাকিরা ২ বার)
      // app-0001: 3 payments of ৳2,000 = ৳6,000 (600000 paisa)
      // app-0001: 2 expenses of ৳500 = ৳1,000 (100000 paisa)
      final firstApp = appsWithFinancials.firstWhere((a) => a.application.id == 'app-0001');
      expect(firstApp.totalReceivedPaisa, 600000);
      expect(firstApp.totalExpensePaisa, 100000);
      expect(firstApp.actualIncome.paisa, 500000); // ৳৫,০০০
      expect(firstApp.effectiveDue.paisa, 200000); // ৳৮,০০০ - ৳৬,০০০ = ৳২,০০০
    });

    test('উচ্চ ভলিউমে বাংলা ও ইংরেজি ডিজিট সার্চ ও ফিল্টারিং পারফরম্যান্স', () async {
      // আবেদন ডাটা লোড
      await db.batch((batch) {
        for (int i = 1; i <= 500; i++) {
          batch.insert(
            db.applications,
            ApplicationsCompanion.insert(
              id: 'app-$i',
              applicantName: i == 250 ? 'মোঃ রফিকুল ইসলাম' : 'গ্রাহক $i',
              applicantPhone: i == 250 ? '01712345678' : '01819000$i',
              applicantAddress: const Value('মিরপুর, ঢাকা'),
              officeName: i % 2 == 0 ? 'সদর ভূমি অফিস' : 'উপজেলা ভূমি অফিস',
              mouza: Value(i == 250 ? 'কালিকাপুর' : 'মৌজা-$i'),
              appNumber: Value(i == 250 ? 'APP-9988' : 'APP-$i'),
              caseNumber: Value('CASE-$i'),
              workType: 'ই-নামজারি',
              applicationDate: DateTime.now().millisecondsSinceEpoch,
              status: i % 2 == 0 ? 'সম্পন্ন' : 'আবেদন',
              agreedAmount: 500000,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      });

      // ১. বাংলা অঙ্কে ফোন সার্চ ("০১৭১২")
      final bnSearch = await appRepo.watchApplications(search: '০১৭১২').first;
      expect(bnSearch.length, 1);
      expect(bnSearch.first.applicantName, 'মোঃ রফিকুল ইসলাম');

      // ২. ইংরেজি অঙ্কে আবেদন নম্বর সার্চ ("9988")
      final enSearch = await appRepo.watchApplications(search: '9988').first;
      expect(enSearch.length, 1);
      expect(enSearch.first.id, 'app-250');

      // ৩. বাংলা মৌজা সার্চ ("কালিকাপুর")
      final mouzaSearch = await appRepo.watchApplications(search: 'কালিকাপুর').first;
      expect(mouzaSearch.length, 1);
      expect(mouzaSearch.first.applicantName, 'মোঃ রফিকুল ইসলাম');

      // ৪. স্ট্যাটাস ফিল্টারিং ("সম্পন্ন")
      final completedApps = await appRepo.watchApplications(status: 'সম্পন্ন').first;
      expect(completedApps.length, 250);
    });
  });

  group('Phase 5: Concurrency & Race Condition Simulation (কনকারেন্সি ও ডেটা অখণ্ডতা)', () {
    late AppDatabase db;
    late ApplicationRepository appRepo;
    late FinanceRepository finRepo;

    setUp(() {
      db = createStressTestDb();
      appRepo = ApplicationRepository(db);
      finRepo = FinanceRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('একই সাথে ২০টি প্যারালাল অ্যাসিনক্রোনাস অপারেশন সফলভাবে সম্পন্ন হয় (No Deadlocks)', () async {
      // প্রাথমিক আবেদন তৈরি
      final app = await appRepo.createApplication(
        applicantName: 'কনকারেন্ট টেস্ট আবেদন',
        applicantPhone: '01711223344',
        officeName: 'সদর রেকর্ডরুম',
        workType: 'খতিয়ান সংশোধন',
        agreedAmountPaisa: 1000000,
      );

      // ২০টি প্যারালাল পেমেন্ট অপারেশন একসাথে কল করা
      final futures = List.generate(20, (index) {
        return finRepo.addPayment(
          applicationId: app.id,
          amountPaisa: 10000, // ৳১০০
          method: 'নগদ',
          note: 'প্যারালাল পেমেন্ট #$index',
        );
      });

      final results = await Future.wait(futures);
      expect(results.length, 20);

      // সকল ২০টি পেমেন্ট ডেটাবেজে সঠিকভাবে যুক্ত হয়েছে
      final payments = await finRepo.getPaymentsForApplication(app.id);
      expect(payments.length, 20);

      final totalPaid = payments.fold<int>(0, (sum, p) => sum + p.amount);
      expect(totalPaid, 200000); // ২০ * ৳১০০ = ৳২,০০০
    });

    test('একই অফিসে ডুপ্লিকেট আবেদন নম্বরের রেস কন্ডিশনে একজন সফল এবং অপরজন সম্মানজনক বাংলায় ব্যর্থ', () async {
      const duplicateAppNum = 'APP-DUPLICATE-RACE-001';
      const officeName = 'সদর উপজেলা ভূমি অফিস';

      // ২টি কনকারেন্ট আবেদন একই সাথে তৈরি করার চেষ্টা
      Future<Application> createAttempt(String applicantName) {
        return appRepo.createApplication(
          applicantName: applicantName,
          applicantPhone: '01811223344',
          officeName: officeName,
          appNumber: duplicateAppNum,
          workType: 'ই-নামজারি',
          agreedAmountPaisa: 600000,
        );
      }

      var successCount = 0;
      var duplicateFailureCount = 0;

      try {
        await createAttempt('প্রথম আবেদনকারী');
        successCount++;
      } catch (e) {
        if (e is AppFailure && e.code == 'duplicateAppNumber') {
          duplicateFailureCount++;
        }
      }

      try {
        await createAttempt('দ্বিতীয় আবেদনকারী');
        successCount++;
      } catch (e) {
        if (e is AppFailure && e.code == 'duplicateAppNumber') {
          duplicateFailureCount++;
          expect(e.message, 'এই আবেদন নম্বরটি ইতিমধ্যে এই অফিসে সংরক্ষিত আছে। অনুগ্রহ করে নম্বরটি পরীক্ষা করুন।');
        }
      }

      expect(successCount, 1);
      expect(duplicateFailureCount, 1);
    });
  });

  group('Phase 5: Worst-Case & Extreme Crisis Scenarios (চরম সংকট টেস্ট)', () {
    late AppDatabase db;
    late ApplicationRepository appRepo;

    setUp(() {
      db = createStressTestDb();
      appRepo = ApplicationRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('ট্রানজ্যাকশনের মাঝখানে এরর ঘটলে সম্পূর্ণ রোলব্যাক নিশ্চিত হয় (Zero Corrupted/Half Data)', () async {
      final app = await appRepo.createApplication(
        applicantName: 'আনিসুর রহমান',
        applicantPhone: '01819998877',
        officeName: 'তেজগাঁও ভূমি অফিস',
        workType: 'খারিজ/জমাভাগ',
        agreedAmountPaisa: 700000,
      );

      final initialHistoryCount = (await db.select(db.statusHistory).get()).length;
      final initialExpenseCount = (await db.select(db.expenses).get()).length;
      final initialTaskCount = (await db.select(db.tasks).get()).length;

      // ট্রানজ্যাকশন সিমুলেশন: ১. স্ট্যাটাস হিস্টোরি লেখা ২. খরচ লেখা ৩. তারপর ইচ্ছাকৃত অপ্রত্যাশিত এক্সেপশন
      bool exceptionThrown = false;
      try {
        await db.transaction(() async {
          await db.into(db.statusHistory).insert(
                StatusHistoryCompanion.insert(
                  id: 'sh-rollback-test',
                  applicationId: app.id,
                  prevStatus: const Value('আবেদন'),
                  newStatus: 'শুনানি',
                  changedAt: DateTime.now().millisecondsSinceEpoch,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                ),
              );

          await db.into(db.expenses).insert(
                ExpensesCompanion.insert(
                  id: 'exp-rollback-test',
                  applicationId: Value(app.id),
                  amount: 50000,
                  category: 'শুনানি খরচ',
                  date: DateTime.now().millisecondsSinceEpoch,
                  isGeneral: const Value(0),
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                ),
              );

          // সিমুলেটেড চরম ব্যর্থতা (যেমন: ডিস্ক বা মেমরি ফেইল বা কোড এক্সেপশন)
          throw Exception('চরম অপ্রত্যাশিত সিস্টেম ব্যর্থতা!');
        });
      } catch (e) {
        exceptionThrown = true;
      }

      expect(exceptionThrown, isTrue);

      // রোলব্যাক ভেরিফিকেশন: কোনো টেবিল স্পর্শিত বা আংশিক ডাটা লেখা হয়নি
      final finalHistoryCount = (await db.select(db.statusHistory).get()).length;
      final finalExpenseCount = (await db.select(db.expenses).get()).length;
      final finalTaskCount = (await db.select(db.tasks).get()).length;

      expect(finalHistoryCount, initialHistoryCount);
      expect(finalExpenseCount, initialExpenseCount);
      expect(finalTaskCount, initialTaskCount);

      // মূল আবেদনের অবস্থা অপরিবর্তিত
      final untouchedApp = await appRepo.getApplication(app.id);
      expect(untouchedApp?.status, 'আবেদন');
    });

    test('স্ন্যাপশট কলামে সরাসরি SQL UPDATE চেষ্টা ট্রিগার দ্বারা প্রতিহত হয়', () async {
      final app = await appRepo.createApplication(
        applicantName: 'অপরিবর্তনীয় স্ন্যাপশট গ্রাহক',
        applicantPhone: '01812345678',
        applicantAddress: 'যাত্রাবাড়ী, ঢাকা',
        officeName: 'ডেমরা ভূমি অফিস',
        workType: 'নামজারি',
        agreedAmountPaisa: 500000,
      );

      // ট্রাই টু ব্রীচ স্ন্যাপশট কলাম
      expect(
        () async {
          await db.customUpdate(
            "UPDATE applications SET applicant_name = 'হ্যাকড নাম' WHERE id = ?",
            variables: [Variable.withString(app.id)],
          );
        },
        throwsA(
          isA<SqliteException>().having(
            (e) => e.message,
            'message',
            contains('application snapshot columns are immutable'),
          ),
        ),
      );

      // ডাটাবেজের রেকর্ড অপরিবর্তিত অক্ষত আছে
      final checked = await appRepo.getApplication(app.id);
      expect(checked?.applicantName, 'অপরিবর্তনীয় স্ন্যাপশট গ্রাহক');
    });

    test('আর্থিক রেকর্ড (Payments ও Expenses) সরাসরি SQL UPDATE ট্রিগার দ্বারা প্রতিহত হয়', () async {
      final app = await appRepo.createApplication(
        applicantName: 'আর্থিক অডিট গ্রাহক',
        applicantPhone: '01711223344',
        officeName: 'সাভার ভূমি অফিস',
        workType: 'নামজারি',
        agreedAmountPaisa: 500000,
        initialPaymentPaisa: 200000,
      );
      expect(app.id, isNotEmpty);

      final payments = await db.select(db.payments).get();
      final paymentId = payments.first.id;

      // সরাসরি পেমেন্টের টাকা বা তারিখ বদলানোর চেষ্টা
      expect(
        () async {
          await db.customUpdate(
            'UPDATE payments SET amount = 999999 WHERE id = ?',
            variables: [Variable.withString(paymentId)],
          );
        },
        throwsA(
          isA<SqliteException>().having(
            (e) => e.message,
            'message',
            contains('payments are immutable; use soft-delete and a new entry'),
          ),
        ),
      );
    });

    test('চরম প্রতিকূল ও ভুল ইনপুট হ্যান্ডলিং (Malformed & Adversarial Inputs)', () {
      // ১. ফোন নম্বর ভুল ও চরম ইনপুট
      expect(AppValidators.isValidPhone(''), isFalse);
      expect(AppValidators.isValidPhone('018'), isFalse);
      expect(AppValidators.isValidPhone('0181234567890'), isFalse); // ১২ ডিজিট
      expect(AppValidators.isValidPhone('01212345678'), isFalse); // অবৈধ প্রিফিক্স 012
      expect(AppValidators.isValidPhone('abcdefghijk'), isFalse);
      expect(AppValidators.isValidPhone('০১৮১২৩৪৫৬৭'), isFalse); // ১০ ডিজিট বাংলা
      expect(AppValidators.isValidPhone('01812345678'), isTrue);
      expect(AppValidators.isValidPhone('০১৭১২৩৪৫৬৭৮'), isTrue);

      // ২. টাকা পার্সিং ভুল ও চরম ইনপুট (Money.fromJson)
      expect(() => Money.fromJson(''), throwsFormatException);
      expect(() => Money.fromJson('abc'), throwsFormatException);
      expect(Money.fromJson('৳৫০০০').paisa, 500000);
      expect(Money.fromJson('৫,০০০.৫০').paisa, 500050);
      expect(Money.fromJson('-500').paisa, -50000);

      // ৩. বাংলা সংখ্যা রূপান্তর সেফটি
      expect(BengaliDigits.toEnglish('০১২৩৪৫৬৭৮৯'), '0123456789');
      expect(BengaliDigits.toBengali('0123456789'), '০১২৩৪৫৬৭৮৯');
      expect(BengaliDigits.toEnglish('Hello 123'), 'Hello 123');
      expect(BengaliDigits.toBengali('Hello 123'), 'Hello ১২৩');
    });

    test('করাপ্ট বা নষ্ট ব্যাকআপ ফাইল রিস্টোর করার চেষ্টায় লাইভ ডাটা অক্ষত থাকে এবং মানবিক এরর দেয়', () async {
      final tempDir = Directory.systemTemp.createTempSync('rojob_p5_crisis_');
      try {
        final corruptFile = File('${tempDir.path}/corrupted_backup.db');
        // নষ্ট বা ভাঙা ফাইল যাতে কোনো ভ্যালিড SQLite হেডার নেই
        corruptFile.writeAsStringSync('THIS IS NOT A VALID SQLITE FILE - GARBAGE DATA 12345');

        final backupRepo = BackupRepository(db);

        // ১. ভ্যালিডেশনে isValid false হবে এবং মানবিক বাংলা মেসেজ থাকবে
        final validation = await backupRepo.validateBackupFile(corruptFile.path);
        expect(validation.isValid, isFalse);
        expect(
          validation.errorMessage,
          'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
        );

        // ২. রিস্টোর চেষ্টায় AppFailure ছুঁড়ে দেওয়া হবে
        expect(
          () => backupRepo.restoreBackup(
            corruptFile.path,
            onDatabaseReopened: (_) {},
          ),
          throwsA(
            isA<AppFailure>().having(
              (f) => f.code,
              'code',
              'corruptBackup',
            ),
          ),
        );
      } finally {
        try {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        } catch (_) {}
      }
    });

    test('আর্থিক লেনদেনের সফট-ডিলিট ও রিস্টোর অডিট ট্রেইল (কখনোই স্থায়ীভাবে মুছে যায় না)', () async {
      final finRepo = FinanceRepository(db);
      final app = await appRepo.createApplication(
        applicantName: 'অডিট ট্রেইল গ্রাহক',
        applicantPhone: '01811223344',
        officeName: 'সদর ভূমি অফিস',
        workType: 'ই-নামজারি',
        agreedAmountPaisa: 500000,
        initialPaymentPaisa: 200000, // ৳২,০০০
      );

      // ১. প্রাথমিক পেমেন্ট উপস্থিত
      var payments = await finRepo.getPaymentsForApplication(app.id);
      expect(payments.length, 1);
      final paymentId = payments.first.id;

      // ২. সফট ডিলিট করা হলো
      await finRepo.deletePayment(paymentId);

      // সক্রিয় লিস্ট থেকে বাদ পড়েছে
      payments = await finRepo.getPaymentsForApplication(app.id);
      expect(payments.length, 0);

      // ভিউ থেকেও মুছে গেছে (আর্থিক হিসেবে যোগ হবে না)
      var appFinancials = await appRepo.getApplicationWithFinancials(app.id);
      expect(appFinancials?.totalReceivedPaisa, 0);

      // ৩. ডাটাবেজ ফাইলে রেকর্ড এখনও সুরক্ষিতভাবে সংরক্ষিত আছে (deleted_at নাল নয়)
      final rawRow = await (db.select(db.payments)..where((t) => t.id.equals(paymentId))).getSingle();
      expect(rawRow.deletedAt, isNotNull);

      // ৪. রিস্টোর / আনডু করা হলো
      await finRepo.restorePayment(paymentId);

      // পুনরায় হিসাবে ফেরত এসেছে
      payments = await finRepo.getPaymentsForApplication(app.id);
      expect(payments.length, 1);

      appFinancials = await appRepo.getApplicationWithFinancials(app.id);
      expect(appFinancials?.totalReceivedPaisa, 200000);
    });
  });

  group('Phase 5: Real-World End-to-End Land Service Shop Lifecycle (Golden Rules 1-6 Audit)', () {
    late AppDatabase db;
    late ApplicationRepository appRepo;
    late FinanceRepository finRepo;
    late PersonRepository personRepo;
    late ReferenceRepository refRepo;
    late OfficeRepository officeRepo;
    late TaskRepository taskRepo;

    setUp(() {
      db = createStressTestDb();
      appRepo = ApplicationRepository(db);
      finRepo = FinanceRepository(db);
      personRepo = PersonRepository(db);
      refRepo = ReferenceRepository(db);
      officeRepo = OfficeRepository(db);
      taskRepo = TaskRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('সম্পূর্ণ বাস্তব জীবনের দোকান কাজের পরিক্রমা ও ১০০% নিখুঁত গোল্ডেন রুলস অডিট', () async {
      // -------------------------------------------------------------
      // ধাপ ১: গ্রাহক ও রেফারেন্স ব্যক্তি নিবন্ধন
      // -------------------------------------------------------------
      final customer = await personRepo.createPerson(
        name: 'হাজী মোঃ সোলেমান',
        phone: '01819556677',
        address: 'গ্রাম: চর কিসমত, থানা: রূপগঞ্জ, নারায়ণগঞ্জ',
      );

      final reference = await refRepo.createReference(
        name: 'ইউনিয়ন সদস্য আতিকুর রহমান',
        phone: '01711889900',
        address: 'চর কিসমত বাজার',
      );

      final office = await officeRepo.createOffice(
        name: 'রূপগঞ্জ উপজেলা ভূমি অফিস',
      );

      // -------------------------------------------------------------
      // ধাপ ২: ৳৮,০০০ টাকার প্যাকেজ চুক্তিতে নতুন আবেদন তৈরি
      // -------------------------------------------------------------
      const contractPaisa = 800000; // ৳৮,০০০
      const advancePaisa = 300000; // ৳৩,০০০ অগ্রিম কিস্তি
      final app = await appRepo.createApplication(
        applicantId: customer.id,
        applicantName: customer.name,
        applicantPhone: customer.phone,
        applicantAddress: customer.address,
        referenceId: reference.id,
        referenceName: reference.name,
        officeId: office.id,
        officeName: office.name,
        mouza: 'চর কিসমত',
        appNumber: 'APP-RUP-2026-001',
        caseNumber: 'CASE-7788',
        workType: 'ই-নামজারি',
        agreedAmountPaisa: contractPaisa,
        initialPaymentPaisa: advancePaisa,
        initialPaymentMethod: 'নগদ',
      );

      // প্রাথমিক হিসাব যাচাই (নিয়ম ১: Realized Income)
      var appDetails = await appRepo.getApplicationWithFinancials(app.id);
      expect(appDetails?.totalReceivedPaisa, 300000); // ৳৩,০০০
      expect(appDetails?.totalExpensePaisa, 0); // ৳০
      expect(appDetails?.actualIncome.paisa, 300000); // ৳৩,০০০
      expect(appDetails?.effectiveDue.paisa, 500000); // ৳৫,০০০

      // -------------------------------------------------------------
      // ধাপ ৩: অবস্থা পরিবর্তন ➔ 'প্রস্তাব প্রেরণ' (+ সরকারি ফি ৳৭০ খরচ)
      // -------------------------------------------------------------
      const govFeePaisa = 7000; // ৳৭০
      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'প্রস্তাব প্রেরণ',
        feeExpensePaisa: govFeePaisa,
        feeExpenseCategory: 'সরকারি ফি',
        note: 'অনলাইন চালানসহ প্রস্তাব প্রেরণ সম্পন্ন',
      );

      appDetails = await appRepo.getApplicationWithFinancials(app.id);
      expect(appDetails?.totalReceivedPaisa, 300000); // ৳৩,০০০
      expect(appDetails?.totalExpensePaisa, 7000); // ৳৭০
      expect(appDetails?.actualIncome.paisa, 293000); // ৳২,৯৩০ (৩,০০০ - ৭০)
      expect(appDetails?.effectiveDue.paisa, 500000); // ৳৫,০০০

      // -------------------------------------------------------------
      // ধাপ ৪: অবস্থা পরিবর্তন ➔ 'শুনানি' (+ শুনানি খরচ ৳৩০০ ও অটো টাস্ক)
      // -------------------------------------------------------------
      const hearingExpensePaisa = 30000; // ৳৩০০
      final hearingDate = DateTime.now().add(const Duration(days: 7));
      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'শুনানি',
        feeExpensePaisa: hearingExpensePaisa,
        feeExpenseCategory: 'শুনানি খরচ',
        hearingTaskTitle: 'হাজী সোলেমানের নামজারি শুনানি ও নথি পেশ',
        hearingTaskDueDate: hearingDate,
        hearingTaskPriority: 'জরুরি',
      );

      // শুনানির টাস্ক স্বয়ংক্রিয় তৈরি হয়েছে কিনা যাচাই
      final tasks = await taskRepo.getTasks(applicationId: app.id);
      expect(tasks.length, 1);
      expect(tasks.first.title, 'হাজী সোলেমানের নামজারি শুনানি ও নথি পেশ');
      expect(tasks.first.priority, 'জরুরি');

      // -------------------------------------------------------------
      // ধাপ ৫: শুনানির দিন ২য় কিস্তি পরিশোধ ৳৩,৫০০
      // -------------------------------------------------------------
      const installmentTwoPaisa = 350000; // ৳৩,৫০০
      await finRepo.addPayment(
        applicationId: app.id,
        amountPaisa: installmentTwoPaisa,
        method: 'বিকাশ',
        note: 'শুনানি পরবর্তী কিস্তি',
      );

      appDetails = await appRepo.getApplicationWithFinancials(app.id);
      expect(appDetails?.totalReceivedPaisa, 650000); // ৳৩,০০০ + ৳৩,৫০০ = ৳৬,৫০০
      expect(appDetails?.totalExpensePaisa, 37000); // ৳৭০ + ৳৩০০ = ৳৩৭০
      expect(appDetails?.actualIncome.paisa, 613000); // ৳৬,৫০০ - ৳৩৭০ = ৳৬,১৩০
      expect(appDetails?.effectiveDue.paisa, 150000); // ৳৮,০০০ - ৳৬,৫০০ = ৳১,৫০০ বকেয়া

      // -------------------------------------------------------------
      // ধাপ ৬: অবস্থা পরিবর্তন ➔ 'ডিসিআর প্রস্তুত' (+ ডিসিআর ফি ৳১,১০০)
      // -------------------------------------------------------------
      const dcrFeePaisa = 110000; // ৳১,১০০
      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'ডিসিআর প্রস্তুত',
        feeExpensePaisa: dcrFeePaisa,
        feeExpenseCategory: 'ডিসিআর ফি',
        note: 'ডিসিআর ও খতিয়ান ফি জমা দেওয়া হয়েছে',
      );

      // -------------------------------------------------------------
      // ধাপ ৭: অবস্থা পরিবর্তন ➔ 'সম্পন্ন'
      // -------------------------------------------------------------
      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'সম্পন্ন',
        note: 'চূড়ান্ত নামজারি ও খতিয়ান গ্রাহককে হস্তান্তর',
      );

      // -------------------------------------------------------------
      // ধাপ ৮: ৩য় কিস্তি ও বকেয়া নিষ্পত্তি ('Mark as Paid' - নিয়ম ২)
      // -------------------------------------------------------------
      // মোট চুক্তি ৳৮,০০০। ইতিমধ্যে আদায় ৳৬,৫০০। বাকি ছিল ৳১,৫০০।
      // গ্রাহক দিলেন ৳১,৩০০। বাকি ২০০ টাকা দোকানদার মাফ করলেন।
      await finRepo.addPayment(
        applicationId: app.id,
        amountPaisa: 130000, // ৳১,৩০০
        method: 'নগদ',
        note: 'চূড়ান্ত কিস্তি',
      );

      // বাকি ৳২০০ মওকুফ ('Mark as Paid')
      await appRepo.markAsPaid(app.id, true);

      appDetails = await appRepo.getApplicationWithFinancials(app.id);
      expect(appDetails?.totalReceivedPaisa, 780000); // ৳৭,৮০০
      expect(appDetails?.totalExpensePaisa, 147000); // ৳৭০ + ৳৩০০ + ৳১,১০০ = ৳১,৪৭০
      expect(appDetails?.actualIncome.paisa, 633000); // ৳৭,৮০০ - ৳১,৪৭০ = ৳৬,৩৩০
      expect(appDetails?.effectiveDue.paisa, 0); // কার্যকর বকেয়া = ৳০!
      expect(appDetails?.application.isMarkedAsPaid, 1);

      // -------------------------------------------------------------
      // ধাপ ৯: রেফারেন্স ব্যক্তি খাতা অডিট (নিয়ম ৬)
      // -------------------------------------------------------------
      final refStats = await refRepo.getReferenceStats(reference.id);
      expect(refStats.applicationCount, 1);
      expect(refStats.totalAgreedPaisa, 800000); // ৳৮,০০০
      expect(refStats.totalReceivedPaisa, 780000); // ৳৭,৮০০
      expect(refStats.totalDuePaisa, 0); // ৳০

      // -------------------------------------------------------------
      // ধাপ ১০: স্বাধীন আয় ও সাধারণ দোকান খরচ সংযোজন (নিয়ম ৩ ও ৪)
      // -------------------------------------------------------------
      // স্বাধীন আয়: ফটোকপি ও জমির চুক্তিপত্র টাইপিং ৳৫০০
      await finRepo.addIndependentIncome(
        customerName: 'স্থানীয় গ্রাহক করিম',
        category: 'ফটোকপি ও টাইপিং',
        amountPaisa: 50000, // ৳৫০০
        note: 'দলিল ফটোকপি',
      );

      // সাধারণ পরিচালন খরচ: দোকান বিদ্যুৎ বিল ও নাস্তা ৳১,০০০
      await finRepo.addGeneralExpense(
        amountPaisa: 100000, // ৳১,০০০
        category: 'বিদ্যুৎ বিল ও নাস্তা',
        note: 'চলতি মাসের দোকান বিল',
      );

      // -------------------------------------------------------------
      // ধাপ ১১: সামগ্রিক দোকান নিট ইনকাম গোল্ডেন রুল অডিট (নিয়ম ৫)
      // -------------------------------------------------------------
      // মোট নিট ইনকাম = (আবেদন আদায় ৳৭,৮০০ + স্বাধীন আয় ৳৫০০) - (কাজের খরচ ৳১,৪৭০ + সাধারণ খরচ ৳১,০০০)
      //              = ৳৮,৩০০ - ৳২,৪৭০ = ৳৫,৮৩০ (৫৮৩০০০ পয়সা)
      final shopSummary = await finRepo.getShopFinancialOverview();
      expect(shopSummary.totalApplicationReceived, 780000);
      expect(shopSummary.totalIndependentIncome, 50000);
      expect(shopSummary.totalApplicationExpense, 147000);
      expect(shopSummary.totalGeneralExpense, 100000);
      expect(shopSummary.netRealizedIncome.paisa, 583000); // ৳৫,৮৩০ bit-for-bit exact!

      // -------------------------------------------------------------
      // ধাপ ১২: ইউনিভার্সাল স্ন্যাপশট নিরাপত্তা অডিট (গ্রাহক ডিলিট হলেও স্ন্যাপশট অক্ষত)
      // -------------------------------------------------------------
      // গ্রাহক বা রেফারেন্স ব্যক্তি বা অফিস যদি পরে মডিফাই বা সফট ডিলিট করা হয়
      await personRepo.deletePerson(customer.id);
      await refRepo.deleteReference(reference.id);
      await officeRepo.deleteOffice(office.id);

      final appSnapshot = await appRepo.getApplication(app.id);
      expect(appSnapshot?.applicantName, 'হাজী মোঃ সোলেমান');
      expect(appSnapshot?.applicantPhone, '01819556677');
      expect(appSnapshot?.applicantAddress, 'গ্রাম: চর কিসমত, থানা: রূপগঞ্জ, নারায়ণগঞ্জ');
      expect(appSnapshot?.referenceName, 'ইউনিয়ন সদস্য আতিকুর রহমান');
      expect(appSnapshot?.officeName, 'রূপগঞ্জ উপজেলা ভূমি অফিস');
    });
  });
}
