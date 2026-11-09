import '../../../../core/utils/money.dart';
import '../../../applications/domain/models/application_with_financials.dart';

/// রেফারেন্স ব্যক্তির সারসংক্ষেপ ও পরিসংখ্যান মডেল
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

  static const zero = ReferenceStats(
    totalApplications: 0,
    completedCount: 0,
    ongoingCount: 0,
    pendingCount: 0,
    totalAgreed: Money.zero,
    totalReceived: Money.zero,
    totalDue: Money.zero,
  );

  /// প্রদত্ত আবেদন তালিকা থেকে পরিসংখ্যান গণনা
  static ReferenceStats fromApplications(List<ApplicationWithFinancials> apps) {
    int completed = 0;
    int ongoing = 0;
    int pending = 0;
    int agreedPaisa = 0;
    int receivedPaisa = 0;
    int duePaisa = 0;

    for (final a in apps) {
      final st = a.application.status;
      if (st == 'সম্পন্ন' || st == 'মঞ্জুর' || st == 'পাশ') {
        completed++;
      } else if (st == 'প্রস্তাব প্রেরণ' ||
          st == 'প্রতিবেদন দাখিল' ||
          st == 'শুনানি' ||
          st == 'ডিসিআর প্রস্তুত' ||
          st == 'PER') {
        ongoing++;
      } else {
        pending++;
      }
      agreedPaisa += a.agreed.paisa;
      receivedPaisa += a.received.paisa;
      duePaisa += a.effectiveDue.paisa;
    }

    return ReferenceStats(
      totalApplications: apps.length,
      completedCount: completed,
      ongoingCount: ongoing,
      pendingCount: pending,
      totalAgreed: Money.fromPaisa(agreedPaisa),
      totalReceived: Money.fromPaisa(receivedPaisa),
      totalDue: Money.fromPaisa(duePaisa),
    );
  }
}
