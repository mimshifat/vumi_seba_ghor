import 'package:flutter/material.dart';
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

class ExpenseFormScreen extends StatefulWidget {
  final String? defaultApplicationId;
  final String? defaultApplicationTitle;

  const ExpenseFormScreen({
    super.key,
    this.defaultApplicationId,
    this.defaultApplicationTitle,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isGeneralExpense = false;
  String? _selectedAppId;
  late String _selectedCategory;
  DateTime _expenseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedAppId = widget.defaultApplicationId ??
        (DemoStore.applications.isNotEmpty ? DemoStore.applications.first.id : null);
    _selectedCategory = DemoStore.applicationExpenseCategories.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories => _isGeneralExpense
      ? DemoStore.generalExpenseCategories
      : DemoStore.applicationExpenseCategories;

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isGeneralExpense ? 'নতুন সাধারণ খরচের খাত' : 'নতুন কাজের খরচের খাত'),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'খাতের নাম', isRequired: true),
            hintText: 'যেমন: কম্পিউটার মেরামত বা আপ্যায়ন',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          AppDialogActionRow(
            confirmText: 'যোগ করুন',
            onConfirm: () {
              final newCat = catController.text.trim();
              if (newCat.isNotEmpty) {
                setState(() {
                  if (_isGeneralExpense) {
                    if (!DemoStore.generalExpenseCategories.contains(newCat)) {
                      DemoStore.generalExpenseCategories.add(newCat);
                    }
                  } else {
                    if (!DemoStore.applicationExpenseCategories.contains(newCat)) {
                      DemoStore.applicationExpenseCategories.add(newCat);
                    }
                  }
                  if (!DemoStore.expenseCategories.contains(newCat)) {
                    DemoStore.expenseCategories.add(newCat);
                  }
                  _selectedCategory = newCat;
                });
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    final raw = _amountController.text.replaceAll(',', '').replaceAll('৳', '').trim();
    final taka = int.tryParse(BengaliDigits.toEnglish(raw)) ?? 0;
    if (taka <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে খরচের সঠিক পরিমাণ লিখুন'), backgroundColor: AppColors.rose),
      );
      return;
    }

    if (!_isGeneralExpense && _selectedAppId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে সংশ্লিষ্ট আবেদনটি নির্বাচন করুন'), backgroundColor: AppColors.rose),
      );
      return;
    }

    String? appTitle;
    if (!_isGeneralExpense && _selectedAppId != null) {
      try {
        final a = DemoStore.applications.firstWhere((app) => app.id == _selectedAppId);
        appTitle = '${a.workType} - ${a.applicantName}';
      } catch (_) {}
    }

    final newExpense = DemoExpense(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      applicationId: _isGeneralExpense ? null : _selectedAppId,
      applicationTitle: _isGeneralExpense ? null : appTitle,
      amount: Money.fromTaka(taka),
      category: _selectedCategory,
      date: _expenseDate,
      isGeneral: _isGeneralExpense,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    if (_isGeneralExpense) {
      DemoStore.generalExpenses.insert(0, newExpense);
    } else if (_selectedAppId != null) {
      final idx = DemoStore.applications.indexWhere((a) => a.id == _selectedAppId);
      if (idx != -1) {
        final app = DemoStore.applications[idx];
        final updatedExpenses = List<DemoExpense>.from(app.expenses)..insert(0, newExpense);
        DemoStore.applications[idx] = DemoApplication(
          id: app.id,
          applicantId: app.applicantId,
          applicantName: app.applicantName,
          applicantPhone: app.applicantPhone,
          referencePersonId: app.referencePersonId,
          referencePersonName: app.referencePersonName,
          mouza: app.mouza,
          appNumber: app.appNumber,
          caseNumber: app.caseNumber,
          workType: app.workType,
          officeName: app.officeName,
          applicationDate: app.applicationDate,
          status: app.status,
          agreedAmount: app.agreedAmount,
          receivedAmount: app.receivedAmount,
          expenseAmount: app.expenseAmount + Money.fromTaka(taka),
          notes: app.notes,
          payments: app.payments,
          expenses: updatedExpenses,
          statusHistory: app.statusHistory,
          documents: app.documents,
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('৳${BengaliDigits.toBengali(taka)} খরচ সফলভাবে এন্ট্রি হয়েছে।'),
        backgroundColor: AppColors.emerald,
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
            // Expense Scope Toggle (কাজের খরচ vs সাধারণ খরচ)
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
                        _selectedCategory = DemoStore.applicationExpenseCategories.first;
                      }),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !_isGeneralExpense ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
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
                            color: !_isGeneralExpense ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: !_isGeneralExpense ? FontWeight.w700 : FontWeight.w500,
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
                        _selectedCategory = DemoStore.generalExpenseCategories.first;
                      }),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isGeneralExpense ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
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
                            color: _isGeneralExpense ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: _isGeneralExpense ? FontWeight.w700 : FontWeight.w500,
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
                      label: 'কোন আবেদনের জন্য খরচ?',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAppId,
                          isExpanded: true,
                          items: DemoStore.applications.map((a) {
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text(
                                '${a.applicantName} (${a.workType} - ${a.officeName})',
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAppId = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
            ],

            // Expense Details Card
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

                  // Category Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppFieldLabel(
                        label: 'খরচের খাত / ক্যাটাগরি',
                        isRequired: true,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('নতুন খাত', style: TextStyle(fontSize: 12)),
                        onPressed: _showAddCategoryDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 30),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentCategories.map((cat) {
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
                          color: isSelected ? AppColors.rose : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                          fontFamily: AppTypography.fontFamily,
                        ),
                        side: BorderSide(color: isSelected ? AppColors.rose : AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Date
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
                      if (picked != null) setState(() => _expenseDate = picked);
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.rose),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            BengaliDigits.toBengali('${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}'),
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Note
                  AppTextField(
                    label: 'বিবরণ বা ভাউচার নোট',
                    hint: _isGeneralExpense
                        ? 'যেমন: নভেম্বর মাসের দোকান ভাড়া বা বিদ্যুৎ বিল রশিদ'
                        : 'যেমন: সরকারি চালানের কপি বা দলিলের ফটোকপি খরচ',
                    controller: _noteController,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'খরচ সংরক্ষণ করুন',
              variant: ButtonVariant.danger,
              icon: Icons.check,
              onPressed: _saveExpense,
            ),
          ],
        ),
      ),
    );
  }
}
