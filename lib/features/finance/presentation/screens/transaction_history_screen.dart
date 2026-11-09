import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../providers/finance_providers.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String? initialApplicationId;

  const TransactionHistoryScreen({super.key, this.initialApplicationId});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  // Filter States
  String _typeFilter = 'all'; // 'all', 'income', 'expense'
  String _dateFilter = 'all'; // 'all', 'today', 'month', 'year', 'custom'
  DateTimeRange? _customDateRange;
  String? _selectedCategory;
  String? _selectedApplicationId;

  @override
  void initState() {
    super.initState();
    if (widget.initialApplicationId != null) {
      _selectedApplicationId = widget.initialApplicationId;
    }
  }

  void _resetFilters() {
    setState(() {
      _typeFilter = 'all';
      _dateFilter = 'all';
      _customDateRange = null;
      _selectedCategory = null;
      _selectedApplicationId = null;
    });
  }

  bool get _hasActiveFilters =>
      _typeFilter != 'all' ||
      _dateFilter != 'all' ||
      _selectedCategory != null ||
      _selectedApplicationId != null;

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
    final liveTx = ref.watch(unifiedTransactionsStreamProvider).valueOrNull;
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
    final now = DateTime.now();

    return _getAllTransactions().where((tx) {
      // 1. Type Filter
      if (_typeFilter == 'income' && !tx.isIncome) return false;
      if (_typeFilter == 'expense' && !tx.isExpense) return false;

      // 2. Date Filter
      if (_dateFilter == 'today') {
        if (tx.date.year != now.year ||
            tx.date.month != now.month ||
            tx.date.day != now.day) {
          return false;
        }
      } else if (_dateFilter == 'month') {
        if (tx.date.year != now.year || tx.date.month != now.month) {
          return false;
        }
      } else if (_dateFilter == 'year') {
        if (tx.date.year != now.year) {
          return false;
        }
      } else if (_dateFilter == 'custom' && _customDateRange != null) {
        final start = DateTime(_customDateRange!.start.year,
            _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year,
            _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        if (tx.date.isBefore(start) || tx.date.isAfter(end)) {
          return false;
        }
      }

      // 3. Category Filter
      if (_selectedCategory != null && tx.category != _selectedCategory) {
        return false;
      }

      // 4. Application Filter
      if (_selectedApplicationId != null &&
          tx.applicationId != _selectedApplicationId) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTransactions();

    Money filteredTotalIncome = Money.zero;
    Money filteredTotalExpense = Money.zero;
    for (final tx in filtered) {
      if (tx.isIncome) filteredTotalIncome += tx.amount;
      if (tx.isExpense) filteredTotalExpense += tx.amount;
    }
    final filteredNet = filteredTotalIncome - filteredTotalExpense;

    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('লেনদেন খাতা (ক্যাশবই)'),
        actions: [
          if (_hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'ফিল্টার রিসেট',
              onPressed: _resetFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Type Filter
                  _buildFilterPill(
                    label: 'সব লেনদেন',
                    isSelected: _typeFilter == 'all',
                    onTap: () => setState(() => _typeFilter = 'all'),
                  ),
                  _buildFilterPill(
                    label: 'শুধু আয়',
                    isSelected: _typeFilter == 'income',
                    color: AppColors.emerald,
                    onTap: () => setState(() => _typeFilter = 'income'),
                  ),
                  _buildFilterPill(
                    label: 'শুধু খরচ',
                    isSelected: _typeFilter == 'expense',
                    color: AppColors.rose,
                    onTap: () => setState(() => _typeFilter = 'expense'),
                  ),

                  const SizedBox(width: AppSpacing.sm),
                  Container(width: 1, height: 20, color: AppColors.slate200),
                  const SizedBox(width: AppSpacing.sm),

                  // Date Filter
                  _buildFilterPill(
                    label: 'আজ',
                    isSelected: _dateFilter == 'today',
                    onTap: () => setState(() => _dateFilter = 'today'),
                  ),
                  _buildFilterPill(
                    label: 'চলতি মাস',
                    isSelected: _dateFilter == 'month',
                    onTap: () => setState(() => _dateFilter = 'month'),
                  ),
                  _buildFilterPill(
                    label: 'চলতি বছর',
                    isSelected: _dateFilter == 'year',
                    onTap: () => setState(() => _dateFilter = 'year'),
                  ),
                  _buildFilterPill(
                    label: _customDateRange != null ? 'কাস্টম রেঞ্জ' : 'তারিখ রেঞ্জ...',
                    isSelected: _dateFilter == 'custom',
                    icon: Icons.calendar_today,
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDateRange: _customDateRange,
                      );
                      if (picked != null) {
                        setState(() {
                          _customDateRange = picked;
                          _dateFilter = 'custom';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Total Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBadge(
                  'মোট আয়',
                  filteredTotalIncome.formatBengali(),
                  AppColors.emerald,
                ),
                _buildSummaryBadge(
                  'মোট খরচ',
                  filteredTotalExpense.formatBengali(),
                  AppColors.rose,
                ),
                _buildSummaryBadge(
                  'নিট হিসাব',
                  filteredNet.formatBengali(),
                  filteredNet.isPositive ? AppColors.emerald : AppColors.rose,
                  isBold: true,
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'কোনো লেনদেন পাওয়া যায়নি',
                    message:
                        'নির্বাচিত ফিল্টারের সাথে কোনো আয় বা খরচের রেকর্ড মেলেনি।',
                    actionText: _hasActiveFilters ? 'ফিল্টার রিসেট করুন' : null,
                    onAction: _hasActiveFilters ? _resetFilters : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, idx) {
                      final tx = filtered[idx];
                      return _buildTransactionCard(tx, allApps);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
      DemoTransaction tx, List<dynamic> allApps) {
    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.emerald : AppColors.rose;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.category,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.sourceDisplayName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${tx.amount.formatBengali()}',
                    style: AppTypography.moneyMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    BengaliDigits.toBengali(
                        '${tx.date.day}/${tx.date.month}/${tx.date.year}'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.slate400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (tx.applicantName != null ||
              tx.customerName != null ||
              tx.note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (tx.applicantName != null || tx.customerName != null)
                  Expanded(
                    child: Text(
                      'গ্রাহক: ${tx.applicantName ?? tx.customerName}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.slate700,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (tx.paymentMethod != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Text(
                      tx.paymentMethod!,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.slate600),
                    ),
                  ),
              ],
            ),
          ],
          if (tx.note != null && tx.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'নোট: ${tx.note!}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.slate500,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final activeColor = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : AppColors.slate100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 13,
                    color: isSelected ? activeColor : AppColors.textSecondary),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : AppColors.textPrimary,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(String title, String amount, Color color,
      {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall
              .copyWith(fontSize: 10.5, color: AppColors.textMuted),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
      ],
    );
  }
}
