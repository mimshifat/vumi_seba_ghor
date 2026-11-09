import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/money.dart';
import '../../../applications/domain/models/application_with_financials.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';

/// ড্যাশবোর্ডের সামগ্রিক অপারেশনাল পরিসংখ্যান
class DashboardStats {
  final int totalActiveApplications;
  final int ongoingApplications;
  final int hearingApplications;
  final int completedApplications;
  final int todayTasksCount;
  final Money todayReceived;
  final Money todayExpense;
  final Money totalEffectiveDue;

  const DashboardStats({
    required this.totalActiveApplications,
    required this.ongoingApplications,
    required this.hearingApplications,
    required this.completedApplications,
    required this.todayTasksCount,
    required this.todayReceived,
    required this.todayExpense,
    required this.totalEffectiveDue,
  });
}

/// ড্যাশবোর্ডের মূল পরিসংখ্যান প্রোভাইডার
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final applications =
      await ref.watch(applicationsWithFinancialsStreamProvider.future);
  final todaySnapshot = await ref.watch(todayFinancialSnapshotProvider.future);
  final todayTasks = await ref.watch(todayTasksCountProvider.future);

  int totalActive = applications.length;
  int ongoing = 0;
  int hearing = 0;
  int completed = 0;
  int totalDuePaisa = 0;

  for (final item in applications) {
    final status = item.application.status;
    if (status == 'সম্পন্ন') {
      completed++;
    } else if (status == 'নামঞ্জুর' || status == 'বাতিল') {
      // ব্যতিক্রম
    } else {
      ongoing++;
    }

    if (status == 'শুনানি') {
      hearing++;
    }

    totalDuePaisa += item.effectiveDue.paisa;
  }

  return DashboardStats(
    totalActiveApplications: totalActive,
    ongoingApplications: ongoing,
    hearingApplications: hearing,
    completedApplications: completed,
    todayTasksCount: todayTasks,
    todayReceived: Money.fromPaisa(todaySnapshot.totalApplicationReceived),
    todayExpense: Money.fromPaisa(
        todaySnapshot.totalApplicationExpense + todaySnapshot.totalGeneralExpense),
    totalEffectiveDue: Money.fromPaisa(totalDuePaisa),
  );
});

/// সাম্প্রতিক আবেদন তালিকা (ড্যাশবোর্ডের জন্য শীর্ষ ৫টি)
final recentApplicationsProvider =
    Provider<List<ApplicationWithFinancials>>((ref) {
  final asyncApps = ref.watch(applicationsWithFinancialsStreamProvider);
  return asyncApps.when(
    data: (apps) => apps.take(5).toList(),
    loading: () => const [],
    error: (_, __) => const [],
  );
});

