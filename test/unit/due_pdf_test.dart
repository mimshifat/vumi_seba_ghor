import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/theme/app_theme.dart';
import 'package:bhumi_kajer_hisab/core/utils/money.dart';
import 'package:bhumi_kajer_hisab/features/applications/domain/models/application_with_financials.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/providers/application_providers.dart';
import 'package:bhumi_kajer_hisab/features/finance/data/services/due_pdf_service.dart';
import 'package:bhumi_kajer_hisab/features/finance/presentation/screens/due_management_screen.dart';
import 'package:bhumi_kajer_hisab/features/finance/presentation/screens/due_pdf_preview_screen.dart';
import 'package:bhumi_kajer_hisab/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DuePdfService (Canvas বাংলা শেপিং)', () {
    testWidgets('মাল্টি-পেজ বাংলা বকেয়া তালিকার বৈধ PDF বাইট তৈরি করে', (tester) async {
      await tester.runAsync(() async {
        final rows = List.generate(
          35,
          (i) => DuePdfRow(
            applicantName: 'আব্দুল করিম ও ফাতেমা খাতুন (${i + 1})',
            applicantPhone: '01711223344',
            workType: 'নামজারি ও জমাভাগ',
            agreedAmount: Money.fromTaka(7000 + i * 500),
            receivedAmount: Money.fromTaka(3000),
            dueAmount: Money.fromTaka(4000 + i * 500),
          ),
        );

        final pdfBytes = await DuePdfService.buildDueListPdf(
          rows: rows,
          shopName: 'রজব ভূমি সেবা ঘর',
          printedAt: DateTime(2026, 11, 10),
        );

        expect(pdfBytes, isNotEmpty);
        expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
      });
    });

    testWidgets('খালি বকেয়া তালিকাতেও বৈধ PDF বাইট তৈরি করে', (tester) async {
      await tester.runAsync(() async {
        final pdfBytes = await DuePdfService.buildDueListPdf(
          rows: const [],
          shopName: 'রজব ভূমি সেবা ঘর',
        );

        expect(pdfBytes, isNotEmpty);
        expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
      });
    });
  });

  group('DueManagementScreen PDF অ্যাকশন', () {
    Widget buildScreen(List<ApplicationWithFinancials> items) {
      return ProviderScope(
        overrides: [
          applicationsWithFinancialsStreamProvider
              .overrideWith((ref) => Stream.value(items)),
          shopSettingsStreamProvider
              .overrideWith((ref) => Stream.value({'shop_name': 'রজব ভূমি সেবা ঘর'})),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DueManagementScreen(),
        ),
      );
    }

    testWidgets('বকেয়া না থাকলে PDF আইকনে চাপ দিলে তথ্যপূর্ণ মেসেজ দেখায়',
        (tester) async {
      await tester.pumpWidget(buildScreen(const []));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
      await tester.pumpAndSettle();

      expect(
        find.text('তৈরি করার মতো কোনো বকেয়া পাওনা নেই।'),
        findsOneWidget,
      );
      expect(find.byType(DuePdfPreviewScreen), findsNothing);
    });

    testWidgets('বকেয়া থাকলে PDF আইকনে চাপ দিলে DuePdfPreviewScreen খোলে',
        (tester) async {
      final nowMs = DateTime(2026, 11, 10).millisecondsSinceEpoch;
      final item = ApplicationWithFinancials(
        application: Application(
          id: 'app-due-1',
          applicantId: 'person-1',
          applicantName: 'রজব',
          applicantPhone: '01795449455',
          officeName: 'সাভার ভূমি অফিস',
          workType: 'নামজারি',
          applicationDate: nowMs,
          status: 'আবেদন',
          agreedAmount: 700000,
          isMarkedAsPaid: 0,
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
        totalReceivedPaisa: 300000,
        totalExpensePaisa: 0,
      );

      await tester.pumpWidget(buildScreen([item]));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
        await tester.pump();
        // PDF তৈরি (ui.Picture.toImage + png encode) শেষ হওয়া পর্যন্ত অপেক্ষা
        for (var i = 0; i < 30; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (find.byType(DuePdfPreviewScreen).evaluate().isNotEmpty) {
            break;
          }
        }
      });
      await tester.pump();

      expect(find.byType(DuePdfPreviewScreen), findsOneWidget);
      expect(find.text('বকেয়া তালিকা PDF প্রিভিউ'), findsOneWidget);
    });
  });
}

