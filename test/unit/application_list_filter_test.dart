import 'package:bhumi_kajer_hisab/core/constants/app_colors.dart';
import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/theme/app_theme.dart';
import 'package:bhumi_kajer_hisab/features/applications/domain/models/application_with_financials.dart';
import 'package:bhumi_kajer_hisab/features/applications/domain/models/proposal_print_models.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/providers/application_providers.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/providers/proposal_print_providers.dart';
import 'package:bhumi_kajer_hisab/features/applications/presentation/screens/application_list_screen.dart';
import 'package:bhumi_kajer_hisab/features/offices/presentation/providers/office_providers.dart';
import 'package:bhumi_kajer_hisab/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildScreen(
    List<ApplicationWithFinancials> apps, {
    List<PendingProposalCandidate> pendingProposals = const [],
  }) {
    return ProviderScope(
      overrides: [
        applicationsWithFinancialsStreamProvider
            .overrideWith((ref) => Stream.value(apps)),
        pendingProposalCandidatesStreamProvider
            .overrideWith((ref) => Stream.value(pendingProposals)),
        workTypesStreamProvider.overrideWith((ref) => Stream.value([])),
        officesStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ApplicationListScreen(),
      ),
    );
  }

  ApplicationWithFinancials makeApp({
    required String id,
    required String name,
    required String status,
  }) {
    final nowMs = DateTime(2026, 11, 10).millisecondsSinceEpoch;
    return ApplicationWithFinancials(
      application: Application(
        id: id,
        applicantId: 'person-$id',
        applicantName: name,
        applicantPhone: '01711223344',
        officeName: 'সাভার ভূমি অফিস',
        workType: 'নামজারি',
        applicationDate: nowMs,
        status: status,
        agreedAmount: 500000,
        isMarkedAsPaid: 0,
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
      totalReceivedPaisa: 500000,
      totalExpensePaisa: 0,
    );
  }

  group('ApplicationListScreen filter pill colors & proposal banner sync', () {
    testWidgets('সিলেক্ট করা কুইক ফিল্টার চিপের টেক্সট সাদা নয় এবং রঙের সাথে সামঞ্জস্যপূর্ণ',
        (tester) async {
      await tester.pumpWidget(
        buildScreen([
          makeApp(id: '1', name: 'রজব', status: 'সম্পন্ন'),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('সম্পন্ন (১)'));
      await tester.pumpAndSettle();

      final chipFinder = find.ancestor(
        of: find.text('সম্পন্ন (১)'),
        matching: find.byType(FilterChip),
      );
      final chip = tester.widget<FilterChip>(chipFinder);
      expect(chip.selected, isTrue);
      expect(chip.labelStyle?.color, isNot(Colors.white));
      expect(
        chip.labelStyle?.color,
        Color.lerp(AppColors.emerald, Colors.black, 0.22),
      );
    });

    testWidgets(
        'প্রস্তাব প্রেরণ সিলেক্টে সব প্রিন্ট করা থাকলে ব্যানার দেখায় না',
        (tester) async {
      await tester.pumpWidget(
        buildScreen(
          [makeApp(id: '1', name: 'রজব', status: 'প্রস্তাব প্রেরণ')],
          pendingProposals: const [],
        ),
      );
      await tester.pumpAndSettle();

      final proposalChipEmpty = find.text('প্রস্তাব প্রেরণ (১)');
      await tester.ensureVisible(proposalChipEmpty);
      await tester.pumpAndSettle();
      await tester.tap(proposalChipEmpty);
      await tester.pumpAndSettle();

      expect(
        find.text('প্রস্তাব প্রেরণের সব কেস আগে প্রিন্ট করা হয়েছে'),
        findsNothing,
      );
      expect(find.textContaining('প্রিন্ট বাকি আছে'), findsNothing);
    });

    testWidgets(
        'প্রস্তাব প্রেরণে প্রিন্ট বাকি থাকলে ব্যানার দেখায় ও সম্পন্ন-এ গেলে মুছে যায়',
        (tester) async {
      final pendingCandidate = PendingProposalCandidate(
        application: makeApp(
          id: '1',
          name: 'রজব',
          status: 'প্রস্তাব প্রেরণ',
        ).application,
        statusHistoryId: 'sh-1',
        statusEnteredAt: DateTime(2026, 11, 10).millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        buildScreen(
          [
            makeApp(id: '1', name: 'রজব', status: 'প্রস্তাব প্রেরণ'),
            makeApp(id: '2', name: 'করিম', status: 'সম্পন্ন'),
          ],
          pendingProposals: [pendingCandidate],
        ),
      );
      await tester.pumpAndSettle();

      final proposalChip = find.text('প্রস্তাব প্রেরণ (১)');
      await tester.ensureVisible(proposalChip);
      await tester.pumpAndSettle();
      await tester.tap(proposalChip);
      await tester.pumpAndSettle();

      expect(
        find.text('প্রিন্ট বাকি আছে: নতুন ১ টি কেস'),
        findsOneWidget,
      );
      expect(find.text('অবস্থা: প্রস্তাব প্রেরণ'), findsOneWidget);
      expect(find.text('রজব'), findsOneWidget);

      final completedChip = find.text('সম্পন্ন (১)');
      await tester.ensureVisible(completedChip);
      await tester.pumpAndSettle();
      await tester.tap(completedChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('প্রিন্ট বাকি আছে'), findsNothing);
      expect(find.text('অবস্থা: প্রস্তাব প্রেরণ'), findsNothing);
      expect(find.text('মোট দেখানো হচ্ছে: ১ টি ফাইল'), findsOneWidget);
      expect(find.text('করিম'), findsOneWidget);
    });
  });
}

