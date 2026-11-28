import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/providers/application_providers.dart';
import 'package:bhumi_kajer_hisab/features/offices/presentation/screens/office_management_screen.dart';
import 'package:bhumi_kajer_hisab/features/offices/presentation/providers/office_providers.dart';

void main() {
  group('Mouza List Sheet Layout & Display Tests', () {
    testWidgets('শীটের শীর্ষে অফিসের নাম, মোট মৌজার সংখ্যা এবং নতুন মৌজা বাটন সঠিকভাবে প্রদর্শিত হয়',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75; // 392 x 872 dp

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final testOffice = Office(
        id: 'test-office-1',
        name: 'ইউনিয়ন ভূমি অফিস, আলাতুলী',
        createdAt: nowMs,
        updatedAt: nowMs,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            officesStreamProvider.overrideWith((ref) => Stream.value([testOffice])),
            applicationsWithFinancialsStreamProvider.overrideWith((ref) => Stream.value([])),
            customMouzasStreamProvider.overrideWith((ref) => Stream.value({})),
          ],
          child: const MaterialApp(
            home: OfficeManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // অফিস কার্ডে মৌজা লিঙ্কে ট্যাপ করা
      final mouzaInkWell = find.textContaining('মৌজা:');
      expect(mouzaInkWell, findsOneWidget);
      await tester.tap(mouzaInkWell);
      await tester.pumpAndSettle();

      // ১. অফিসের নাম শীর্ষ হেডার হিসেবে প্রদর্শিত হচ্ছে (কার্ড + বটম শীট উভয় স্থানে)
      final officeNameFinder = find.text('ইউনিয়ন ভূমি অফিস, আলাতুলী');
      expect(officeNameFinder, findsWidgets);

      // ২. 'মোট ১৯টি মৌজা' টেক্সট এক লাইনে সঠিকভাবে দৃশ্যমান
      final countTextFinder = find.text('মোট ১৯টি মৌজা');
      expect(countTextFinder, findsOneWidget);

      // ৩. 'নতুন মৌজা' বাটন দৃশ্যমান
      final addMouzaBtnFinder = find.widgetWithText(TextButton, 'নতুন মৌজা');
      expect(addMouzaBtnFinder, findsOneWidget);

      // ৪. টেক্সট এর প্রস্থ যাচাই (কোনোভাবেই ক্যারেক্টার অনুযায়ী ভার্টিক্যাল কলাপ্স হয়নি)
      final countRect = tester.getRect(countTextFinder);
      expect(countRect.width, greaterThan(60)); // স্বাভাবিক চওড়া টেক্সট
      expect(countRect.height, lessThan(30)); // ১ লাইনের উচ্চতা

      // ৫. সার্চ ফিল্টার কাজ করে
      final searchFinder = find.widgetWithText(TextField, 'মৌজা খুঁজুন...');
      expect(searchFinder, findsOneWidget);
      await tester.enterText(searchFinder, 'কাচারিপাড়া');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'কাচারিপাড়া'), findsOneWidget);
      expect(find.text('চর মধ্যপাড়া'), findsNothing);
    });

    testWidgets('ছোট স্ক্রিনেও (320px) কোনো প্রকার ওভারফ্লো বা টেক্সট কলাপ্স হয় না',
        (tester) async {
      tester.view.physicalSize = const Size(640, 1280);
      tester.view.devicePixelRatio = 2.0; // 320 x 640 dp (ন্যারো মোবাইল)

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final testOffice = Office(
        id: 'test-office-narrow',
        name: 'উপজেলা ভূমি অফিস, চাঁপাইনবাবগঞ্জ সদর',
        createdAt: nowMs,
        updatedAt: nowMs,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            officesStreamProvider.overrideWith((ref) => Stream.value([testOffice])),
            applicationsWithFinancialsStreamProvider.overrideWith((ref) => Stream.value([])),
            customMouzasStreamProvider.overrideWith((ref) => Stream.value({})),
          ],
          child: const MaterialApp(
            home: OfficeManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final mouzaInkWell = find.textContaining('মৌজা:');
      await tester.tap(mouzaInkWell);
      await tester.pumpAndSettle();

      // কোনো RenderFlex এরর বা ওভারফ্লো ছাড়াই খোলে
      expect(find.textContaining('মোট'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'নতুন মৌজা'), findsOneWidget);
    });
  });
}
