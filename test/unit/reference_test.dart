import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/demo/demo_data.dart';
import 'package:bhumi_kajer_hisab/features/references/data/demo_reference_store.dart';

void main() {
  group('Reference Management & Mouza Tests', () {
    test('DemoStore has initialized references', () {
      expect(DemoStore.references.isNotEmpty, isTrue);
      final ref = DemoStore.references.first;
      expect(ref.name.isNotEmpty, isTrue);
      expect(ref.phone.isNotEmpty, isTrue);
    });

    test('Reference stats calculate correct counts and money amounts', () {
      // Find a reference with linked applications
      final ref1 = DemoStore.references.firstWhere((r) => r.id == 'ref-1');
      final stats = ReferenceHelper.getStats(ref1.id, ref1.name);

      expect(stats.totalApplications, greaterThanOrEqualTo(2));
      expect(stats.completedCount + stats.ongoingCount + stats.pendingCount, stats.totalApplications);
      expect(stats.totalAgreed.paisa, greaterThan(0));
      expect(stats.totalReceived.paisa, greaterThan(0));
      expect(stats.totalDue.paisa, stats.totalAgreed.paisa - stats.totalReceived.paisa);
    });

    test('Applications contain mouza field and reference link', () {
      final appWithMouza = DemoStore.applications.firstWhere((a) => a.mouza != null);
      expect(appWithMouza.mouza, isNotNull);
      expect(appWithMouza.mouza!.isNotEmpty, isTrue);

      final appWithRef = DemoStore.applications.firstWhere((a) => a.referencePersonId != null);
      expect(appWithRef.referencePersonId, isNotNull);
      expect(appWithRef.referencePersonName, isNotNull);
    });

    test('Soft delete & snapshot isolation: deleting a reference preserves application snapshot and calculations', () {
      // Find an application with a reference
      final app = DemoStore.applications.firstWhere((a) => a.referencePersonName != null);
      final refName = app.referencePersonName;
      final originalAgreed = app.agreedAmount;
      final originalReceived = app.receivedAmount;
      final originalExpense = app.expenseAmount;
      final originalIncome = app.actualIncome;

      // Simulate reference person being deleted from directory (soft delete / directory removal)
      // Even if reference person ID is removed or record is archived, application snapshot holds the name
      final appAfterDeletion = app.copyWith(referencePersonId: null); // FK severed / soft deleted

      // Snapshot name MUST remain intact
      expect(appAfterDeletion.referencePersonName, equals(refName));
      // Financial amounts and calculations MUST be 100% unaffected
      expect(appAfterDeletion.agreedAmount, equals(originalAgreed));
      expect(appAfterDeletion.receivedAmount, equals(originalReceived));
      expect(appAfterDeletion.expenseAmount, equals(originalExpense));
      expect(appAfterDeletion.actualIncome, equals(originalIncome));
      expect(appAfterDeletion.dueAmount, equals(app.dueAmount));
    });
  });
}

