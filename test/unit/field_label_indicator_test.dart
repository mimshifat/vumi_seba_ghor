import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/constants/app_colors.dart';
import 'package:bhumi_kajer_hisab/core/theme/app_theme.dart';
import 'package:bhumi_kajer_hisab/core/widgets/app_field_label.dart';
import 'package:bhumi_kajer_hisab/core/widgets/app_text_field.dart';
import 'package:bhumi_kajer_hisab/core/widgets/money_field.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/screens/application_create_screen.dart';
import 'package:bhumi_kajer_hisab/features/finance/presentation/screens/income_form_screen.dart';
import 'package:bhumi_kajer_hisab/features/finance/presentation/screens/expense_form_screen.dart';
import 'package:bhumi_kajer_hisab/features/finance/presentation/screens/payment_form_screen.dart';
import 'package:bhumi_kajer_hisab/features/persons/presentation/screens/person_create_edit_screen.dart';
import 'package:bhumi_kajer_hisab/features/tasks/presentation/screens/task_create_edit_screen.dart';

void main() {
  group('AppFieldLabel & Field Indicators Standard Tests', () {
    testWidgets('AppFieldLabel displays red * when isRequired is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFieldLabel(
              label: 'মোবাইল নম্বর',
              isRequired: true,
            ),
          ),
        ),
      );

      // Verify text is present with asterisk
      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.textSpan, isNotNull);

      final textSpan = textWidget.textSpan as TextSpan;
      expect(textSpan.text, 'মোবাইল নম্বর');
      expect(textSpan.children, isNotNull);
      expect(textSpan.children!.length, 1);

      final starSpan = textSpan.children!.first as TextSpan;
      expect(starSpan.text, ' *');
      expect(starSpan.style?.color, AppColors.rose);
      expect(starSpan.style?.fontWeight, FontWeight.bold);

      // Plain text check
      expect(textSpan.toPlainText(), 'মোবাইল নম্বর *');
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
    });

    testWidgets('AppFieldLabel displays NO asterisk and NO "ঐচ্ছিক" when isRequired is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppFieldLabel(
              label: 'ঠিকানা',
              isRequired: false,
            ),
          ),
        ),
      );

      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      final textSpan = textWidget.textSpan as TextSpan;

      expect(textSpan.text, 'ঠিকানা');
      expect(textSpan.children, isEmpty);
      expect(textSpan.toPlainText(), 'ঠিকানা');
      expect(find.textContaining('*'), findsNothing);
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
    });

    testWidgets('AppTextField integrates AppFieldLabel correctly for required & optional fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                AppTextField(
                  label: 'নাম',
                  isRequired: true,
                ),
                AppTextField(
                  label: 'ঠিকানা',
                  isRequired: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('নাম *'), findsOneWidget);
      expect(find.text('ঠিকানা'), findsOneWidget);
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
    });

    testWidgets('MoneyField integrates AppFieldLabel correctly for required & optional fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                MoneyField(
                  label: 'চুক্তিকৃত টাকা',
                  isRequired: true,
                ),
                MoneyField(
                  label: 'অগ্রিম জমা',
                  isRequired: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('চুক্তিকৃত টাকা *'), findsOneWidget);
      expect(find.text('অগ্রিম জমা'), findsOneWidget);
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
    });
  });

  group('Forms Consistency & No "ঐচ্ছিক" Appearance Tests', () {
    testWidgets('ApplicationCreateScreen has NO "ঐচ্ছিক" anywhere across wizard steps', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ApplicationCreateScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Client Info
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
      expect(find.text('আবেদনকারীর নাম *'), findsOneWidget);
      expect(find.text('মোবাইল নম্বর *'), findsOneWidget);
      expect(find.text('ঠিকানা'), findsOneWidget);

      // Enter required fields to advance to Step 2
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'মো: রহিম উদ্দিন'); // Name
      await tester.enterText(textFields.at(1), '01711223344'); // Phone
      await tester.pumpAndSettle();

      // Tap Next to advance to Step 2
      await tester.tap(find.text('পরবর্তী ধাপ'));
      await tester.pumpAndSettle();

      // Step 2: Work and Office Info
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
      expect(find.text('কাজের ধরন *'), findsOneWidget);
      expect(find.text('অফিসের নাম *'), findsOneWidget);
      expect(find.text('আবেদনের তারিখ *'), findsOneWidget);
      expect(find.text('মৌজার নাম'), findsOneWidget);

      // Enter required application number
      final step2Fields = find.byType(TextField);
      await tester.enterText(step2Fields.at(0), 'SAV-TEST-999');
      await tester.pumpAndSettle();

      // Tap Next to advance to Step 3
      await tester.tap(find.text('পরবর্তী ধাপ'));
      await tester.pumpAndSettle();

      // Step 3: Payment and Summary
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
      expect(find.text('রেফারেন্স ব্যক্তি'), findsOneWidget);
      expect(find.text('চুক্তিকৃত মোট সার্ভিস ফি (টাকা) *'), findsOneWidget);
      expect(find.text('প্রাথমিক জমা / অগ্রিম'), findsOneWidget);
      expect(find.text('বিশেষ নোট বা গ্রাহকের নির্দেশ'), findsOneWidget);
    });

    testWidgets('PersonCreateEditScreen has NO "ঐচ্ছিক" anywhere', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PersonCreateEditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
      expect(find.text('পুরো নাম *'), findsOneWidget);
      expect(find.text('মোবাইল নম্বর *'), findsOneWidget);
      expect(find.text('ঠিকানা'), findsOneWidget);
      expect(find.text('মন্তব্য বা পরিচয় নোট'), findsOneWidget);
    });

    testWidgets('IncomeFormScreen has NO "ঐচ্ছিক" anywhere', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const IncomeFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
      expect(find.text('আয়ের পরিমাণ (টাকা) *'), findsOneWidget);
      expect(find.text('আয়ের খাত / ধরন *'), findsOneWidget);
      expect(find.text('পেমেন্ট পদ্ধতি *'), findsOneWidget);
      expect(find.text('আয়ের তারিখ *'), findsOneWidget);
      expect(find.text('ব্যক্তি বা গ্রাহকের নাম'), findsOneWidget);
      expect(find.text('বিবরণ বা নোট'), findsOneWidget);
    });

    testWidgets('ExpenseFormScreen has NO "ঐচ্ছিক" anywhere', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ExpenseFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
      expect(find.text('খরচের পরিমাণ (টাকা) *'), findsOneWidget);
      expect(find.text('খরচের খাত / ক্যাটাগরি *'), findsOneWidget);
      expect(find.text('খরচের তারিখ *'), findsOneWidget);
      expect(find.text('বিবরণ বা ভাউচার নোট'), findsOneWidget);
    });

    testWidgets('PaymentFormScreen has NO "ঐচ্ছিক" anywhere', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PaymentFormScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
      expect(find.text('জমার পরিমাণ (টাকা) *'), findsOneWidget);
      expect(find.text('জমার মাধ্যম *'), findsOneWidget);
      expect(find.text('জমার তারিখ *'), findsOneWidget);
      expect(find.text('মন্তব্য বা মানি রিসিট নম্বর'), findsOneWidget);
    });

    testWidgets('TaskCreateEditScreen has NO "ঐচ্ছিক" anywhere', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskCreateEditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
      expect(find.text('কাজের শিরোনাম *'), findsOneWidget);
      expect(find.text('কাজের বিস্তারিত বিবরণ'), findsOneWidget);
      expect(find.text('অগ্রাধিকার *'), findsOneWidget);
      expect(find.text('তারিখ *'), findsOneWidget);
      expect(find.text('সময়'), findsOneWidget);
      expect(find.text('সংশ্লিষ্ট আবেদন'), findsOneWidget);
    });
  });
}
