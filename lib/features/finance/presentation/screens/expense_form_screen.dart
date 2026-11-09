import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog_action_row.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/finance_providers.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? defaultApplicationId;
  final String? defaultApplicationTitle;

  const ExpenseFormScreen({
    super.key,
    this.defaultApplicationId,
    this.defaultApplicationTitle,
  });

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isGeneralExpense = false;
  String? _selectedAppId;
  String? _selectedCategory;
  DateTime _expenseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedAppId = widget.defaultApplicationId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isGeneralExpense
            ? 'নতুন সাধারণ খরচের খাত'
            : 'নতুন কাজের খরচের খাত'),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'খাতের নাম', isRequired: true),
            hintText: 'যেমন: কম্পিউটার মেরামত বা আপ্যায়ন',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          AppDialogActionRow(
            confirmText: 'যোগ করুন',
            onConfirm: () async {
              final newCat = catController.text.trim();
              if (newCat.isNotEmpty) {
                await ref
                    .read(categoryControllerProvider.notifier)
                    .createExpenseCategory(
                      name: newCat,
                      isGeneral: _isGeneralExpense,
                    );
                setState(() {
                  _selectedCategory = newCat;
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final raw =
        _amountController.text.replaceAll(',', '').replaceAll('৳', '').trim();
    final taka = int.tryParse(BengaliDigits.toEnglish(raw)) ?? 0;
    if (taka <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('অনুগ্রহ করে খরচের সঠিক পরিমাণ লিখুন'),
            backgroundColor: AppColors.rose),
      );
      return;
    }

    if (!_isGeneralExpense && _selectedAppId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('অনুগ্রহ করে সংশ্লিষ্ট আবেদনটি নির্বাচন করুন'),
            backgroundColor: AppColors.rose),
      );
      return;
    }

    final categoryToSave = _selectedCategory ??
        (_isGeneralExpense ? 'দোকান ভাড়া' : 'সরকারি ফি');

    try {
      if (_isGeneralExpense) {
        await ref.read(financeControllerProvider.notifier).addGeneralExpense(
              amountPaisa: Money.fromTaka(taka).paisa,
              category: categoryToSave,
              date: _expenseDate,
              note: _noteController.text.trim().isNotEmpty
                  ? _noteController.text.trim()
                  : null,
            );
      } else {
        await ref
            .read(financeControllerProvider.notifier)
            .addApplicationExpense(
              applicationId: _selectedAppId!,
              amountPaisa: Money.fromTaka(taka).paisa,
              category: categoryToSave,
              date: _expenseDate,
              note: _noteController.text.trim().isNotEmpty
                  ? _noteController.text.trim()
                  : null,
            );
      }

      if (!mounted) return;

      ref.invalidate(allUnifiedTransactionsStreamProvider);
      ref.invalidate(applicationsWithFinancialsStreamProvider);
      ref.invalidate(financialOverviewProvider);
      ref.invalidate(todayFinancialSnapshotProvider);
      ref.invalidate(thisMonthFinancialSnapshotProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '৳${BengaliDigits.toBengali(taka)} খরচ সফলভাবে সংরক্ষিত হয়েছে!'),
          backgroundColor: AppColors.emerald,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];

    if (_selectedAppId == null && allApps.isNotEmpty) {
      _selectedAppId = allApps.first.application.id;
    }

    final liveCategoriesAsync =
        ref.watch(expenseCategoriesStreamProvider(_isGeneralExpense));
    final liveCatList = liveCategoriesAsync.valueOrNull?.map((c) => c.name).toList();
    final categories = (liveCatList != null && liveCatList.isNotEmpty)
        ? liveCatList
        : (_isGeneralExpense
            ? DemoStore.generalExpenseCategories
            : DemoStore.applicationExpenseCategories);

    if (_selectedCategory == null || !categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('খরচ যোগ করুন'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            // Segmented Control: Work Expense vs General Expense
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _isGeneralExpense = false;
                        _selectedCategory = null;
                      }),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd - 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !_isGeneralExpense
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd - 2),
                          boxShadow: !_isGeneralExpense
                              ? [
                                  const BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          'নির্দিষ্ট কাজের খরচ',
                          style: TextStyle(
                            color: !_isGeneralExpense
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: !_isGeneralExpense
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _isGeneralExpense = true;
                        _selectedCategory = null;
                      }),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd - 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isGeneralExpense
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd - 2),
                          boxShadow: _isGeneralExpense
                              ? [
                                  const BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          'দোকানের সাধারণ খরচ',
                          style: TextStyle(
                            color: _isGeneralExpense
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: _isGeneralExpense
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Target Application if application-specific
            if (!_isGeneralExpense) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel(
                      label: 'সংশ্লিষ্ট আবেদন নির্বাচন',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAppId,
                          isExpanded: true,
                          items: allApps.map((item) {
                            final a = item.application;
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.applicantName} (${a.workType})',
                                style: AppTypography.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAppId = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
            ],

            // Amount & Category Container
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoneyField(
                    label: 'খরচের পরিমাণ (টাকা)',
                    hint: '০',
                    controller: _amountController,
                    isRequired: true,
                    showQuickChips: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Category Selector with + Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppFieldLabel(
                        label: 'খরচের খাত / ক্যাটাগরি',
                        isRequired: true,
                      ),
                      InkWell(
                        onTap: _showAddCategoryDialog,
                        child: Text(
                          '+ নতুন খাত',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedCategory = cat);
                        },
                        selectedColor: AppColors.roseSurface,
                        backgroundColor: AppColors.slate100,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.rose
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                          fontFamily: AppTypography.fontFamily,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.rose
                              : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Expense Date
                  const AppFieldLabel(
                    label: 'খরচের তারিখ',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expenseDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _expenseDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 16, color: AppColors.rose),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            BengaliDigits.toBengali(
                                '${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}'),
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Note
                  AppTextField(
                    label: 'বিবরণ বা ভাউচার নোট',
                    hint: 'যেমন: খতিয়ান ড্রাফটিং ফি, সার্ভেয়ার বকশিশ ইত্যাদি',
                    controller: _noteController,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'খরচ সংরক্ষণ করুন',
              icon: Icons.check_circle_outline,
              onPressed: _saveExpense,
            ),
          ],
        ),
      ),
    );
  }
}
