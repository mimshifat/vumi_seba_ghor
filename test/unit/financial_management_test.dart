import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/demo/demo_data.dart';
import 'package:bhumi_kajer_hisab/core/utils/money.dart';

void main() {
  group('ভূমি কাজের হিসাব — Financial Management & Workflow Scenarios', () {
    late DemoApplication testApp;

    setUp(() {
      testApp = DemoApplication(
        id: 'APP-TEST-999',
        applicantId: 'p-test',
        applicantName: 'মো: জামান মিয়া',
        applicantPhone: '01700112233',
        workType: 'নামজারি',
        officeName: 'উপজেলা ভূমি অফিস, সাভার',
        applicationDate: DateTime.now(),
        status: 'আবেদন',
        agreedAmount: Money.fromTaka(7000),
        receivedAmount: Money.fromTaka(3000),
        expenseAmount: Money.zero,
        payments: [
          DemoPayment(
            id: 'pay-test-1',
            applicationId: 'APP-TEST-999',
            amount: Money.fromTaka(3000),
            date: DateTime.now().subtract(const Duration(days: 1)),
            method: 'নগদ',
            note: 'প্রাথমিক অগ্রিম জমা',
          ),
        ],
        expenses: [],
        statusHistory: [
          DemoStatusHistory(
            id: 'sh-test-1',
            prevStatus: '',
            newStatus: 'আবেদন',
            changedAt: DateTime.now().subtract(const Duration(days: 1)),
            note: 'নতুন আবেদন তৈরি',
          ),
        ],
      );

      // Add to demo store for testing
      DemoStore.applications.add(testApp);
    });

    tearDown(() {
      DemoStore.applications.removeWhere((a) => a.id == 'APP-TEST-999');
      DemoStore.independentIncomes.removeWhere((inc) => inc.id.startsWith('inc-test-'));
      DemoStore.generalExpenses.removeWhere((ge) => ge.id.startsWith('gexp-test-'));
    });

    test('Scenario 1: Application Payment — Installments & Due Calculation', () {
      // Customer agreed amount is 7000, initial deposit was 3000, remaining due is 4000
      expect(testApp.agreedAmount, Money.fromTaka(7000));
      expect(testApp.receivedAmount, Money.fromTaka(3000));
      expect(testApp.dueAmount, Money.fromTaka(4000));

      // Customer makes a second installment payment of 2000
      final installmentPayment = DemoPayment(
        id: 'pay-test-2',
        applicationId: testApp.id,
        amount: Money.fromTaka(2000),
        date: DateTime.now(),
        method: 'বিকাশ',
        note: 'দ্বিতীয় কিস্তি পরিশোধ',
      );

      final updatedPayments = List<DemoPayment>.from(testApp.payments)..insert(0, installmentPayment);
      final updatedApp = DemoApplication(
        id: testApp.id,
        applicantId: testApp.applicantId,
        applicantName: testApp.applicantName,
        applicantPhone: testApp.applicantPhone,
        workType: testApp.workType,
        officeName: testApp.officeName,
        applicationDate: testApp.applicationDate,
        status: testApp.status,
        agreedAmount: testApp.agreedAmount,
        receivedAmount: testApp.receivedAmount + Money.fromTaka(2000),
        expenseAmount: testApp.expenseAmount,
        payments: updatedPayments,
        expenses: testApp.expenses,
        statusHistory: testApp.statusHistory,
      );

      final idx = DemoStore.applications.indexWhere((a) => a.id == testApp.id);
      DemoStore.applications[idx] = updatedApp;

      // Verify total received is 5000 and remaining due is 2000
      expect(updatedApp.receivedAmount, Money.fromTaka(5000));
      expect(updatedApp.dueAmount, Money.fromTaka(2000));

      // Verify payment appears in global transaction history
      final allTx = DemoStore.getAllTransactions();
      final recordedTx = allTx.where((t) => t.id == 'pay-test-2').toList();
      expect(recordedTx.length, 1, reason: 'Payment must be recorded exactly once without duplication');
      expect(recordedTx.first.amount, Money.fromTaka(2000));
      expect(recordedTx.first.source, TransactionSource.applicationPayment);
      expect(recordedTx.first.applicationId, testApp.id);
    });

    test('Scenario 2: Status Change with Automatic Work Expense (কাজের খরচ)', () {
      final currentApp = DemoStore.applications.firstWhere((a) => a.id == testApp.id);
      final initialExpense = currentApp.expenseAmount;
      final initialReceived = currentApp.receivedAmount;

      // Status change to 'শুনানি' with expense ৳500 (automatically recorded as expense)
      final expenseAmount = Money.fromTaka(500);
      const shId = 'sh-test-status-hearing';
      final statusExpense = DemoExpense(
        id: 'exp-sh-test-hearing',
        applicationId: currentApp.id,
        applicationTitle: '${currentApp.workType} - ${currentApp.applicantName}',
        amount: expenseAmount,
        category: 'কাজের খরচ',
        date: DateTime.now(),
        isGeneral: false,
        note: 'শুনানির কাজের সরকারি ফি ও খরচ',
        statusHistoryId: shId,
        statusName: 'শুনানি',
        isStatusExpense: true,
      );

      final updatedStatusHistory = List<DemoStatusHistory>.from(currentApp.statusHistory)
        ..insert(
          0,
          DemoStatusHistory(
            id: shId,
            prevStatus: currentApp.status,
            newStatus: 'শুনানি',
            changedAt: DateTime.now(),
            note: 'শুনানির কাজের সরকারি ফি ও খরচ • কাজের খরচ: ৳৫০০',
          ),
        );

      final updatedExpenses = List<DemoExpense>.from(currentApp.expenses)..insert(0, statusExpense);

      final updatedApp = DemoApplication(
        id: currentApp.id,
        applicantId: currentApp.applicantId,
        applicantName: currentApp.applicantName,
        applicantPhone: currentApp.applicantPhone,
        workType: currentApp.workType,
        officeName: currentApp.officeName,
        applicationDate: currentApp.applicationDate,
        status: 'শুনানি',
        agreedAmount: currentApp.agreedAmount,
        receivedAmount: currentApp.receivedAmount,
        expenseAmount: currentApp.expenseAmount + expenseAmount,
        payments: currentApp.payments,
        expenses: updatedExpenses,
        statusHistory: updatedStatusHistory,
      );

      final idx = DemoStore.applications.indexWhere((a) => a.id == testApp.id);
      DemoStore.applications[idx] = updatedApp;

      // Verify application expense was recorded and income was NOT affected
      expect(updatedApp.status, 'শুনানি');
      expect(updatedApp.expenseAmount, initialExpense + expenseAmount);
      expect(updatedApp.receivedAmount, initialReceived, reason: 'Status change does not record income');
      expect(updatedApp.statusHistory.first.newStatus, 'শুনানি');

      // Verify appears in global transaction history with statusExpense source
      final allTx = DemoStore.getAllTransactions();
      final tx = allTx.firstWhere((t) => t.id == 'exp-sh-test-hearing');
      expect(tx.isExpense, isTrue);
      expect(tx.source, TransactionSource.statusExpense);
      expect(tx.amount, Money.fromTaka(500));
      expect(tx.applicationId, testApp.id);
      expect(tx.statusName, 'শুনানি');
    });

    test('Scenario 3: Status Change with Expense (টাকা খরচ)', () {
      final currentApp = DemoStore.applications.firstWhere((a) => a.id == testApp.id);
      final initialExpense = currentApp.expenseAmount;

      // Change status to 'প্রস্তাব প্রেরণ' with expense ৳300
      final expenseAmount = Money.fromTaka(300);
      const shId = 'sh-test-status-proposal';
      final statusExpense = DemoExpense(
        id: 'exp-sh-test-proposal',
        applicationId: currentApp.id,
        applicationTitle: '${currentApp.workType} - ${currentApp.applicantName}',
        amount: expenseAmount,
        category: 'কাজের খরচ',
        date: DateTime.now(),
        isGeneral: false,
        note: 'প্রয়োজনীয় কাজের জন্য খরচ',
        statusHistoryId: shId,
        statusName: 'প্রস্তাব প্রেরণ',
        isStatusExpense: true,
      );

      final updatedStatusHistory = List<DemoStatusHistory>.from(currentApp.statusHistory)
        ..insert(
          0,
          DemoStatusHistory(
            id: shId,
            prevStatus: currentApp.status,
            newStatus: 'প্রস্তাব প্রেরণ',
            changedAt: DateTime.now(),
            note: 'প্রয়োজনীয় কাজের জন্য খরচ • কাজের খরচ: ৳৩০০',
          ),
        );

      final updatedExpenses = List<DemoExpense>.from(currentApp.expenses)..insert(0, statusExpense);

      final updatedApp = DemoApplication(
        id: currentApp.id,
        applicantId: currentApp.applicantId,
        applicantName: currentApp.applicantName,
        applicantPhone: currentApp.applicantPhone,
        workType: currentApp.workType,
        officeName: currentApp.officeName,
        applicationDate: currentApp.applicationDate,
        status: 'প্রস্তাব প্রেরণ',
        agreedAmount: currentApp.agreedAmount,
        receivedAmount: currentApp.receivedAmount,
        expenseAmount: currentApp.expenseAmount + expenseAmount,
        payments: currentApp.payments,
        expenses: updatedExpenses,
        statusHistory: updatedStatusHistory,
      );

      final idx = DemoStore.applications.indexWhere((a) => a.id == testApp.id);
      DemoStore.applications[idx] = updatedApp;

      // Verify application expense was recorded
      expect(updatedApp.status, 'প্রস্তাব প্রেরণ');
      expect(updatedApp.expenseAmount, initialExpense + expenseAmount);

      // Verify it appears in global transactions with statusExpense
      final allTx = DemoStore.getAllTransactions();
      final tx = allTx.firstWhere((t) => t.id == 'exp-sh-test-proposal');
      expect(tx.isExpense, isTrue);
      expect(tx.source, TransactionSource.statusExpense);
      expect(tx.amount, Money.fromTaka(300));
      expect(tx.applicationId, testApp.id);
    });

    test('Scenario 4: Status Change without Money', () {
      final currentApp = DemoStore.applications.firstWhere((a) => a.id == testApp.id);
      final initialReceived = currentApp.receivedAmount;
      final initialExpense = currentApp.expenseAmount;
      final initialPaymentCount = currentApp.payments.length;
      final initialExpenseCount = currentApp.expenses.length;

      // Status change to 'অপেক্ষমাণ' with NO money entered
      final updatedHistory = List<DemoStatusHistory>.from(currentApp.statusHistory)
        ..insert(
          0,
          DemoStatusHistory(
            id: 'sh-test-no-money',
            prevStatus: currentApp.status,
            newStatus: 'অপেক্ষমাণ',
            changedAt: DateTime.now(),
            note: 'কাগজপত্র যাচাই চলছে',
          ),
        );

      final updatedApp = DemoApplication(
        id: currentApp.id,
        applicantId: currentApp.applicantId,
        applicantName: currentApp.applicantName,
        applicantPhone: currentApp.applicantPhone,
        workType: currentApp.workType,
        officeName: currentApp.officeName,
        applicationDate: currentApp.applicationDate,
        status: 'অপেক্ষমাণ',
        agreedAmount: currentApp.agreedAmount,
        receivedAmount: currentApp.receivedAmount,
        expenseAmount: currentApp.expenseAmount,
        payments: currentApp.payments,
        expenses: currentApp.expenses,
        statusHistory: updatedHistory,
      );

      // Verify status changed and history created
      expect(updatedApp.status, 'অপেক্ষমাণ');
      expect(updatedApp.statusHistory.first.newStatus, 'অপেক্ষমাণ');

      // Verify NO financial changes occurred
      expect(updatedApp.receivedAmount, initialReceived);
      expect(updatedApp.expenseAmount, initialExpense);
      expect(updatedApp.payments.length, initialPaymentCount);
      expect(updatedApp.expenses.length, initialExpenseCount);
    });

    test('Scenario 5: Independent Income (স্বতন্ত্র আয়)', () {
      final initialTotalIncome = DemoStore.totalIncome;
      final initialIndependent = DemoStore.totalIndependentIncome;

      final independentIncome = DemoIncome(
        id: 'inc-test-online-1',
        category: 'অন্যান্য আয়',
        amount: Money.fromTaka(1200),
        date: DateTime.now(),
        paymentMethod: 'নগদ',
        customerName: 'বশির আহমেদ',
        note: 'অনলাইন ফরম পূরণ ও প্রিন্ট সেবা',
      );

      DemoStore.independentIncomes.insert(0, independentIncome);

      // Verify stored and no application required
      expect(DemoStore.independentIncomes.first.id, 'inc-test-online-1');
      expect(DemoStore.totalIndependentIncome, initialIndependent + Money.fromTaka(1200));
      expect(DemoStore.totalIncome, initialTotalIncome + Money.fromTaka(1200));

      // Verify appears in global transactions with independentIncome source
      final tx = DemoStore.getAllTransactions().firstWhere((t) => t.id == 'inc-test-online-1');
      expect(tx.isIncome, isTrue);
      expect(tx.source, TransactionSource.independentIncome);
      expect(tx.applicationId, isNull, reason: 'Independent income must NOT require an application');
      expect(tx.customerName, 'বশির আহমেদ');
    });

    test('Scenario 6: Application Expense (কাজের খরচ)', () {
      final initialTotalExpense = DemoStore.totalExpense;
      final currentApp = DemoStore.applications.firstWhere((a) => a.id == testApp.id);

      final appExpense = DemoExpense(
        id: 'exp-test-central-1',
        applicationId: currentApp.id,
        applicationTitle: '${currentApp.workType} - ${currentApp.applicantName}',
        amount: Money.fromTaka(850),
        category: 'কাগজপত্র ও ফটোকপি',
        date: DateTime.now(),
        isGeneral: false,
        note: 'দলিল ফটোকপি ও লেমিনেশন',
      );

      final updatedExpenses = List<DemoExpense>.from(currentApp.expenses)..insert(0, appExpense);
      final updatedApp = DemoApplication(
        id: currentApp.id,
        applicantId: currentApp.applicantId,
        applicantName: currentApp.applicantName,
        applicantPhone: currentApp.applicantPhone,
        workType: currentApp.workType,
        officeName: currentApp.officeName,
        applicationDate: currentApp.applicationDate,
        status: currentApp.status,
        agreedAmount: currentApp.agreedAmount,
        receivedAmount: currentApp.receivedAmount,
        expenseAmount: currentApp.expenseAmount + Money.fromTaka(850),
        payments: currentApp.payments,
        expenses: updatedExpenses,
        statusHistory: currentApp.statusHistory,
      );

      final idx = DemoStore.applications.indexWhere((a) => a.id == testApp.id);
      DemoStore.applications[idx] = updatedApp;

      // Verify updated in application
      expect(updatedApp.expenseAmount, Money.fromTaka(850));
      expect(DemoStore.totalExpense, initialTotalExpense + Money.fromTaka(850));

      // Verify appears in global transactions
      final tx = DemoStore.getAllTransactions().firstWhere((t) => t.id == 'exp-test-central-1');
      expect(tx.isExpense, isTrue);
      expect(tx.source, TransactionSource.applicationExpense);
      expect(tx.applicationId, testApp.id);
    });

    test('Scenario 7: General Shop Expense (দোকানের সাধারণ খরচ)', () {
      final initialTotalExpense = DemoStore.totalExpense;
      final initialGeneralExpense = DemoStore.totalGeneralExpense;

      final generalExp = DemoExpense(
        id: 'gexp-test-rent',
        amount: Money.fromTaka(6000),
        category: 'দোকান ভাড়া',
        date: DateTime.now(),
        isGeneral: true,
        note: 'দোকানের মাসিক ভাড়া',
      );

      DemoStore.generalExpenses.insert(0, generalExp);

      // Verify recorded
      expect(DemoStore.totalGeneralExpense, initialGeneralExpense + Money.fromTaka(6000));
      expect(DemoStore.totalExpense, initialTotalExpense + Money.fromTaka(6000));

      // Verify appears in global transactions without application link
      final tx = DemoStore.getAllTransactions().firstWhere((t) => t.id == 'gexp-test-rent');
      expect(tx.isExpense, isTrue);
      expect(tx.source, TransactionSource.generalExpense);
      expect(tx.applicationId, isNull, reason: 'General shop expenses must NOT require an application');
    });

    test('Scenario 8: Centralized Financial Calculations & Precision', () {
      // 1. Total Income equals Application Income + Independent Income
      expect(
        DemoStore.totalIncome,
        DemoStore.totalApplicationIncome + DemoStore.totalIndependentIncome,
      );

      // 2. Total Expense equals Application Expense + General Expense
      expect(
        DemoStore.totalExpense,
        DemoStore.totalApplicationExpense + DemoStore.totalGeneralExpense,
      );

      // 3. Net Income equals Total Income - Total Expense
      expect(
        DemoStore.netIncome,
        DemoStore.totalIncome - DemoStore.totalExpense,
      );

      // 4. Agreed service amounts are NOT counted as received income
      Money totalAgreed = Money.zero;
      for (final a in DemoStore.applications) {
        totalAgreed += a.agreedAmount;
      }
      expect(
        DemoStore.totalApplicationIncome < totalAgreed,
        isTrue,
        reason: 'Unpaid agreed service amounts must NOT be counted as received revenue',
      );

      // 5. Total outstanding due is exact sum of application due amounts
      Money calculatedDue = Money.zero;
      for (final a in DemoStore.applications) {
        if (a.dueAmount.isPositive) {
          calculatedDue += a.dueAmount;
        }
      }
      expect(DemoStore.totalOutstandingDue, calculatedDue);

      // 6. Zero duplicate transactions in getAllTransactions()
      final allTx = DemoStore.getAllTransactions();
      final txIds = allTx.map((t) => t.id).toSet();
      expect(
        txIds.length,
        allTx.length,
        reason: 'Every transaction ID must be unique with zero duplicate records',
      );

      // 7. Due applications list only contains applications with due > 0
      final dueApps = DemoStore.getDueApplications();
      for (final a in dueApps) {
        expect(a.dueAmount.isPositive, isTrue);
      }
    });
  });
}
