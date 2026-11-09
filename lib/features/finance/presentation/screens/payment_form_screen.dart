import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../providers/finance_providers.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  final String? defaultApplicationId;
  final String? defaultApplicantName;
  final Money? dueAmount;

  const PaymentFormScreen({
    super.key,
    this.defaultApplicationId,
    this.defaultApplicantName,
    this.dueAmount,
  });

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedAppId;
  String _selectedMethod = 'নগদ';
  DateTime _paymentDate = DateTime.now();
  bool _markRemainingAsPaid = false;

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

  Future<void> _savePayment(DemoApplication? currentApp) async {
    if (!_formKey.currentState!.validate()) return;

    final taka = int.tryParse(BengaliDigits.toEnglish(
            _amountController.text.replaceAll(',', ''))) ??
        0;
    if (taka <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('অনুগ্রহ করে সঠিক টাকার পরিমাণ লিখুন'),
            backgroundColor: AppColors.rose),
      );
      return;
    }

    if (_selectedAppId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('অনুগ্রহ করে সংশ্লিষ্ট আবেদন নির্বাচন করুন'),
            backgroundColor: AppColors.rose),
      );
      return;
    }

    final paymentMoney = Money.fromTaka(taka);

    // বকেয়ার চেয়ে বেশি টাকা দিলে মানবিক কনফার্মেশন ডায়ালগ (BACKEND_MASTER_PLAN §2.1)
    if (currentApp != null && paymentMoney > currentApp.dueAmount) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'অতিরিক্ত টাকা জমা',
        message:
            'গ্রাহকের বকেয়ার চেয়ে জমার পরিমাণ বেশি হয়ে যাচ্ছে। আপনি কি নিশ্চিত এই টাকা জমা নিতে চান?',
        confirmText: 'হ্যাঁ, জমা নিন',
        icon: Icons.help_outline_rounded,
      );
      if (confirmed != true) return;
    }

    try {
      await ref.read(financeControllerProvider.notifier).addPayment(
            applicationId: _selectedAppId!,
            amountPaisa: paymentMoney.paisa,
            date: _paymentDate,
            method: _selectedMethod,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
            allowOverpayment: true,
          );

      if (_markRemainingAsPaid) {
        await ref
            .read(applicationControllerProvider.notifier)
            .markAsPaid(_selectedAppId!, true);
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
              '৳${BengaliDigits.toBengali(taka)} টাকা জমা সফলভাবে সংরক্ষিত হয়েছে!'),
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

    final matchedItem =
        allApps.where((a) => a.application.id == _selectedAppId).firstOrNull;
    final app = matchedItem?.toDemoApplication();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('টাকা জমা নিন'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            // Application selection & dues summary
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
                  Text(
                    'সংশ্লিষ্ট আবেদন নির্বাচন করুন',
                    style: AppTypography.titleMedium
                        .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
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
                          if (val != null) setState(() => _selectedAppId = val);
                        },
                      ),
                    ),
                  ),
                  if (app != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAppFinanceBrief('মোট চুক্তি',
                            app.agreedAmount.formatBengali(), AppColors.textPrimary),
                        _buildAppFinanceBrief('ইতোমধ্যে জমা',
                            app.receivedAmount.formatBengali(), AppColors.emerald),
                        _buildAppFinanceBrief('বর্তমান বকেয়া',
                            app.dueAmount.formatBengali(), AppColors.rose),
                      ],
                    ),
                    if (app.dueAmount.isPositive) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.flash_on, size: 14),
                          label: const Text('সম্পূর্ণ বকেয়া জমা দিন'),
                          onPressed: () {
                            _amountController.text =
                                app.dueAmount.inTaka.toString();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.base),

            // Payment Amount & Method
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
                    label: 'জমার পরিমাণ (টাকা)',
                    hint: '০',
                    controller: _amountController,
                    isRequired: true,
                    showQuickChips: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Payment Method Selector
                  const AppFieldLabel(
                    label: 'জমার মাধ্যম',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Row(
                    children: ['নগদ', 'বিকাশ', 'ব্যাংক', 'অন্যান্য'].map((m) {
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
                                  fontSize: 12.5,
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

                  // Date
                  const AppFieldLabel(
                    label: 'জমার তারিখ',
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _paymentDate = picked);
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
                                '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
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
                    label: 'মন্তব্য বা মানি রিসিট নম্বর',
                    hint: 'যেমন: রিসিট নং ৪৪, দ্বিতীয় কিস্তি ইত্যাদি',
                    controller: _noteController,
                  ),
                ],
              ),
            ),

            if (app != null && app.dueAmount.isPositive) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: CheckboxListTile(
                  value: _markRemainingAsPaid,
                  activeColor: AppColors.emerald,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'বাকি টাকা মওকুফ করে সম্পূর্ণ পরিশোধিত চিহ্নিত করুন',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'ক্লায়েন্ট আর অবশিষ্ট টাকা না দিলে টিক দিন, ফাইলে কোনো বকেয়া থাকবে না',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) =>
                      setState(() => _markRemainingAsPaid = val ?? false),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'জমা নিশ্চিত করুন',
              icon: Icons.check_circle_outline,
              onPressed: () => _savePayment(app),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppFinanceBrief(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.bodySmall
                .copyWith(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.moneySmall
                .copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
