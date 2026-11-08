import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/money_field.dart';

class PaymentFormScreen extends StatefulWidget {
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
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
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
    _selectedAppId = widget.defaultApplicationId ??
        (DemoStore.applications.isNotEmpty ? DemoStore.applications.first.id : null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  DemoApplication? get _currentApp {
    if (_selectedAppId == null) return null;
    try {
      return DemoStore.applications.firstWhere((a) => a.id == _selectedAppId);
    } catch (_) {
      return null;
    }
  }

  void _savePayment() {
    if (!_formKey.currentState!.validate()) return;

    final taka = int.tryParse(BengaliDigits.toEnglish(_amountController.text.replaceAll(',', ''))) ?? 0;
    if (taka <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে সঠিক টাকার পরিমাণ লিখুন'), backgroundColor: AppColors.rose),
      );
      return;
    }

    final newPayment = DemoPayment(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      applicationId: _selectedAppId ?? 'general',
      amount: Money.fromTaka(taka),
      date: _paymentDate,
      method: _selectedMethod,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    // If linked to an application, update application received amount
    if (_currentApp != null) {
      final app = _currentApp!;
      final newTotalReceived = app.receivedAmount + Money.fromTaka(taka);
      final isFullyPaidByCash = newTotalReceived >= app.agreedAmount;
      final shouldMarkPaid = _markRemainingAsPaid || isFullyPaidByCash;

      final updatedPayments = List<DemoPayment>.from(app.payments)..insert(0, newPayment);
      final updatedApp = app.copyWith(
        receivedAmount: newTotalReceived,
        payments: updatedPayments,
        isMarkedAsPaid: shouldMarkPaid,
        notes: _markRemainingAsPaid && !isFullyPaidByCash
            ? (app.notes != null && app.notes!.isNotEmpty
                ? '${app.notes}\n• অবশিষ্ট বকেয়া মওকুফ করে সম্পূর্ণ পরিশোধিত চিহ্নিত'
                : '• অবশিষ্ট বকেয়া মওকুফ করে সম্পূর্ণ পরিশোধিত চিহ্নিত')
            : app.notes,
      );

      final idx = DemoStore.applications.indexWhere((a) => a.id == app.id);
      if (idx != -1) DemoStore.applications[idx] = updatedApp;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('৳${BengaliDigits.toBengali(taka)} টাকা জমা সফলভাবে সংরক্ষিত হয়েছে!'),
        backgroundColor: AppColors.emerald,
      ),
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final app = _currentApp;

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
                    style: AppTypography.titleMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
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
                              '${a.applicantName} (${a.workType})',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
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
                        _buildAppFinanceBrief('মোট চুক্তি', app.agreedAmount.formatBengali(), AppColors.textPrimary),
                        _buildAppFinanceBrief('ইতোমধ্যে জমা', app.receivedAmount.formatBengali(), AppColors.emerald),
                        _buildAppFinanceBrief('বর্তমান বকেয়া', app.dueAmount.formatBengali(), AppColors.rose),
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
                            _amountController.text = app.dueAmount.inTaka.toString();
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
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.emeraldSurface : AppColors.slate100,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isSelected ? AppColors.emerald : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  color: isSelected ? AppColors.emeraldDark : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 12.5,
                                  fontFamily: AppTypography.fontFamily,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Payment Date
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.emerald),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            BengaliDigits.toBengali('${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
                            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
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

            if (_currentApp != null && _currentApp!.rawDueAmount.isPositive) ...[
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
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'ক্লায়েন্ট আর অবশিষ্ট টাকা না দিলে টিক দিন, ফাইলে কোনো বকেয়া থাকবে না',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  onChanged: (val) => setState(() => _markRemainingAsPaid = val ?? false),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'জমা নিশ্চিত করুন',
              icon: Icons.check_circle_outline,
              onPressed: _savePayment,
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
        Text(title, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.moneySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

