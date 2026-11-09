import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_dialog_action_row.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../providers/settings_providers.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Expense sub-filter: 0 = All, 1 = Application Expenses, 2 = Office Expenses
  int _expenseFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Work Types Actions ---
  void _showAddEditWorkTypeDialog({WorkType? existingType}) {
    final controller = TextEditingController(text: existingType?.name ?? '');
    final isEditing = existingType != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text(isEditing ? 'কাজের ধরন পরিবর্তন' : 'নতুন কাজের ধরন যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আবেদন নিবন্ধনের সময় এই কাজের ধরনটি নির্বাচন তালিকায় যুক্ত থাকবে।',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                label: AppFieldLabel.inline(label: 'কাজের নাম', isRequired: true),
                hintText: 'যেমন: বাটোয়ারা বা খাস জমি বন্দোবস্ত',
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          AppDialogActionRow(
            confirmText: isEditing ? 'সংরক্ষণ করুন' : 'যোগ করুন',
            onConfirm: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              try {
                if (isEditing) {
                  await ref
                      .read(categoryControllerProvider.notifier)
                      .updateWorkType(id: existingType.id, name: text);
                } else {
                  await ref
                      .read(categoryControllerProvider.notifier)
                      .createWorkType(name: text);
                }

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing
                        ? 'কাজের ধরন সফলভাবে হালনাগাদ হয়েছে'
                        : 'নতুন কাজের ধরন যুক্ত করা হয়েছে'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                final msg = e is AppFailure
                    ? e.message
                    : 'কাজের ধরন সংরক্ষণ করা যায়নি।';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteWorkType(WorkType type) async {
    final allAppsAsync = ref.read(applicationsWithFinancialsStreamProvider);
    final count = (allAppsAsync.valueOrNull ?? [])
        .where((a) => a.application.workType == type.name)
        .length;

    final message = count > 0
        ? 'এই ধরনের অধীনে ${BengaliDigits.toBengali(count.toString())} টি আবেদন সংরক্ষিত রয়েছে। আপনি কি নিশ্চিত যে এটি তালিকা থেকে মুছতে চান?'
        : 'আপনি কি নিশ্চিত যে "${type.name}" কাজের ধরনটি তালিকা থেকে মুছে ফেলতে চান?';

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'কাজের ধরন মুছবেন?',
      message: message,
      confirmText: 'হ্যাঁ, মুছুন',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        final wasDeleted = await ref
            .read(categoryControllerProvider.notifier)
            .deleteWorkType(type.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasDeleted == true
                ? 'কাজের ধরন তালিকা থেকে মুছে ফেলা হয়েছে'
                : 'কাজের ধরন নিষ্ক্রিয় করা হয়েছে'),
            backgroundColor: AppColors.rose,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        final msg = e is AppFailure ? e.message : 'কাজের ধরন মোছা যায়নি।';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
        );
      }
    }
  }

  // --- Expense Categories Actions ---
  void _showAddEditExpenseCategoryDialog({
    ExpenseCategory? existingCategory,
    bool isGeneral = false,
  }) {
    final controller =
        TextEditingController(text: existingCategory?.name ?? '');
    final isEditing = existingCategory != null;
    bool targetIsGeneral = existingCategory != null
        ? existingCategory.isGeneral == 1
        : isGeneral;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          title: Text(isEditing
              ? 'খরচের খাত পরিবর্তন'
              : 'নতুন খরচের খাত যোগ করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'দৈনিক খরচের হিসাব রাখার সময় এই খাত থেকে বাছাই করা যাবে।',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!isEditing) ...[
                  Text(
                    'খাতের শ্রেণি নির্বাচন করুন',
                    style: AppTypography.labelMedium
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('আবেদনের খরচ'),
                          selected: !targetIsGeneral,
                          onSelected: (val) {
                            setDialogState(() => targetIsGeneral = false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('দোকান খরচ'),
                          selected: targetIsGeneral,
                          onSelected: (val) {
                            setDialogState(() => targetIsGeneral = true);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    label:
                        AppFieldLabel.inline(label: 'খাতের নাম', isRequired: true),
                    hintText: 'যেমন: আপ্যায়ন বা কম্পিউটার কালি',
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          actions: [
            AppDialogActionRow(
              confirmText: isEditing ? 'সংরক্ষণ করুন' : 'যোগ করুন',
              onConfirm: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                try {
                  if (isEditing) {
                    await ref
                        .read(categoryControllerProvider.notifier)
                        .updateExpenseCategory(
                          id: existingCategory.id,
                          name: text,
                        );
                  } else {
                    await ref
                        .read(categoryControllerProvider.notifier)
                        .createExpenseCategory(
                          name: text,
                          isGeneral: targetIsGeneral,
                        );
                  }

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? 'খরচের খাত হালনাগাদ হয়েছে'
                          : 'নতুন খরচের খাত যুক্ত করা হয়েছে'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  final msg = e is AppFailure
                      ? e.message
                      : 'খরচের খাত সংরক্ষণ করা যায়নি।';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteExpenseCategory(ExpenseCategory cat) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'খরচের খাত মুছবেন?',
      message: 'আপনি কি নিশ্চিত যে "${cat.name}" খাতটি তালিকা থেকে মুছে ফেলতে চান?',
      confirmText: 'হ্যাঁ, মুছুন',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        final wasDeleted = await ref
            .read(categoryControllerProvider.notifier)
            .deleteExpenseCategory(cat.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasDeleted == true
                ? 'খরচের খাত মুছে ফেলা হয়েছে'
                : 'খরচের খাত নিষ্ক্রিয় করা হয়েছে'),
            backgroundColor: AppColors.rose,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        final msg = e is AppFailure ? e.message : 'খরচের খাত মোছা যায়নি।';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workTypesAsync = ref.watch(workTypesStreamProvider);
    final workTypes = workTypesAsync.valueOrNull ?? [];

    final expenseCategoriesAsync =
        ref.watch(expenseCategoriesStreamProvider(null));
    final expenseCategories = expenseCategoriesAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ক্যাটাগরি ও খাত ব্যবস্থাপনা'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelMedium
              .copyWith(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: [
            Tab(
              icon: const Icon(Icons.work_outline, size: 20),
              text: 'কাজের ধরন (${BengaliDigits.toBengali(workTypes.length.toString())})',
            ),
            Tab(
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              text: 'খরচের খাত (${BengaliDigits.toBengali(expenseCategories.length.toString())})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: _tabController.index == 0
                    ? 'কাজের ধরন খুঁজুন...'
                    : 'খরচের খাত খুঁজুন...',
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: AppColors.slate100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWorkTypesTab(workTypes),
                _buildExpenseCategoriesTab(expenseCategories),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'নতুন কাজের ধরন' : 'নতুন খরচের খাত',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEditWorkTypeDialog();
          } else {
            _showAddEditExpenseCategoryDialog(
              isGeneral: _expenseFilterIndex == 2,
            );
          }
        },
      ),
    );
  }

  Widget _buildWorkTypesTab(List<WorkType> workTypes) {
    final filtered = workTypes.where((wt) {
      if (_searchQuery.isEmpty) return true;
      return wt.name.toLowerCase().contains(_searchQuery);
    }).toList();

    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // Informative Header Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF4F46E5), size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'নতুন আবেদন গ্রহণ ও হিসাবের সুবিধার্থে ভূমিসেবার কাজের ধরনগুলো এখানে সাজিয়ে রাখুন।',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF3730A3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        if (filtered.isEmpty)
          EmptyState(
            icon: Icons.work_off_outlined,
            title: 'কোনো কাজের ধরন পাওয়া যায়নি',
            message: _searchQuery.isNotEmpty
                ? '"$_searchQuery" এর সাথে কোনো কাজের ধরন মেলেনি।'
                : 'তালিকায় কোনো কাজের ধরন নেই। নতুন ধরন যোগ করুন।',
            actionText: 'নতুন কাজের ধরন যোগ করুন',
            onAction: () => _showAddEditWorkTypeDialog(),
          )
        else
          ...filtered.asMap().entries.map((entry) {
            final idx = entry.key;
            final wt = entry.value;
            final count =
                allApps.where((a) => a.application.workType == wt.name).length;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base, vertical: 4),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      BengaliDigits.toBengali((idx + 1).toString()),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  wt.name,
                  style: AppTypography.headingSmall
                      .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  count > 0
                      ? '${BengaliDigits.toBengali(count.toString())} টি আবেদনে ব্যবহৃত'
                      : 'এখনও কোনো আবেদনে ব্যবহার হয়নি',
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        count > 0 ? AppColors.emeraldDark : AppColors.textMuted,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppColors.slate600),
                      tooltip: 'সম্পাদনা',
                      onPressed: () =>
                          _showAddEditWorkTypeDialog(existingType: wt),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.rose),
                      tooltip: 'মুছুন',
                      onPressed: () => _deleteWorkType(wt),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 80), // Fab spacing
      ],
    );
  }

  Widget _buildExpenseCategoriesTab(List<ExpenseCategory> categories) {
    final appCats = categories.where((c) => c.isGeneral == 0).toList();
    final genCats = categories.where((c) => c.isGeneral == 1).toList();

    final filteredAppCats = appCats.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery);
    }).toList();

    final filteredGenCats = genCats.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // Sub-filter tabs
        Row(
          children: [
            _buildFilterPill('সকল খাত', 0),
            const SizedBox(width: 8),
            _buildFilterPill(
                'আবেদনের খরচ (${BengaliDigits.toBengali(appCats.length.toString())})',
                1),
            const SizedBox(width: 8),
            _buildFilterPill(
                'দোকান খরচ (${BengaliDigits.toBengali(genCats.length.toString())})',
                2),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Section 1: Application Expenses
        if (_expenseFilterIndex == 0 || _expenseFilterIndex == 1) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'আবেদনের সাথে সম্পৃক্ত খরচ',
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${BengaliDigits.toBengali(filteredAppCats.length.toString())} টি খাত',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (filteredAppCats.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('এই বিভাগে কোনো খরচের খাত পাওয়া যায়নি',
                    style: AppTypography.bodySmall),
              ),
            )
          else
            ...filteredAppCats.map((cat) => _buildExpenseCard(cat)),
          const SizedBox(height: AppSpacing.md),
        ],

        // Section 2: General Shop Expenses
        if (_expenseFilterIndex == 0 || _expenseFilterIndex == 2) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'দোকানের সাধারণ পরিচালন খরচ',
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${BengaliDigits.toBengali(filteredGenCats.length.toString())} টি খাত',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (filteredGenCats.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text('এই বিভাগে কোনো খরচের খাত পাওয়া যায়নি',
                    style: AppTypography.bodySmall),
              ),
            )
          else
            ...filteredGenCats.map((cat) => _buildExpenseCard(cat)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFilterPill(String label, int index) {
    final isSelected = _expenseFilterIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _expenseFilterIndex = index),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11.5,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseCategory cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cat.isGeneral == 1
                ? AppColors.roseSurface
                : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            cat.isGeneral == 1 ? Icons.store_outlined : Icons.description_outlined,
            color: cat.isGeneral == 1 ? AppColors.rose : AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          cat.name,
          style: AppTypography.headingSmall
              .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          cat.isGeneral == 1 ? 'দোকানের সাধারণ ব্যয়' : 'আবেদন বা কাজের ফাইল ব্যয়',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary, fontSize: 11.5),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: AppColors.slate600),
              tooltip: 'সম্পাদনা',
              onPressed: () =>
                  _showAddEditExpenseCategoryDialog(existingCategory: cat),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.rose),
              tooltip: 'মুছুন',
              onPressed: () => _deleteExpenseCategory(cat),
            ),
          ],
        ),
      ),
    );
  }
}
