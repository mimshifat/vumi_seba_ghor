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
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/finance_providers.dart';

class IncomeFormScreen extends ConsumerStatefulWidget {
  const IncomeFormScreen({super.key});

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _customerController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedCategory;
  String _selectedMethod = 'নগদ';
  DateTime _incomeDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _customerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন আয়ের খাত যোগ করুন'),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'খাতের নাম', isRequired: true),
            hintText: 'যেমন: জমির নকশা স্ক্যানিং',
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
                    .createIncomeCategory(name: newCat);
                setState(() => _selectedCategory = newCat);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final raw =
        _amountController.text.replaceAll(',', '').replaceAll('৳', '').trim();
    final taka = int.tryParse(BengaliDigits.toEnglish(raw)) ?? 0;
    if (taka <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে আয়ের সঠিক পরিমাণ লিখুন'),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    final cat = _selectedCategory ?? 'অন্যান্য আয়';

    try {
      await ref.read(financeControllerProvider.notifier).addIndependentIncome(
            category: cat,
            amountPaisa: Money.fromTaka(taka).paisa,
            date: _incomeDate,
            paymentMethod: _selectedMethod,
            customerName: _customerController.text.trim().isNotEmpty
                ? _customerController.text.trim()
                : null,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '৳${BengaliDigits.toBengali(taka)} স্বাধীন আয় সফলভাবে যুক্ত হয়েছে!'),
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
    final liveCategoriesAsync = ref.watch(incomeCategoriesStreamProvider);
    final liveCats = liveCategoriesAsync.valueOrNull?.map((c) => c.name).toList();
    final categories = (liveCats != null && liveCats.isNotEmpty)
        ? liveCats
        : DemoStore.incomeCategories;

    if (_selectedCategory == null || !categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আয় যোগ করুন (স্বাধীন আয়)'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            // Notice banner explaining this is exclusively for independent income
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 20, color: AppColors.emerald),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'দোকানের স্বাধীন আয় (আবেদন ব্যতীত)',
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'দোকানের স্বাধীন বা অন্যান্য সার্ভিসের আয় এখানে লিখুন। আবেদন সংক্রান্ত পেমেন্ট সংশ্লিষ্ট আবেদন ফাইল থেকে যুক্ত হয়।',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF15803D),
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Amount & Details Card
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
                    label: 'আয়ের পরিমাণ (টাকা)',
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
                        label: 'আয়ের খাত / ধরন',
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
                        selectedColor: AppColors.emeraldSurface,
                        backgroundColor: AppColors.slate100,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.emerald
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                          fontFamily: AppTypography.fontFamily,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.emerald
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

                  // Payment Method Selector
                  const AppFieldLabel(
                    label: 'পেমেন্ট পদ্ধতি',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Row(
                    children: ['নগদ', 'বিকাশ', 'নগদ/অন্যান্য', 'ব্যাংক'].map((m) {
                      final isSelected = _selectedMethod == m;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setState(() => _selectedMethod = m),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.emeraldSurface
                                    : AppColors.slate100,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.emerald
                                      : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.emerald
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Income Date
                  const AppFieldLabel(
                    label: 'আয়ের তারিখ',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _incomeDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _incomeDate = picked);
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
                              size: 16, color: AppColors.emerald),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            BengaliDigits.toBengali(
                                '${_incomeDate.day}/${_incomeDate.month}/${_incomeDate.year}'),
                            style: AppTypography.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Customer Name (Optional)
                  AppTextField(
                    label: 'ব্যক্তি বা গ্রাহকের নাম',
                    hint: 'যেমন: রফিক উদ্দিন',
                    controller: _customerController,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Note (Optional)
                  AppTextField(
                    label: 'বিবরণ বা নোট',
                    hint: 'যেমন: ৪ পাতা বায়নানামা টাইপিং ও ফটোকপি',
                    controller: _noteController,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'আয় সংরক্ষণ করুন',
              icon: Icons.check_circle_outline,
              onPressed: _saveIncome,
            ),
          ],
        ),
      ),
    );
  }
}
