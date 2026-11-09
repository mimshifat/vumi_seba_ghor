import 'dart:async';
import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/errors/app_failure.dart';
import 'package:bhumi_kajer_hisab/core/providers/app_providers.dart';
import 'package:bhumi_kajer_hisab/core/utils/money.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

ProviderContainer createContainer(AppDatabase db) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Phase 2: MutationController ও ডাবল-ট্যাপ সেফটি লক (Double-Tap Prevention)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = createTestDb();
      container = createContainer(db);
    });

    tearDown(() => db.close());

    test('একই সাথে দ্রুত পরপর একাধিক চাপ (Double-Tap) দিলে দ্বিতীয় কল ব্লক হয়', () async {
      final controller = container.read(applicationControllerProvider.notifier);
      final completer = Completer<String>();
      int executionCount = 0;

      // প্রথম অ্যাকশন শুরু করা হলো (যা বিলম্বিত)
      final future1 = controller.execute(() async {
        executionCount++;
        return await completer.future;
      });

      // সাথে সাথে দ্বিতীয়বার কল করার চেষ্টা (ডাবল ট্যাপ)
      final future2 = controller.execute(() async {
        executionCount++;
        return 'second';
      });

      // দ্বিতীয় কল সাথে সাথেই null ফেরত দিবে কারণ প্রথমটি চলমান
      final result2 = await future2;
      expect(result2, isNull);
      expect(executionCount, 1);

      // প্রথমটি সফলভাবে শেষ করা হলো
      completer.complete('first');
      final result1 = await future1;
      expect(result1, 'first');
      expect(executionCount, 1);
      expect(controller.state, isA<AsyncData<void>>());
    });

    test('মিউটেশনে এরর হলে স্বয়ংক্রিয়ভাবে প্রাকৃতিক বাংলা AppFailure-এ কনভার্ট হয়', () async {
      final controller = container.read(applicationControllerProvider.notifier);

      // অবৈধ ফোন নম্বর দিয়ে তৈরি করার চেষ্টা
      await controller.createApplication(
        applicantName: 'আবেদনকারী',
        applicantPhone: '12345', // অবৈধ ফোন
        officeName: 'সাভার অফিস',
        workType: 'নামজারি',
        agreedAmountPaisa: 500000,
      );

      final state = container.read(applicationControllerProvider);
      expect(state.hasError, true);
      expect(state.error, isA<AppFailure>());
      final failure = state.error as AppFailure;
      expect(failure.code, 'invalidPhone');
      expect(failure.message, contains('১১ ডিজিটের সঠিক মোবাইল নম্বর দিন'));
    });
  });

  group('Phase 2: অ্যাপ্লিকেশন প্রোভাইডার, সার্চ ও ফিল্টারিং (Reactive Application Providers)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = createTestDb();
      container = createContainer(db);

      // প্রাথমিক টেস্ট ডাটা সিড
      final officeCtrl = container.read(officeControllerProvider.notifier);
      final off1 = await officeCtrl.createOffice(name: 'সাভার ভূমি অফিস');
      final off2 = await officeCtrl.createOffice(name: 'কেরানীগঞ্জ সার্কেল');

      final appCtrl = container.read(applicationControllerProvider.notifier);
      // ১. চলমান নামজারি
      await appCtrl.createApplication(
        applicantName: 'মো. রফিক ইসলাম',
        applicantPhone: '01711223344',
        officeId: off1!.id,
        officeName: off1.name,
        workType: 'ই-নামজারি',
        mouza: 'সাভার',
        agreedAmountPaisa: 800000,
        initialPaymentPaisa: 500000,
        status: 'আবেদন',
        appNumber: 'APP-101',
      );

      // ২. শুনানির আবেদন
      await appCtrl.createApplication(
        applicantName: 'করিম উল্লাহ',
        applicantPhone: '01819998877',
        officeId: off1.id,
        officeName: off1.name,
        workType: 'জমাভাগ',
        mouza: 'ধামরাই',
        agreedAmountPaisa: 600000,
        initialPaymentPaisa: 600000, // সম্পূর্ণ পরিশোধ
        status: 'শুনানি',
        appNumber: 'APP-102',
      );

      // ৩. সম্পন্ন আবেদন
      await appCtrl.createApplication(
        applicantName: 'আব্দুস সামাদ',
        applicantPhone: '01911002233',
        officeId: off2!.id,
        officeName: off2.name,
        workType: 'খতিয়ান সংশোধন',
        mouza: 'কেরানীগঞ্জ',
        agreedAmountPaisa: 500000,
        initialPaymentPaisa: 500000,
        status: 'সম্পন্ন',
        appNumber: 'APP-103',
      );
    });

    tearDown(() => db.close());

    test('applicationsWithFinancialsStreamProvider রিয়েলটাইমে মোট জমা ও খরচ হিসাব প্রদান করে', () async {
      final apps = await container.read(applicationsWithFinancialsStreamProvider.future);
      expect(apps.length, 3);

      final rafiq = apps.firstWhere((a) => a.application.applicantName == 'মো. রফিক ইসলাম');
      expect(rafiq.agreed, Money.fromTaka(8000));
      expect(rafiq.received, Money.fromTaka(5000));
      expect(rafiq.effectiveDue, Money.fromTaka(3000));
      expect(rafiq.actualIncome, Money.fromTaka(5000)); // এখনো খরচ হয়নি
    });

    test('কুইক ফিল্টার চিপস: "has_due", "hearing", "ongoing", "completed"', () async {
      await container.read(applicationsWithFinancialsStreamProvider.future);
      final filterNotifier = container.read(applicationFilterProvider.notifier);

      // বকেয়া ফিল্টার
      filterNotifier.setQuickFilterKey('has_due');
      var filtered = container.read(filteredApplicationsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.application.applicantName, 'মো. রফিক ইসলাম');

      // শুনানি ফিল্টার
      filterNotifier.setQuickFilterKey('hearing');
      filtered = container.read(filteredApplicationsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.application.applicantName, 'করিম উল্লাহ');

      // সম্পন্ন ফিল্টার
      filterNotifier.setQuickFilterKey('completed');
      filtered = container.read(filteredApplicationsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.application.applicantName, 'আব্দুস সামাদ');

      // চলমান ফিল্টার (সম্পন্ন ছাড়া)
      filterNotifier.setQuickFilterKey('ongoing');
      filtered = container.read(filteredApplicationsProvider);
      expect(filtered.length, 2);
    });

    test('বাংলা ডিজিট ও নাম দিয়ে স্মার্ট সার্চ ফিল্টার', () async {
      await container.read(applicationsWithFinancialsStreamProvider.future);
      final filterNotifier = container.read(applicationFilterProvider.notifier);

      // বাংলা ডিজিট ফোন সার্চ: ০১৮১৯
      filterNotifier.setSearchQuery('০১৮১৯');
      var filtered = container.read(filteredApplicationsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.application.applicantName, 'করিম উল্লাহ');

      // মৌজা দিয়ে সার্চ
      filterNotifier.setSearchQuery('ধামরাই');
      filtered = container.read(filteredApplicationsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.application.applicantName, 'করিম উল্লাহ');
    });

    test('আবেদনের অবস্থা পরিবর্তন (Atomic Transition Workflow)', () async {
      final apps = await container.read(applicationsWithFinancialsStreamProvider.future);
      final rafiq = apps.firstWhere((a) => a.application.applicantName == 'মো. রফিক ইসলাম');

      final controller = container.read(applicationControllerProvider.notifier);
      await controller.transitionStatus(
        applicationId: rafiq.application.id,
        newStatus: 'ডিসিআর প্রস্তুত',
        feeExpensePaisa: 110000, // ৳১,১০০ খরচ
        paymentReceivedPaisa: 100000, // ৳১,০০০ আদায়
        hearingTaskTitle: 'ডিসিআর চালান সংগ্রহ',
      );

      await pumpEventQueue();

      // রিয়েলটাইম আপডেটেড ডেটা যাচাই
      final updatedApp = await container.read(applicationWithFinancialsDetailProvider(rafiq.application.id).future);

      expect(updatedApp!.application.status, 'ডিসিআর প্রস্তুত');
      expect(updatedApp.received, Money.fromTaka(6000)); // ৳৫,০০০ + ৳১,০০০
      expect(updatedApp.expense, Money.fromTaka(1100)); // ৳১,১০০
      expect(updatedApp.actualIncome, Money.fromTaka(4900)); // ৳৬,০০০ - ৳১,১০০ = ৳৪,৯০০
      expect(updatedApp.effectiveDue, Money.fromTaka(2000)); // ৳৮,০০০ - ৳৬,০০০ = ৳২,০০০
    });
  });

  group('Phase 2: ফিন্যান্স প্রোভাইডার ও সময়ভিত্তিক হিসাব (Financial Overview Providers)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = createTestDb();
      container = createContainer(db);

      final officeCtrl = container.read(officeControllerProvider.notifier);
      final office = await officeCtrl.createOffice(name: 'সাভার অফিস');

      final appCtrl = container.read(applicationControllerProvider.notifier);
      final app = await appCtrl.createApplication(
        applicantName: 'জামাল সাহেব',
        applicantPhone: '01711223344',
        officeId: office!.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 1000000, // চুক্তি ৳১০,০০০
      );

      final finCtrl = container.read(financeControllerProvider.notifier);
      // আবেদন জমা ৳৭,০০০
      await finCtrl.addPayment(applicationId: app!.id, amountPaisa: 700000);
      // কাজের খরচ ৳২,০০০
      await finCtrl.addApplicationExpense(
        applicationId: app.id,
        amountPaisa: 200000,
        category: 'কোর্ট ফি',
      );
      // স্বতন্ত্র আয় ৳১,৫০০
      await finCtrl.addIndependentIncome(
        category: 'ফটোকপি',
        amountPaisa: 150000,
      );
      // সাধারণ খরচ ৳৫০০
      await finCtrl.addGeneralExpense(
        category: 'চা ও নাস্তা',
        amountPaisa: 50000,
      );
    });

    tearDown(() => db.close());

    test('financialOverviewProvider নির্বাচিত ফিল্টারে প্রকৃত নিট ইনকাম গণনা করে', () async {
      final overview = await container.read(financialOverviewProvider.future);

      // মোট ক্যাশ আয় = ৳৭,০০০ + ৳১,৫০০ = ৳৮,৫০০
      expect(overview.totalCashIncome, Money.fromTaka(8500));
      // মোট খরচ = ৳২,০০০ + ৳৫০০ = ৳২,৫০০
      expect(overview.totalCashExpense, Money.fromTaka(2500));
      // প্রকৃত নিট ইনকাম = ৳৮,৫০০ - ৳২,৫০০ = ৳৬,০০০ (Golden rule §1.2)
      expect(overview.netRealizedIncome, Money.fromTaka(6000));
      // মোট বকেয়া = ৳১০,০০০ - ৳৭,০০০ = ৳৩,০০০
      expect(overview.effectiveDue, Money.fromTaka(3000));
    });

    test('todayFinancialSnapshotProvider আজকের দিনের সঠিক হিসাব দেয়', () async {
      final todaySnapshot = await container.read(todayFinancialSnapshotProvider.future);

      expect(todaySnapshot.totalCashIncome, Money.fromTaka(8500));
      expect(todaySnapshot.totalCashExpense, Money.fromTaka(2500));
      expect(todaySnapshot.netRealizedIncome, Money.fromTaka(6000));
    });

    test('সেন্ট্রালাইজড লেনদেন ভিউতে ফিল্টার (Income/Expense/Source)', () async {
      final txs = await container.read(unifiedTransactionsStreamProvider.future);
      expect(txs.length, 4);

      final filterNotifier = container.read(transactionsFilterProvider.notifier);

      // শুধু খরচ
      filterNotifier.setType('expense');
      var filtered = container.read(filteredTransactionsProvider);
      expect(filtered.length, 2);

      // শুধু আয়
      filterNotifier.setType('income');
      filtered = container.read(filteredTransactionsProvider);
      expect(filtered.length, 2);
    });
  });

  group('Phase 2: Person, Reference, Task, Office ও Settings প্রোভাইডার', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = createTestDb();
      container = createContainer(db);
    });

    tearDown(() => db.close());

    test('PersonController গ্রাহক তৈরি ও ফোন স্ট্যান্ডার্ডাইজেশন', () async {
      final ctrl = container.read(personControllerProvider.notifier);
      final person = await ctrl.createPerson(
        name: 'মো. কামাল হোসেন',
        phone: '০১৭১১-৯৯৮৮৭৭',
      );

      expect(person, isNotNull);
      expect(person!.phone, '01711998877');

      final list = await container.read(personsStreamProvider.future);
      expect(list.length, 1);
    });

    test('ReferenceController রেফারেন্স খাতা পরিসংখ্যান প্রোভাইডার', () async {
      final refCtrl = container.read(referenceControllerProvider.notifier);
      final ref = await refCtrl.createReference(
        name: 'হাজী মতিউর রহমান',
        phone: '01819001122',
      );

      final officeCtrl = container.read(officeControllerProvider.notifier);
      final office = await officeCtrl.createOffice(name: 'সাভার অফিস');

      final appCtrl = container.read(applicationControllerProvider.notifier);
      await appCtrl.createApplication(
        applicantName: 'ক্লায়েন্ট ১',
        applicantPhone: '01711000000',
        referenceId: ref!.id,
        referenceName: ref.name,
        officeId: office!.id,
        officeName: office.name,
        workType: 'নামজারি',
        agreedAmountPaisa: 600000,
        initialPaymentPaisa: 400000,
      );

      final stats = await container.read(referenceStatsProvider(ref.id).future);
      expect(stats.applicationCount, 1);
      expect(stats.totalAgreed, Money.fromTaka(6000));
      expect(stats.totalReceived, Money.fromTaka(4000));
      expect(stats.totalDue, Money.fromTaka(2000));
    });

    test('TaskController ও filteredTasksProvider (আজকের কাজ ও সম্পন্ন টাস্ক)', () async {
      final taskCtrl = container.read(taskControllerProvider.notifier);
      final now = DateTime.now();

      final t1 = await taskCtrl.createTask(
        title: 'এসি ল্যান্ড অফিসে শুনানি',
        dueDate: now,
        priority: 'জরুরি',
        category: 'শুনানি',
      );

      await container.read(tasksStreamProvider.future);

      // আজকের কাজ ফিল্টার
      container.read(taskTabFilterProvider.notifier).state = 'today';
      var tasks = container.read(filteredTasksProvider);
      expect(tasks.length, 1);

      // কাজ সম্পন্ন করা হলো
      await taskCtrl.markCompleted(t1!.id, true);
      await pumpEventQueue();
      await container.read(tasksStreamProvider.future);

      tasks = container.read(filteredTasksProvider);
      expect(tasks.length, 0); // আজকের অসমাপ্ত তালিকা থেকে বাদ গেছে

      // সম্পন্ন ট্যাবে রয়েছে
      container.read(taskTabFilterProvider.notifier).state = 'completed';
      tasks = container.read(filteredTasksProvider);
      expect(tasks.length, 1);
    });

    test('CategoryController ডিফল্ট ক্যাটাগরি ডিলিটে AsyncValue.error সেট করে', () async {
      // ডিফল্ট ক্যাটাগরি তৈরি
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.expenseCategories).insert(
            ExpenseCategoriesCompanion.insert(
              id: 'def-exp-fee',
              name: 'সরকারি ফি',
              isGeneral: const Value(0),
              isDefault: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final catCtrl = container.read(categoryControllerProvider.notifier);
      await catCtrl.deleteExpenseCategory('def-exp-fee');

      final state = container.read(categoryControllerProvider);
      expect(state.hasError, true);
      expect(state.error, isA<AppFailure>());
      final failure = state.error as AppFailure;
      expect(failure.code, 'cannotDeleteDefaultCategory');
    });

    test('ShopSettingsController দোকানে সেটিংস সেট ও রিয়েলটাইম ওয়াচ', () async {
      final settingsCtrl = container.read(shopSettingsControllerProvider.notifier);
      await settingsCtrl.setSetting('shop_name', 'রজব ভূমি সেবা ঘর');

      final settings = await container.read(shopSettingsStreamProvider.future);
      expect(settings['shop_name'], 'রজব ভূমি সেবা ঘর');
    });

    test('dashboardStatsProvider ড্যাশবোর্ডের সামগ্রিক অপারেশনাল পরিসংখ্যান প্রদান করে', () async {
      final stats = await container.read(dashboardStatsProvider.future);
      expect(stats.totalActiveApplications, greaterThanOrEqualTo(0));
      expect(stats.todayTasksCount, greaterThanOrEqualTo(0));
    });
  });
}
