import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/money.dart';

class ReferenceStats {
  final int totalApplications;
  final int completedCount;
  final int ongoingCount;
  final int pendingCount;
  final Money totalAgreed;
  final Money totalReceived;
  final Money totalDue;

  const ReferenceStats({
    required this.totalApplications,
    required this.completedCount,
    required this.ongoingCount,
    required this.pendingCount,
    required this.totalAgreed,
    required this.totalReceived,
    required this.totalDue,
  });
}

class ReferenceHelper {
  /// Returns all applications referred by a reference person.
  static List<DemoApplication> getApplicationsForReference(String referenceId, [String? referenceName]) {
    return DemoStore.applications.where((app) {
      if (app.referencePersonId != null && app.referencePersonId == referenceId) {
        return true;
      }
      if (referenceName != null &&
          referenceName.trim().isNotEmpty &&
          app.referencePersonName != null &&
          app.referencePersonName!.trim() == referenceName.trim()) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Calculates aggregate statistics for a given reference.
  static ReferenceStats getStats(String referenceId, [String? referenceName]) {
    final apps = getApplicationsForReference(referenceId, referenceName);
    int completed = 0;
    int ongoing = 0;
    int pending = 0;
    int agreedPaisa = 0;
    int receivedPaisa = 0;

    for (final app in apps) {
      if (app.status == 'সম্পন্ন' || app.status == 'মঞ্জুর' || app.status == 'পাশ') {
        completed++;
      } else if (app.status == 'প্রস্তাব প্রেরণ' ||
          app.status == 'প্রতিবেদন দাখিল' ||
          app.status == 'শুনানি' ||
          app.status == 'ডিসিআর প্রস্তুত' ||
          app.status == 'PER') {
        ongoing++;
      } else {
        pending++;
      }
      agreedPaisa += app.agreedAmount.paisa;
      receivedPaisa += app.receivedAmount.paisa;
    }

    final totalAgreed = Money.fromPaisa(agreedPaisa);
    final totalReceived = Money.fromPaisa(receivedPaisa);
    final totalDue = totalAgreed - totalReceived;

    return ReferenceStats(
      totalApplications: apps.length,
      completedCount: completed,
      ongoingCount: ongoing,
      pendingCount: pending,
      totalAgreed: totalAgreed,
      totalReceived: totalReceived,
      totalDue: totalDue,
    );
  }
}
