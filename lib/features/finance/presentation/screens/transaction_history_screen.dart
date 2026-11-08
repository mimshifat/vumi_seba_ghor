import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/screens/application_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String? initialApplicationId;

  const TransactionHistoryScreen({super.key, this.initialApplicationId});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
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

  List<DemoTransaction> get _filteredTransactions {
    final now = DateTime.now();

    return DemoStore.getAllTransactions().where((tx) {
      // 1. Type Filter
      if (_typeFilter == 'income' && !tx.isIncome) return false;
      if (_typeFilter == 'expense' && !tx.isExpense) return false;

      // 2. Date Filter
      if (_dateFilter == 'today') {
        if (tx.date.year != now.year || tx.date.month != now.month || tx.date.day != now.day) {
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
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        if (tx.date.isBefore(start) || tx.date.isAfter(end)) {
          return false;
        }
      }

      // 3. Category Filter
      if (_selectedCategory != null && tx.category != _selectedCategory) {
        return false;
      }

      // 4. Application Filter
      if (_selectedApplicationId != null && tx.applicationId != _selectedApplicationId) {
        return false;
      }

      return true;
    }).toList();
  }

  Money get _filteredTotalIncome {
    Money sum = Money.zero;
    for (final tx in _filteredTransactions) {
      if (tx.isIncome) sum += tx.amount;
    }
    return sum;
  }

  Money get _filteredTotalExpense {
    Money sum = Money.zero;
    for (final tx in _filteredTransactions) {
      if (tx.isExpense) sum += tx.amount;
    }
    return sum;
  }

  Money get _filteredBalance => _filteredTotalIncome - _filteredTotalExpense;

  List<String> get _availableCategories {
    final cats = <String>{};
    for (final tx in DemoStore.getAllTransactions()) {
      cats.add(tx.category);
    }
    return cats.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('লেনদেনের ইতিহাস'),
        actions: [
          if (_hasActiveFilters)
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.rose),
              label: const Text('রিসেট', style: TextStyle(color: AppColors.rose)),
              onPressed: _resetFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Controls Card
          _buildFilterBar(),

          // Summary Strip
          _buildSummaryStrip(),

          const Divider(height: 1),

          // Active filter tags (if any)
          if (_hasActiveFilters) _buildActiveFilterTags(),

          // Transactions List
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'কোনো লেনদেন পাওয়া যায়নি',
                      message: _hasActiveFilters
                          ? 'বর্তমান ফিল্টারের সাথে মিলে এমন কোনো লেনদেন নেই।'
                          : 'কোনো আর্থিক লেনদেন এন্ট্রি করা হয়নি।',
                      actionText: _hasActiveFilters ? 'ফিল্টার রিসেট করুন' : null,
                      onAction: _hasActiveFilters ? _resetFilters : null,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    itemCount: transactions.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      final tx = transactions[i];
                      return _buildTransactionCard(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Compact Filter Bar
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Filter Tabs
          Row(
            children: [
              _buildTypeChip('all', 'সব লেনদেন (${BengaliDigits.toBengali(DemoStore.getAllTransactions().length)})'),
              const SizedBox(width: 6),
              _buildTypeChip('income', 'শুধু আয়'),
              const SizedBox(width: 6),
              _buildTypeChip('expense', 'শুধু খরচ'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Secondary Filter Dropdowns / Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date Range Dropdown
                _buildDateFilterMenu(),
                const SizedBox(width: 8),

                // Category Filter Menu
                _buildCategoryFilterMenu(),
                const SizedBox(width: 8),

                // Application Filter Menu
                _buildApplicationFilterMenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String key, String label) {
    final isSelected = _typeFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _typeFilter = key),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.slate100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterMenu() {
    String dateLabel = 'সব সময়';
    if (_dateFilter == 'today') dateLabel = 'আজ';
    if (_dateFilter == 'month') dateLabel = 'চলতি মাস';
    if (_dateFilter == 'year') dateLabel = 'চলতি বছর';
    if (_dateFilter == 'custom' && _customDateRange != null) {
      dateLabel =
          '${BengaliDigits.toBengali('${_customDateRange!.start.day}/${_customDateRange!.start.month}')} - ${BengaliDigits.toBengali('${_customDateRange!.end.day}/${_customDateRange!.end.month}')}';
    }

    return PopupMenuButton<String>(
      onSelected: (val) async {
        if (val == 'custom') {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
            initialDateRange: _customDateRange ??
                DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now(),
                ),
          );
          if (range != null) {
            setState(() {
              _dateFilter = 'custom';
              _customDateRange = range;
            });
          }
        } else {
          setState(() {
            _dateFilter = val;
            _customDateRange = null;
          });
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'all', child: Text('সব সময়')),
        const PopupMenuItem(value: 'today', child: Text('আজ')),
        const PopupMenuItem(value: 'month', child: Text('চলতি মাস')),
        const PopupMenuItem(value: 'year', child: Text('চলতি বছর')),
        const PopupMenuItem(value: 'custom', child: Text('কাস্টম তারিখ রেঞ্জ...')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _dateFilter != 'all' ? AppColors.primarySurface : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: _dateFilter != 'all' ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: _dateFilter != 'all' ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              'তারিখ: $dateLabel',
              style: TextStyle(
                fontSize: 11.5,
                color: _dateFilter != 'all' ? AppColors.primary : AppColors.textSecondary,
                fontWeight: _dateFilter != 'all' ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterMenu() {
    return PopupMenuButton<String?>(
      onSelected: (val) => setState(() => _selectedCategory = val),
      itemBuilder: (ctx) => [
        const PopupMenuItem<String?>(value: null, child: Text('সকল খাত / ক্যাটাগরি')),
        const PopupMenuDivider(),
        ..._availableCategories.map(
          (c) => PopupMenuItem<String?>(value: c, child: Text(c)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedCategory != null ? AppColors.primarySurface : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: _selectedCategory != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 13,
              color: _selectedCategory != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              _selectedCategory != null ? 'খাত: $_selectedCategory' : 'সকল খাত',
              style: TextStyle(
                fontSize: 11.5,
                color: _selectedCategory != null ? AppColors.primary : AppColors.textSecondary,
                fontWeight: _selectedCategory != null ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationFilterMenu() {
    final apps = DemoStore.applications;
    String appLabel = 'সকল আবেদন';
    if (_selectedApplicationId != null) {
      try {
        final a = apps.firstWhere((app) => app.id == _selectedApplicationId);
        appLabel = a.applicantName;
      } catch (_) {}
    }

    return PopupMenuButton<String?>(
      onSelected: (val) => setState(() => _selectedApplicationId = val),
      itemBuilder: (ctx) => [
        const PopupMenuItem<String?>(value: null, child: Text('সকল আবেদন')),
        const PopupMenuDivider(),
        ...apps.map(
          (a) => PopupMenuItem<String?>(
            value: a.id,
            child: Text('${a.applicantName} (${a.workType})'),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _selectedApplicationId != null ? AppColors.primarySurface : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: _selectedApplicationId != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 13,
              color: _selectedApplicationId != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              _selectedApplicationId != null ? 'আবেদন: $appLabel' : 'আবেদন ফিল্টার',
              style: TextStyle(
                fontSize: 11.5,
                color: _selectedApplicationId != null ? AppColors.primary : AppColors.textSecondary,
                fontWeight: _selectedApplicationId != null ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  /// Active Filter Tags bar with clear buttons
  Widget _buildActiveFilterTags() {
    return Container(
      color: AppColors.slate50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('সক্রিয় ফিল্টার: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (_typeFilter != 'all')
              _buildActiveTag(
                _typeFilter == 'income' ? 'শুধু আয়' : 'শুধু খরচ',
                () => setState(() => _typeFilter = 'all'),
              ),
            if (_dateFilter != 'all')
              _buildActiveTag(
                _dateFilter == 'today'
                    ? 'আজ'
                    : (_dateFilter == 'month' ? 'চলতি মাস' : (_dateFilter == 'year' ? 'চলতি বছর' : 'কাস্টম তারিখ')),
                () => setState(() {
                  _dateFilter = 'all';
                  _customDateRange = null;
                }),
              ),
            if (_selectedCategory != null)
              _buildActiveTag(_selectedCategory!, () => setState(() => _selectedCategory = null)),
            if (_selectedApplicationId != null)
              _buildActiveTag('আবেদন ফিল্টার', () => setState(() => _selectedApplicationId = null)),
            TextButton(
              onPressed: _resetFilters,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: const Text('সব মুছুন', style: TextStyle(fontSize: 11, color: AppColors.rose)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTag(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          InkWell(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Summary strip at top of list
  Widget _buildSummaryStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm + 2),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('মোট আদায় / আয়', _filteredTotalIncome.formatBengali(), AppColors.emerald),
          Container(height: 24, width: 1, color: AppColors.border),
          _buildSummaryItem('মোট খরচ', _filteredTotalExpense.formatBengali(), AppColors.rose),
          Container(height: 24, width: 1, color: AppColors.border),
          _buildSummaryItem(
            'নিট ব্যালেন্স',
            _filteredBalance.formatBengali(),
            _filteredBalance.isNegative ? AppColors.rose : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.moneyMedium.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 13.5)),
      ],
    );
  }

  /// Individual Transaction Card
  Widget _buildTransactionCard(DemoTransaction tx) {
    final isIncome = tx.isIncome;

    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isIncome ? AppColors.emeraldSurface : AppColors.roseSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? AppColors.emerald : AppColors.rose,
            size: 18,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isIncome ? AppColors.emeraldSurface : AppColors.roseSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                isIncome ? 'আয়' : 'খরচ',
                style: TextStyle(
                  color: isIncome ? AppColors.emeraldDark : AppColors.rose,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: Text(
                tx.category,
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              '${BengaliDigits.toBengali('${tx.date.day}/${tx.date.month}/${tx.date.year}')} • ${tx.sourceDisplayName}'
              '${tx.paymentMethod != null ? ' (${tx.paymentMethod})' : ''}'
              '${tx.customerName != null ? ' • গ্রাহক: ${tx.customerName}' : ''}',
              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (tx.note != null && tx.note!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                tx.note!,
                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (tx.applicationTitle != null) ...[
              const SizedBox(height: 3),
              InkWell(
                onTap: () {
                  try {
                    final app = DemoStore.applications.firstWhere((a) => a.id == tx.applicationId);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => ApplicationDetailScreen(application: app)),
                    ).then((_) => setState(() {}));
                  } catch (_) {}
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, size: 11, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        'আবেদন: ${tx.applicationTitle!}',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${tx.amount.formatBengali()}',
          style: AppTypography.titleMedium.copyWith(
            color: isIncome ? AppColors.emerald : AppColors.rose,
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }
}
