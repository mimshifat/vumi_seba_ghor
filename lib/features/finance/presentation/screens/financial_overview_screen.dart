import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/summary_card.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../applications/presentation/screens/application_detail_screen.dart';
import '../providers/finance_providers.dart';
import 'due_management_screen.dart';
import 'expense_form_screen.dart';
import 'income_form_screen.dart';
import 'payment_form_screen.dart';
import 'transaction_history_screen.dart';

enum FinancialFilterType {
  thisMonth,
  lastMonth,
  thisYear,
  allTime,
  customMonth,
  customRange,
}

class FinancialOverviewScreen extends ConsumerStatefulWidget {
  const FinancialOverviewScreen({super.key});

  @override
  ConsumerState<FinancialOverviewScreen> createState() =>
      _FinancialOverviewScreenState();
}

class _FinancialOverviewScreenState
    extends ConsumerState<FinancialOverviewScreen> {
  static const List<String> _bengaliMonths = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  FinancialFilterType _filterType = FinancialFilterType.thisMonth;
  late int _selectedYear;
  late int _selectedMonth;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  void _selectThisMonth() {
    final now = DateTime.now();
    setState(() {
      _filterType = FinancialFilterType.thisMonth;
      _selectedYear = now.year;
      _selectedMonth = now.month;
      _customDateRange = null;
    });
  }

  void _selectLastMonth() {
    final now = DateTime.now();
    setState(() {
      _filterType = FinancialFilterType.lastMonth;
      if (now.month == 1) {
        _selectedMonth = 12;
        _selectedYear = now.year - 1;
      } else {
        _selectedMonth = now.month - 1;
        _selectedYear = now.year;
      }
      _customDateRange = null;
    });
  }

  void _selectThisYear() {
    final now = DateTime.now();
    setState(() {
      _filterType = FinancialFilterType.thisYear;
      _selectedYear = now.year;
      _customDateRange = null;
    });
  }

  void _selectAllTime() {
    setState(() {
      _filterType = FinancialFilterType.allTime;
      _customDateRange = null;
    });
  }

  void _goToPreviousPeriod() {
    setState(() {
      if (_filterType == FinancialFilterType.thisYear) {
        _selectedYear--;
      } else {
        _filterType = FinancialFilterType.customMonth;
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear--;
        } else {
          _selectedMonth--;
        }
      }
    });
  }

  void _goToNextPeriod() {
    final now = DateTime.now();
    setState(() {
      if (_filterType == FinancialFilterType.thisYear) {
        _selectedYear++;
      } else {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear++;
        } else {
          _selectedMonth++;
        }
        if (_selectedYear == now.year && _selectedMonth == now.month) {
          _filterType = FinancialFilterType.thisMonth;
        } else {
          _filterType = FinancialFilterType.customMonth;
        }
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      helpText: 'আর্থিক বিবরণীর সময়কাল নির্ধারণ করুন',
      cancelText: 'বাতিল',
      confirmText: 'বাছাই করুন',
    );

    if (picked != null) {
      setState(() {
        _filterType = FinancialFilterType.customRange;
        _customDateRange = picked;
      });
    }
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        int tempYear = _selectedYear;
        int tempMonth = _selectedMonth;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'মাস ও বছর নির্বাচন করুন',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Year Switcher Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                            onPressed: () {
                              setModalState(() => tempYear--);
                            },
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '${BengaliDigits.toBengali(tempYear)} সাল',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                            onPressed: () {
                              setModalState(() => tempYear++);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Month Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (ctx, index) {
                        final monthIndex = index + 1;
                        final isSelected = (monthIndex == tempMonth);
                        return InkWell(
                          onTap: () {
                            setModalState(() => tempMonth = monthIndex);
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              _bengaliMonths[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _selectThisMonth();
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                            ),
                            child: const Text('চলতি মাস'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                final now = DateTime.now();
                                _selectedYear = tempYear;
                                _selectedMonth = tempMonth;
                                if (_selectedYear == now.year && _selectedMonth == now.month) {
                                  _filterType = FinancialFilterType.thisMonth;
                                } else {
                                  _filterType = FinancialFilterType.customMonth;
                                }
                                _customDateRange = null;
                              });
                            },
                            child: const Text('প্রয়োগ করুন'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  TransactionSource _parseSource(String source) {
    switch (source) {
      case 'applicationPayment':
        return TransactionSource.applicationPayment;
      case 'applicationExpense':
        return TransactionSource.applicationExpense;
      case 'independentIncome':
        return TransactionSource.independentIncome;
      case 'generalExpense':
        return TransactionSource.generalExpense;
      case 'statusFee':
        return TransactionSource.statusIncome;
      case 'statusExpense':
        return TransactionSource.statusExpense;
      default:
        return TransactionSource.generalExpense;
    }
  }

  List<DemoTransaction> _getAllTransactions() {
    final liveTx = ref.watch(allUnifiedTransactionsStreamProvider).valueOrNull;
    if (liveTx != null) {
      return liveTx.map((tx) {
        return DemoTransaction(
          id: tx.id ?? '',
          type: tx.type == 'income'
              ? TransactionType.income
              : TransactionType.expense,
          source: _parseSource(tx.source),
          amount: Money.fromPaisa(tx.amount),
          date: DateTime.fromMillisecondsSinceEpoch(tx.date),
          category: tx.category,
          applicationId: tx.applicationId,
          applicantName: tx.applicantName,
          customerName: tx.customerName,
          paymentMethod: tx.paymentMethod,
          statusHistoryId: tx.statusHistoryId,
          statusName: tx.statusName,
          note: tx.note,
        );
      }).toList();
    }
    return const [];
  }

  List<DemoTransaction> _getFilteredTransactions() {
    final all = _getAllTransactions();
    switch (_filterType) {
      case FinancialFilterType.thisMonth:
      case FinancialFilterType.lastMonth:
      case FinancialFilterType.customMonth:
        return all.where((t) => t.date.year == _selectedYear && t.date.month == _selectedMonth).toList();
      case FinancialFilterType.thisYear:
        return all.where((t) => t.date.year == _selectedYear).toList();
      case FinancialFilterType.allTime:
        return all;
      case FinancialFilterType.customRange:
        if (_customDateRange == null) return all;
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        return all.where((t) => !t.date.isBefore(start) && !t.date.isAfter(end)).toList();
    }
  }

  Money get _filteredIncome {
    Money sum = Money.zero;
    for (final t in _getFilteredTransactions()) {
      if (t.isIncome) sum += t.amount;
    }
    return sum;
  }

  Money get _filteredExpense {
    Money sum = Money.zero;
    for (final t in _getFilteredTransactions()) {
      if (t.isExpense) sum += t.amount;
    }
    return sum;
  }

  Money get _filteredNetIncome => _filteredIncome - _filteredExpense;

  String get _periodTitle {
    switch (_filterType) {
      case FinancialFilterType.thisMonth:
        return '${_bengaliMonths[_selectedMonth - 1]} ${BengaliDigits.toBengali(_selectedYear)} (চলতি মাস)';
      case FinancialFilterType.lastMonth:
        return '${_bengaliMonths[_selectedMonth - 1]} ${BengaliDigits.toBengali(_selectedYear)} (বিগত মাস)';
      case FinancialFilterType.customMonth:
        return '${_bengaliMonths[_selectedMonth - 1]} ${BengaliDigits.toBengali(_selectedYear)}';
      case FinancialFilterType.thisYear:
        return '${BengaliDigits.toBengali(_selectedYear)} সাল';
      case FinancialFilterType.allTime:
        return 'সর্বমোট (সকল সময়)';
      case FinancialFilterType.customRange:
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          final e = _customDateRange!.end;
          return '${BengaliDigits.toBengali(s.day)}/${BengaliDigits.toBengali(s.month)} - ${BengaliDigits.toBengali(e.day)}/${BengaliDigits.toBengali(e.month)}/${BengaliDigits.toBengali(e.year)}';
        }
        return 'কাস্টম সময়কাল';
    }
  }

  String get _periodBadgeText {
    switch (_filterType) {
      case FinancialFilterType.thisMonth:
      case FinancialFilterType.lastMonth:
      case FinancialFilterType.customMonth:
        return '${_bengaliMonths[_selectedMonth - 1]} ${BengaliDigits.toBengali(_selectedYear)}';
      case FinancialFilterType.thisYear:
        return '${BengaliDigits.toBengali(_selectedYear)} সাল';
      case FinancialFilterType.allTime:
        return 'সব সময়';
      case FinancialFilterType.customRange:
        if (_customDateRange != null) {
          return '${BengaliDigits.toBengali(_customDateRange!.start.day)}/${BengaliDigits.toBengali(_customDateRange!.start.month)} - ${BengaliDigits.toBengali(_customDateRange!.end.day)}/${BengaliDigits.toBengali(_customDateRange!.end.month)}';
        }
        return 'কাস্টম';
    }
  }

  bool get _isCurrentMonthSelected {
    final now = DateTime.now();
    return (_filterType == FinancialFilterType.thisMonth) ||
        ((_filterType == FinancialFilterType.customMonth) && _selectedYear == now.year && _selectedMonth == now.month);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(allUnifiedTransactionsStreamProvider);
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];
    final dueApps = allApps
        .where((a) => a.effectiveDue.isPositive)
        .map((a) => a.toDemoApplication())
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('হিসাব ও আর্থিক বিবরণী'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_late_outlined, color: AppColors.amberDark),
            tooltip: 'বকেয়া খাতা',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const DueManagementScreen()),
              ).then((_) {
                ref.invalidate(allUnifiedTransactionsStreamProvider);
                ref.invalidate(applicationsWithFinancialsStreamProvider);
                if (mounted) setState(() {});
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'সকল লেনদেন',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const TransactionHistoryScreen()),
              ).then((_) {
                ref.invalidate(allUnifiedTransactionsStreamProvider);
                ref.invalidate(applicationsWithFinancialsStreamProvider);
                if (mounted) setState(() {});
              });
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFloatingButton(
              label: 'আয়',
              icon: Icons.add_circle,
              backgroundColor: AppColors.emerald,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const IncomeFormScreen()),
                ).then((_) {
                  ref.invalidate(allUnifiedTransactionsStreamProvider);
                  ref.invalidate(applicationsWithFinancialsStreamProvider);
                  ref.invalidate(financialOverviewProvider);
                  ref.invalidate(todayFinancialSnapshotProvider);
                  ref.invalidate(thisMonthFinancialSnapshotProvider);
                  if (mounted) setState(() {});
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            AppFloatingButton(
              label: 'খরচ',
              icon: Icons.remove_circle,
              backgroundColor: AppColors.rose,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const ExpenseFormScreen()),
                ).then((_) {
                  ref.invalidate(allUnifiedTransactionsStreamProvider);
                  ref.invalidate(applicationsWithFinancialsStreamProvider);
                  ref.invalidate(financialOverviewProvider);
                  ref.invalidate(todayFinancialSnapshotProvider);
                  ref.invalidate(thisMonthFinancialSnapshotProvider);
                  if (mounted) setState(() {});
                });
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, 96),
        children: [
          // 1. FILTER CONTROLLER & NAVIGATION STRIP
          _buildFilterSection(),

          const SizedBox(height: AppSpacing.base),

          // 2. HERO SUMMARY CARD (DYNAMIC TO FILTER)
          _buildHeroSummaryCard(),

          // 3. DAILY SUMMARY (Shows when viewing current month)
          if (_isCurrentMonthSelected) ...[
            const SizedBox(height: AppSpacing.base),
            _buildTodaySummary(),
          ],

          const SizedBox(height: AppSpacing.base),

          // 4. INCOME VS EXPENSE COMPARISON CHART
          _buildComparisonChart(),

          const SizedBox(height: AppSpacing.base),

          // 5. OUTSTANDING DUES SECTION
          _buildOutstandingDuesSection(dueApps),
        ],
      ),
    );
  }

  /// 1. Modern Filter Selector Bar & Period Navigator
  Widget _buildFilterSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quick Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('চলতি মাস', _filterType == FinancialFilterType.thisMonth, _selectThisMonth),
                const SizedBox(width: 6),
                _buildFilterChip('বিগত মাস', _filterType == FinancialFilterType.lastMonth, _selectLastMonth),
                const SizedBox(width: 6),
                _buildFilterChip('চলতি বছর', _filterType == FinancialFilterType.thisYear, _selectThisYear),
                const SizedBox(width: 6),
                _buildFilterChip('সব সময়', _filterType == FinancialFilterType.allTime, _selectAllTime),
                const SizedBox(width: 6),
                _buildFilterActionChip(
                  label: 'মাস/বছর বাছাই',
                  icon: Icons.calendar_month,
                  isActive: _filterType == FinancialFilterType.customMonth,
                  onTap: _showMonthYearPicker,
                ),
                const SizedBox(width: 6),
                _buildFilterActionChip(
                  label: 'কাস্টম তারিখ',
                  icon: Icons.date_range,
                  isActive: _filterType == FinancialFilterType.customRange,
                  onTap: _pickCustomDateRange,
                ),
              ],
            ),
          ),

          // Period Navigator Banner (for Month or Year mode)
          if (_filterType != FinancialFilterType.allTime && _filterType != FinancialFilterType.customRange)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                color: Color(0xFFF8FAFC),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 15, color: AppColors.textSecondary),
                    onPressed: _goToPreviousPeriod,
                    tooltip: 'পূর্ববর্তী',
                    visualDensity: VisualDensity.compact,
                  ),
                  InkWell(
                    onTap: _filterType == FinancialFilterType.thisYear ? null : _showMonthYearPicker,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            _periodTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          if (_filterType != FinancialFilterType.thisYear) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
                          ],
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.textSecondary),
                    onPressed: _goToNextPeriod,
                    tooltip: 'পরবর্তী',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            )
          else if (_filterType == FinancialFilterType.customRange && _customDateRange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                color: Color(0xFFF8FAFC),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _periodTitle,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _pickCustomDateRange,
                    icon: const Icon(Icons.edit, size: 13),
                    label: const Text('পরিবর্তন', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterActionChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isActive ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Redesigned Dynamic Hero Summary Card
  Widget _buildHeroSummaryCard() {
    final netIncome = _filteredNetIncome;
    final totalIncome = _filteredIncome;
    final totalExpense = _filteredExpense;
    final allApps = ref.watch(applicationsWithFinancialsStreamProvider).valueOrNull ?? [];
    int totalDuePaisa = 0;
    for (final a in allApps) {
      totalDuePaisa += a.effectiveDue.paisa;
    }
    final totalDue = Money.fromPaisa(totalDuePaisa);
    final filteredTxs = _getFilteredTransactions();

    final isPositiveIncome = !netIncome.isNegative;
    // মার্জিন শতকরা হিসাব — পয়সা (integer) থেকে, কোনো ভাসমান
    // মাধ্যমিক ছাড়াই (BACKEND_MASTER_PLAN.md)।
    final marginPercent = totalIncome.paisa > 0
        ? ((netIncome.paisa * 100) ~/ totalIncome.paisa).clamp(-100, 100)
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositiveIncome
              ? const [Color(0xFF1E1B4B), Color(0xFF2E2A72), Color(0xFF4338CA)]
              : const [Color(0xFF4C0519), Color(0xFF881337), Color(0xFF9F1239)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: (isPositiveIncome ? AppColors.primary : AppColors.rose).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isPositiveIncome ? 'প্রকৃত নিট ইনকাম' : 'ঘাটতি / ঋণাত্মক ব্যালেন্স',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPositiveIncome
                          ? AppColors.emerald.withValues(alpha: 0.3)
                          : AppColors.rose.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      isPositiveIncome ? 'ইতিবাচক' : 'ঘাটতি',
                      style: TextStyle(
                        color: isPositiveIncome ? AppColors.emeraldLight : Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range, size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _periodBadgeText,
                      style: AppTypography.labelMedium.copyWith(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                netIncome.formatBengali(),
                style: AppTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (marginPercent > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '(আয়ের হার: ${BengaliDigits.toBengali(marginPercent)}%)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 4 Metric Items Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroMetric('মোট আদায়', totalIncome.formatBengali(), Colors.white),
                Container(height: 24, width: 1, color: Colors.white24),
                _buildHeroMetric('মোট খরচ', totalExpense.formatBengali(), AppColors.roseLight),
                Container(height: 24, width: 1, color: Colors.white24),
                _buildHeroMetric('মোট বকেয়া', totalDue.formatBengali(), AppColors.amberLight),
                Container(height: 24, width: 1, color: Colors.white24),
                _buildHeroMetric(
                  'মোট লেনদেন',
                  '${BengaliDigits.toBengali(filteredTxs.length)} টি',
                  Colors.white.withValues(alpha: 0.95),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 10.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  /// 3. Daily Summary Cards (Shows today's snapshot when viewing current month)
  Widget _buildTodaySummary() {
    final now = DateTime.now();
    int todayIncomePaisa = 0;
    int todayExpensePaisa = 0;
    for (final t in _getAllTransactions()) {
      if (t.date.year == now.year && t.date.month == now.month && t.date.day == now.day) {
        if (t.type == TransactionType.income) {
          todayIncomePaisa += t.amount.paisa;
        } else {
          todayExpensePaisa += t.amount.paisa;
        }
      }
    }
    final todayIncome = Money.fromPaisa(todayIncomePaisa);
    final todayExpense = Money.fromPaisa(todayExpensePaisa);

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'আজকের আয়',
            value: todayIncome.formatBengali(),
            icon: Icons.south_west,
            accentColor: AppColors.emerald,
            subtitle: 'আজকে প্রাপ্ত মোট নগদ ও অনলাইন জমা',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const TransactionHistoryScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SummaryCard(
            title: 'আজকের খরচ',
            value: todayExpense.formatBengali(),
            icon: Icons.north_east,
            accentColor: AppColors.rose,
            subtitle: 'আজকে ব্যয়িত সরকারি ও সাধারণ খরচ',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const TransactionHistoryScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 4. Dynamic Income vs Expense Comparison Chart
  Widget _buildComparisonChart() {
    final filteredTxs = _getFilteredTransactions();
    final chartGroups = _computeChartGroups(filteredTxs);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'আয় বনাম ব্যয়ের তুলনা',
                style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  _buildLegend(AppColors.emerald, 'আয়'),
                  const SizedBox(width: 10),
                  _buildLegend(AppColors.rose, 'ব্যয়'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_periodTitle অনুযায়ী গ্রাফিকাল চিত্র',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),

          if (filteredTxs.isEmpty)
            Container(
              height: 150,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 36, color: AppColors.textMuted),
                  SizedBox(height: 6),
                  Text('এই নির্বাচিত সময়ে কোনো লেনদেন পাওয়া যায়নি', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            )
          else
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _computeChartMaxY(chartGroups),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1E293B),
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final isIncome = rodIndex == 0;
                        final type = isIncome ? 'আয়' : 'ব্যয়';
                        return BarTooltipItem(
                          '$type: ৳${BengaliDigits.toBengali(rod.toY.toInt())}',
                          TextStyle(
                            color: isIncome ? AppColors.emeraldLight : AppColors.roseLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          return _getChartLabel(val.toInt());
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: chartGroups,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _getChartLabel(int index) {
    if (_filterType == FinancialFilterType.thisYear) {
      // 12 months
      if (index >= 0 && index < 12) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _bengaliMonths[index].substring(0, math.min(4, _bengaliMonths[index].length)),
            style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
          ),
        );
      }
    } else if (_filterType == FinancialFilterType.allTime) {
      const labels = ['২০২৪', '২০২৫', '২০২৬'];
      if (index >= 0 && index < labels.length) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(labels[index], style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        );
      }
    } else {
      // Month-based view (5 weeks)
      const labels = ['সপ্তাহ ১', 'সপ্তাহ ২', 'সপ্তাহ ৩', 'সপ্তাহ ৪', 'সপ্তাহ ৫'];
      if (index >= 0 && index < labels.length) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(labels[index], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        );
      }
    }
    return const SizedBox();
  }

  List<BarChartGroupData> _computeChartGroups(List<DemoTransaction> txs) {
    if (_filterType == FinancialFilterType.thisYear) {
      // 12 months
      final groups = <BarChartGroupData>[];
      for (int m = 1; m <= 12; m++) {
        // পয়সা (integer) হিসেবে জমা হয় — ভাসমান মাধ্যমিক নেই (BACKEND_MASTER_PLAN.md)।
        int inc = 0;
        int exp = 0;
        for (final t in txs) {
          if (t.date.month == m) {
            if (t.isIncome) inc += t.amount.paisa;
            if (t.isExpense) exp += t.amount.paisa;
          }
        }
        groups.add(_makeGroup(m - 1, inc, exp, rodWidth: 7));
      }
      return groups;
    } else if (_filterType == FinancialFilterType.allTime) {
      // 3 Years: 2024, 2025, 2026
      final years = [2024, 2025, 2026];
      final groups = <BarChartGroupData>[];
      for (int i = 0; i < years.length; i++) {
        final yr = years[i];
        int inc = 0;
        int exp = 0;
        for (final t in txs) {
          if (t.date.year == yr) {
            if (t.isIncome) inc += t.amount.paisa;
            if (t.isExpense) exp += t.amount.paisa;
          }
        }
        groups.add(_makeGroup(i, inc, exp, rodWidth: 16));
      }
      return groups;
    } else {
      // 5 Weeks in the selected month
      final groups = <BarChartGroupData>[];
      for (int w = 0; w < 5; w++) {
        final startDay = w * 7 + 1;
        final endDay = (w + 1) * 7;
        int inc = 0;
        int exp = 0;
        for (final t in txs) {
          if (t.date.day >= startDay && t.date.day <= endDay) {
            if (t.isIncome) inc += t.amount.paisa;
            if (t.isExpense) exp += t.amount.paisa;
          }
        }
        groups.add(_makeGroup(w, inc, exp, rodWidth: 12));
      }
      return groups;
    }
  }

  double _computeChartMaxY(List<BarChartGroupData> groups) {
    double maxVal = 5000;
    for (final g in groups) {
      for (final r in g.barRods) {
        if (r.toY > maxVal) maxVal = r.toY;
      }
    }
    return maxVal * 1.25;
  }

  /// চার্টের একটি দণ্ড তৈরি করে।
  ///
  /// [income] ও [expense] পয়সা (integer) হিসেবে আসে — সব আর্থিক
  /// হিসাব পূর্ণসংখ্যায় থাকে (BACKEND_MASTER_PLAN.md)। fl_chart-এর `toY` ফিল্ড
  /// `double` চাই বলে শুধু প্রদর্শনের সময় টাকায় রূপান্তর হয়।
  BarChartGroupData _makeGroup(int x, int income, int expense, {double rodWidth = 12}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: income / 100.0,
          color: AppColors.emerald,
          width: rodWidth,
          borderRadius: BorderRadius.circular(3),
        ),
        BarChartRodData(
          toY: expense / 100.0,
          color: AppColors.rose,
          width: rodWidth,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }

  /// 5. Outstanding Dues Section (বকেয়া তালিকা)
  Widget _buildOutstandingDuesSection(List<DemoApplication> dueApps) {
    final allApps = ref.watch(applicationsWithFinancialsStreamProvider).valueOrNull ?? [];
    int totalDuePaisa = 0;
    for (final a in allApps) {
      totalDuePaisa += a.effectiveDue.paisa;
    }
    final totalDue = Money.fromPaisa(totalDuePaisa);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.amberSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.assignment_late_outlined, color: AppColors.amberDark, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'বকেয়া তালিকা (${BengaliDigits.toBengali(dueApps.length)} জন গ্রাহক)',
                    style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Text(
                totalDue.formatBengali(),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.rose,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (dueApps.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              alignment: Alignment.center,
              child: const Text('কোনো গ্রাহকের বকেয়া নেই। সকল হিসাব পরিশোধিত!'),
            )
          else ...[
            ...dueApps.take(3).map((app) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ApplicationDetailScreen(application: app),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          app.applicantName.isNotEmpty ? app.applicantName[0] : 'গ',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.applicantName,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${app.workType} • ${app.officeName}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'চুক্তি: ${app.agreedAmount.formatBengali()} | জমা: ${app.receivedAmount.formatBengali()}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 10.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'বাকি: ${app.dueAmount.formatBengali()}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.rose,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => PaymentFormScreen(
                                    defaultApplicationId: app.id,
                                    defaultApplicantName: app.applicantName,
                                    dueAmount: app.dueAmount,
                                  ),
                                ),
                              ).then((_) => setState(() {}));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                              child: const Text(
                                'জমা নিন',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const DueManagementScreen()),
                ).then((_) => setState(() {}));
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text('সকল বকেয়া তালিকা ও তাগাদা দেখুন'),
            ),
          ],
        ],
      ),
    );
  }
}
