import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';

/// আর্থিক হিসাবের সময়সীমা ফিল্টার ধরন
enum FinancialDateFilterType {
  thisMonth,
  lastMonth,
  thisYear,
  allTime,
  today,
  customMonth,
  customRange,
}

/// আর্থিক তারিখ ফিল্টার স্টেট
class FinancialDateFilterState {
  final FinancialDateFilterType filterType;
  final int selectedYear;
  final int selectedMonth; // 1-12
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const FinancialDateFilterState({
    this.filterType = FinancialDateFilterType.thisMonth,
    required this.selectedYear,
    required this.selectedMonth,
    this.customStartDate,
    this.customEndDate,
  });

  /// epoch milliseconds রেঞ্জ বের করার লজিক
  ({int? startMs, int? endMs}) get dateRange {
    final now = DateTime.now();

    switch (filterType) {
      case FinancialDateFilterType.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (
          startMs: start.millisecondsSinceEpoch,
          endMs: end.millisecondsSinceEpoch,
        );

      case FinancialDateFilterType.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final end = DateTime(now.year, now.month, lastDay, 23, 59, 59, 999);
        return (
          startMs: start.millisecondsSinceEpoch,
          endMs: end.millisecondsSinceEpoch,
        );

      case FinancialDateFilterType.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(lastMonthDate.year, lastMonthDate.month, 1, 0, 0, 0, 0);
        final lastDay = DateTime(lastMonthDate.year, lastMonthDate.month + 1, 0).day;
        final end = DateTime(lastMonthDate.year, lastMonthDate.month, lastDay, 23, 59, 59, 999);
        return (
          startMs: start.millisecondsSinceEpoch,
          endMs: end.millisecondsSinceEpoch,
        );

      case FinancialDateFilterType.thisYear:
        final start = DateTime(now.year, 1, 1, 0, 0, 0, 0);
        final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
        return (
          startMs: start.millisecondsSinceEpoch,
          endMs: end.millisecondsSinceEpoch,
        );

      case FinancialDateFilterType.customMonth:
        final start = DateTime(selectedYear, selectedMonth, 1, 0, 0, 0, 0);
        final lastDay = DateTime(selectedYear, selectedMonth + 1, 0).day;
        final end = DateTime(selectedYear, selectedMonth, lastDay, 23, 59, 59, 999);
        return (
          startMs: start.millisecondsSinceEpoch,
          endMs: end.millisecondsSinceEpoch,
        );

      case FinancialDateFilterType.customRange:
        if (customStartDate != null && customEndDate != null) {
          final start = DateTime(customStartDate!.year, customStartDate!.month,
              customStartDate!.day, 0, 0, 0, 0);
          final end = DateTime(customEndDate!.year, customEndDate!.month,
              customEndDate!.day, 23, 59, 59, 999);
          return (
            startMs: start.millisecondsSinceEpoch,
            endMs: end.millisecondsSinceEpoch,
          );
        }
        return (startMs: null, endMs: null);

      case FinancialDateFilterType.allTime:
        return (startMs: null, endMs: null);
    }
  }

  FinancialDateFilterState copyWith({
    FinancialDateFilterType? filterType,
    int? selectedYear,
    int? selectedMonth,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return FinancialDateFilterState(
      filterType: filterType ?? this.filterType,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

/// আর্থিক তারিখ ফিল্টার কন্ট্রোলার
class FinancialDateFilterNotifier
    extends StateNotifier<FinancialDateFilterState> {
  FinancialDateFilterNotifier()
      : super(FinancialDateFilterState(
          selectedYear: DateTime.now().year,
          selectedMonth: DateTime.now().month,
        ));

  void setFilterType(FinancialDateFilterType type) {
    state = state.copyWith(filterType: type);
  }

  void setCustomMonth(int year, int month) {
    state = state.copyWith(
      filterType: FinancialDateFilterType.customMonth,
      selectedYear: year,
      selectedMonth: month,
    );
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      filterType: FinancialDateFilterType.customRange,
      customStartDate: start,
      customEndDate: end,
    );
  }
}

/// আর্থিক তারিখ ফিল্টার প্রোভাইডার
final financialDateFilterProvider = StateNotifierProvider<
    FinancialDateFilterNotifier, FinancialDateFilterState>(
  (ref) => FinancialDateFilterNotifier(),
);

/// নির্বাচিত সময়সীমার দোকানের সামগ্রিক আর্থিক হিসাব (Realized Net Income)
final financialOverviewProvider =
    FutureProvider<ShopFinancialOverview>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  final filter = ref.watch(financialDateFilterProvider);
  final range = filter.dateRange;

  return repo.getShopFinancialOverview(
    startDate: range.startMs,
    endDate: range.endMs,
  );
});

/// আজকের দিনের স্ন্যাপশট (Dashboard ও দ্রুত পর্যালোচনার জন্য)
final todayFinancialSnapshotProvider =
    FutureProvider<ShopFinancialOverview>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day, 0, 0, 0, 0)
      .millisecondsSinceEpoch;
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
      .millisecondsSinceEpoch;

  return repo.getShopFinancialOverview(startDate: start, endDate: end);
});

/// চলতি মাসের আর্থিক স্ন্যাপশট
final thisMonthFinancialSnapshotProvider =
    FutureProvider<ShopFinancialOverview>((ref) async {
  final repo = ref.watch(financeRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1, 0, 0, 0, 0).millisecondsSinceEpoch;
  final lastDay = DateTime(now.year, now.month + 1, 0).day;
  final end = DateTime(now.year, now.month, lastDay, 23, 59, 59, 999).millisecondsSinceEpoch;

  return repo.getShopFinancialOverview(startDate: start, endDate: end);
});

/// নির্দিষ্ট একক আবেদনের আর্থিক হিসাব (আদায়, কাজের খরচ, নিট লাভ, বকেয়া)
final applicationFinancialsProvider =
    FutureProvider.family<ApplicationFinancials, String>((ref, applicationId) {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.getApplicationFinancials(applicationId);
});

/// নির্দিষ্ট আবেদনের সক্রিয় পেমেন্ট হিস্টোরি
final applicationPaymentsProvider =
    StreamProvider.family<List<Payment>, String>((ref, applicationId) {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.watchPaymentsForApplication(applicationId);
});

/// নির্দিষ্ট আবেদনের সক্রিয় খরচের তালিকা
final applicationExpensesProvider =
    StreamProvider.family<List<Expense>, String>((ref, applicationId) {
  final repo = ref.watch(financeRepositoryProvider);
  return repo.watchExpensesForApplication(applicationId);
});

/// দোকানের সাধারণ খরচ স্ট্রিম
final generalExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  final filter = ref.watch(financialDateFilterProvider);
  final range = filter.dateRange;

  return repo.watchGeneralExpenses(
    startDate: range.startMs,
    endDate: range.endMs,
  );
});

/// স্বতন্ত্র আয় স্ট্রিম
final independentIncomesProvider =
    StreamProvider<List<IndependentIncome>>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  final filter = ref.watch(financialDateFilterProvider);
  final range = filter.dateRange;

  return repo.watchIndependentIncomes(
    startDate: range.startMs,
    endDate: range.endMs,
  );
});

// -------------------------------------------------------------
// লেনদেন ফিল্টার ও একীভূত ক্যাশবই (Unified Transactions)
// -------------------------------------------------------------

class TransactionsFilterState {
  final String searchQuery;
  final String type; // 'all', 'income', 'expense'
  final String source; // 'all', 'applicationPayment', etc.

  const TransactionsFilterState({
    this.searchQuery = '',
    this.type = 'all',
    this.source = 'all',
  });

  TransactionsFilterState copyWith({
    String? searchQuery,
    String? type,
    String? source,
  }) {
    return TransactionsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      type: type ?? this.type,
      source: source ?? this.source,
    );
  }
}

class TransactionsFilterNotifier
    extends StateNotifier<TransactionsFilterState> {
  TransactionsFilterNotifier() : super(const TransactionsFilterState());

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q.trim());
  }

  void setType(String type) {
    state = state.copyWith(type: type);
  }

  void setSource(String source) {
    state = state.copyWith(source: source);
  }

  void reset() {
    state = const TransactionsFilterState();
  }
}

final transactionsFilterProvider = StateNotifierProvider<
    TransactionsFilterNotifier, TransactionsFilterState>(
  (ref) => TransactionsFilterNotifier(),
);

/// সেন্ট্রালাইজড লেনদেন ভিউ স্ট্রিম (Unified Transactions Stream)
final unifiedTransactionsStreamProvider =
    StreamProvider<List<UnifiedTransactionsViewData>>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  final dateFilter = ref.watch(financialDateFilterProvider);
  final range = dateFilter.dateRange;

  return repo.watchUnifiedTransactions(
    startDate: range.startMs,
    endDate: range.endMs,
  );
});

/// ফিল্টার ও সার্চ সমন্বিত সেন্ট্রালাইজড লেনদেন তালিকা
final filteredTransactionsProvider =
    Provider<List<UnifiedTransactionsViewData>>((ref) {
  final asyncTx = ref.watch(unifiedTransactionsStreamProvider);
  final filter = ref.watch(transactionsFilterProvider);

  return asyncTx.when(
    data: (txs) {
      return txs.where((t) {
        if (filter.type != 'all' && t.type != filter.type) return false;
        if (filter.source != 'all' && t.source != filter.source) return false;

        if (filter.searchQuery.isNotEmpty) {
          final q = filter.searchQuery.toLowerCase();
          final catMatch = t.category.toLowerCase().contains(q);
          final appMatch =
              t.applicationTitle != null && t.applicationTitle!.toLowerCase().contains(q);
          final applicantMatch =
              t.applicantName != null && t.applicantName!.toLowerCase().contains(q);
          final customerMatch =
              t.customerName != null && t.customerName!.toLowerCase().contains(q);
          final noteMatch = t.note != null && t.note!.toLowerCase().contains(q);

          if (!catMatch &&
              !appMatch &&
              !applicantMatch &&
              !customerMatch &&
              !noteMatch) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    loading: () => const [],
    error: (_, __) => const [],
  );
});

// -------------------------------------------------------------
// অর্থ ও লেনদেন মিউটেশন কন্ট্রোলার (Finance Mutation Controller)
// -------------------------------------------------------------

class FinanceController extends MutationController {
  final FinanceRepository _repo;

  FinanceController(this._repo);

  /// কিস্তি বা ফি বাবদ টাকা জমা
  Future<Payment?> addPayment({
    String? id,
    required String applicationId,
    required int amountPaisa,
    DateTime? date,
    String method = 'নগদ',
    String? note,
    bool isStatusFee = false,
    String? statusHistoryId,
    String? statusName,
    bool allowOverpayment = true,
  }) {
    return execute(() => _repo.addPayment(
          id: id,
          applicationId: applicationId,
          amountPaisa: amountPaisa,
          date: date,
          method: method,
          note: note,
          isStatusFee: isStatusFee,
          statusHistoryId: statusHistoryId,
          statusName: statusName,
          allowOverpayment: allowOverpayment,
        ));
  }

  /// ফাইলের সরাসরি কাজের খরচ
  Future<Expense?> addApplicationExpense({
    String? id,
    required String applicationId,
    required int amountPaisa,
    required String category,
    DateTime? date,
    String? note,
    String? statusHistoryId,
    String? statusName,
    bool isStatusExpense = false,
  }) {
    return execute(() => _repo.addApplicationExpense(
          id: id,
          applicationId: applicationId,
          amountPaisa: amountPaisa,
          category: category,
          date: date,
          note: note,
          statusHistoryId: statusHistoryId,
          statusName: statusName,
          isStatusExpense: isStatusExpense,
        ));
  }

  /// দোকানের সাধারণ পরিচালন খরচ
  Future<Expense?> addGeneralExpense({
    String? id,
    required int amountPaisa,
    required String category,
    DateTime? date,
    String? note,
  }) {
    return execute(() => _repo.addGeneralExpense(
          id: id,
          amountPaisa: amountPaisa,
          category: category,
          date: date,
          note: note,
        ));
  }

  /// স্বতন্ত্র দোকান আয়
  Future<IndependentIncome?> addIndependentIncome({
    String? id,
    required String category,
    required int amountPaisa,
    DateTime? date,
    String paymentMethod = 'নগদ',
    String? customerName,
    String? note,
  }) {
    return execute(() => _repo.addIndependentIncome(
          id: id,
          category: category,
          amountPaisa: amountPaisa,
          date: date,
          paymentMethod: paymentMethod,
          customerName: customerName,
          note: note,
        ));
  }

  /// পেমেন্ট সফট ডিলিট
  Future<void> deletePayment(String id) {
    return execute(() => _repo.deletePayment(id));
  }

  /// পেমেন্ট পুনরুদ্ধার
  Future<void> restorePayment(String id) {
    return execute(() => _repo.restorePayment(id));
  }

  /// খরচ সফট ডিলিট
  Future<void> deleteExpense(String id) {
    return execute(() => _repo.deleteExpense(id));
  }

  /// খরচ পুনরুদ্ধার
  Future<void> restoreExpense(String id) {
    return execute(() => _repo.restoreExpense(id));
  }

  /// স্বতন্ত্র আয় সফট ডিলিট
  Future<void> deleteIndependentIncome(String id) {
    return execute(() => _repo.deleteIndependentIncome(id));
  }

  /// স্বতন্ত্র আয় পুনরুদ্ধার
  Future<void> restoreIndependentIncome(String id) {
    return execute(() => _repo.restoreIndependentIncome(id));
  }
}

/// অর্থ সংক্রান্ত মিউটেশন কন্ট্রোলার প্রোভাইডার
final financeControllerProvider =
    StateNotifierProvider<FinanceController, AsyncValue<void>>((ref) {
  final repo = ref.watch(financeRepositoryProvider);
  return FinanceController(repo);
});

