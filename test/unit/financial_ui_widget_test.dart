import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/demo/demo_data.dart';
import 'package:bhumi_kajer_hisab/core/widgets/app_floating_button.dart';
import 'package:bhumi_kajer_hisab/features/finance/presentation/screens/financial_overview_screen.dart';
import 'package:bhumi_kajer_hisab/features/finance/presentation/screens/income_form_screen.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/screens/application_detail_screen.dart';
import 'package:bhumi_kajer_hisab/core/utils/money.dart';

void main() {
  group('Financial UI & UX Corrections Tests', () {
    testWidgets('FinancialOverviewScreen renders two floating buttons (আয় & খরচ) and NO shortcut card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: FinancialOverviewScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. "লেনদেন এন্ট্রি শর্টকাট" card is removed
      expect(find.text('লেনদেন এন্ট্রি শর্টকাট'), findsNothing);
      expect(find.text('আয় যোগ করুন'), findsNothing);
      expect(find.text('খরচ যোগ করুন'), findsNothing);

      // 2. Exactly two AppFloatingButtons exist with exact labels "আয়" and "খরচ"
      expect(find.byType(AppFloatingButton), findsNWidgets(2));
      expect(find.widgetWithText(AppFloatingButton, 'আয়'), findsOneWidget);
      expect(find.widgetWithText(AppFloatingButton, 'খরচ'), findsOneWidget);

      // 3. Overall summary hero metrics exist
      expect(find.text('প্রকৃত নিট ইনকাম'), findsOneWidget);
      expect(find.text('মোট আদায়'), findsOneWidget);
      expect(find.text('মোট খরচ'), findsOneWidget);
      expect(find.text('মোট বকেয়া'), findsOneWidget);

      // 4. Daily summary cards exist
      expect(find.text('আজকের আয়'), findsOneWidget);
      expect(find.text('আজকের খরচ'), findsOneWidget);

      // 5. Chart section exists
      expect(find.text('আয় বনাম ব্যয়ের তুলনা'), findsOneWidget);

      // 6. Outstanding dues section exists
      expect(find.textContaining('বকেয়া তালিকা'), findsWidgets);

      // 7. Recent transactions section removed as per user request
      expect(find.text('সাম্প্রতিক লেনদেন'), findsNothing);

      // 8. Tapping 'আয়' FAB opens IncomeFormScreen
      await tester.tap(find.widgetWithText(AppFloatingButton, 'আয়'));
      await tester.pumpAndSettle();
      expect(find.text('আয় যোগ করুন (স্বাধীন আয়)'), findsOneWidget);

      // Return to overview
      Navigator.of(tester.element(find.text('আয় যোগ করুন (স্বাধীন আয়)'))).pop();
      await tester.pumpAndSettle();

      // 9. Tapping 'খরচ' FAB opens ExpenseFormScreen
      await tester.tap(find.widgetWithText(AppFloatingButton, 'খরচ'));
      await tester.pumpAndSettle();
      expect(find.text('খরচ যোগ করুন'), findsOneWidget);
    });

    testWidgets('IncomeFormScreen is strictly for independent income without application fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: IncomeFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Title & notice banner
      expect(find.text('আয় যোগ করুন (স্বাধীন আয়)'), findsOneWidget);
      expect(find.textContaining('দোকানের স্বাধীন বা অন্যান্য সার্ভিসের আয়'), findsOneWidget);

      // Verify "আবেদন থেকে আয়" is NOT in the categories
      expect(find.text('আবেদন থেকে আয়'), findsNothing);

      // Verify categories contain independent categories
      expect(find.text('অন্যান্য আয়'), findsOneWidget);
      expect(find.text('দোকানের অন্যান্য সেবা'), findsOneWidget);

      // Verify NO application selector exists
      expect(find.text('কোন আবেদনের জন্য খরচ?'), findsNothing);
      expect(find.text('আবেদন নির্বাচন'), findsNothing);
      expect(find.text('আবেদন নম্বর'), findsNothing);

      // Verify independent income fields exist
      expect(find.text('পেমেন্ট পদ্ধতি *'), findsOneWidget);
      expect(find.text('ব্যক্তি বা গ্রাহকের নাম'), findsOneWidget);
      expect(find.text('বিবরণ বা নোট'), findsOneWidget);
      expect(find.text('আয় সংরক্ষণ করুন'), findsOneWidget);
    });

    testWidgets('ApplicationDetailScreen financial tab has NO standalone "খরচ যোগ করুন" button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final app = DemoStore.applications.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ApplicationDetailScreen(application: app),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Tab 3: টাকার হিসাব
      final tabFinder = find.text('৩. টাকার হিসাব');
      expect(tabFinder, findsOneWidget);
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();

      // Financial stats exist in clean 2x2 grid
      expect(find.text('চুক্তিকৃত টাকা'), findsOneWidget);
      expect(find.text('মোট আদায়'), findsOneWidget);
      expect(find.text('বকেয়া'), findsOneWidget);
      expect(find.text('কাজের মোট খরচ'), findsOneWidget);
      // Redundant profit cards removed and renamed to actual income
      expect(find.text('আনুমানিক লাভ'), findsNothing);
      expect(find.text('অবশিষ্ট নিট লাভ'), findsNothing);
      expect(find.text('এই ফাইলে আপনার প্রকৃত ইনকাম (আয়)'), findsOneWidget);

      // Payments history has "জমা যোগ করুন" for installments
      expect(find.text('জমা যোগ করুন'), findsOneWidget);

      // IMPORTANT: Verify NO "খরচ যোগ করুন" button exists inside Application Details
      expect(find.text('খরচ যোগ করুন'), findsNothing);

      // Verify Expenses history section title exists
      expect(find.textContaining('খরচের ইতিহাস'), findsOneWidget);
    });

    testWidgets('Status Change Dialog has NO income toggle and treats money strictly as work expense', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final app = DemoStore.applications.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ApplicationDetailScreen(application: app),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'অবস্থা বদলান' button to open dialog
      final statusBtn = find.text('অবস্থা বদলান');
      expect(statusBtn, findsOneWidget);
      await tester.tap(statusBtn);
      await tester.pumpAndSettle();

      // Dialog title
      expect(find.text('আবেদনের অবস্থা পরিবর্তন'), findsOneWidget);

      // Financial section title is explicitly for expenses/fees
      expect(find.text('কাজের খরচ বা ফি'), findsOneWidget);
      expect(find.text('খরচের পরিমাণ'), findsOneWidget);

      // Verify NO "টাকা গ্রহণ (আয়)" or toggle exists
      expect(find.text('টাকা গ্রহণ (আয়)'), findsNothing);
      expect(find.text('টাকা গ্রহণ'), findsNothing);
      expect(find.text('টাকার ধরন নির্বাচন করুন: *'), findsNothing);

      // Enter amount in the expense field
      await tester.enterText(find.widgetWithText(TextField, 'খরচের পরিমাণ'), '350');
      await tester.pumpAndSettle();

      // Verify still NO toggle or payment method appears even after typing amount
      expect(find.text('টাকা গ্রহণ (আয়)'), findsNothing);
      expect(find.text('টাকা খরচ (ব্যয়)'), findsNothing);
      expect(find.text('পদ্ধতি: '), findsNothing);
    });

    test('DemoApplication mark as paid sets effective dueAmount to zero while preserving rawDueAmount', () {
      final app = DemoApplication(
        id: 'test-due-app',
        applicantId: 'app-1',
        applicantName: 'মো: রফিকুল ইসলাম',
        applicantPhone: '01711223344',
        workType: 'নামজারি',
        officeName: 'সাভার',
        applicationDate: DateTime.now(),
        status: 'আবেদন',
        agreedAmount: Money.fromTaka(7000),
        receivedAmount: Money.fromTaka(6500),
        expenseAmount: Money.fromTaka(1000),
      );

      // Initially due is ৳500
      expect(app.rawDueAmount, Money.fromTaka(500));
      expect(app.dueAmount, Money.fromTaka(500));
      expect(app.dueAmount.isPositive, isTrue);

      // When marked as paid (client won't pay the remaining 500)
      final settledApp = app.copyWith(isMarkedAsPaid: true);
      expect(settledApp.rawDueAmount, Money.fromTaka(500));
      expect(settledApp.dueAmount, Money.zero);
      expect(settledApp.dueAmount.isPositive, isFalse);

      // When un-marked, due is restored
      final restoredApp = settledApp.copyWith(isMarkedAsPaid: false);
      expect(restoredApp.dueAmount, Money.fromTaka(500));
      expect(restoredApp.dueAmount.isPositive, isTrue);
    });
  });
}
