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
  });
}

