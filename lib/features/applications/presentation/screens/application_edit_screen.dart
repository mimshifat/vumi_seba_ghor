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
import '../../../../core/widgets/money_field.dart';
import '../../../references/presentation/widgets/reference_selector_sheet.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/application_providers.dart';

class ApplicationEditScreen extends ConsumerStatefulWidget {
  final DemoApplication application;

  const ApplicationEditScreen({super.key, required this.application});

  @override
  ConsumerState<ApplicationEditScreen> createState() =>
      _ApplicationEditScreenState();
}

class _ApplicationEditScreenState extends ConsumerState<ApplicationEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  DemoReference? _selectedReference;
  late final TextEditingController _mouzaController;
  late final TextEditingController _appNumberController;
  late final TextEditingController _caseNumberController;
  late final TextEditingController _agreedAmountController;
  late final TextEditingController _notesController;

  late String _selectedWorkType;

  @override
  void initState() {
    super.initState();
    final app = widget.application;
    _nameController = TextEditingController(text: app.applicantName);
    _phoneController = TextEditingController(text: app.applicantPhone);
    _addressController = TextEditingController(text: app.applicantAddress ?? '');
    if (app.referencePersonId != null) {
      _selectedReference = DemoStore.references.cast<DemoReference?>().firstWhere(
            (r) => r?.id == app.referencePersonId,
            orElse: () => null,
          );
    }
    if (_selectedReference == null && app.referencePersonName != null && app.referencePersonName!.isNotEmpty) {
      _selectedReference = DemoStore.references.cast<DemoReference?>().firstWhere(
            (r) => r?.name == app.referencePersonName,
            orElse: () => null,
          );
    }
    _mouzaController = TextEditingController(text: app.mouza ?? '');
    _appNumberController = TextEditingController(text: app.appNumber ?? '');
    _caseNumberController = TextEditingController(text: app.caseNumber ?? '');
    _agreedAmountController = TextEditingController(text: app.agreedAmount.inTaka.toString());
    _notesController = TextEditingController(text: app.notes ?? '');
    _selectedWorkType = app.workType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _mouzaController.dispose();
    _appNumberController.dispose();
    _caseNumberController.dispose();
    _agreedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final agreedTaka = int.tryParse(BengaliDigits.toEnglish(
            _agreedAmountController.text.replaceAll(',', ''))) ??
        widget.application.agreedAmount.inTaka;
    final agreedPaisa = Money.fromTaka(agreedTaka).paisa;

    try {
      await ref.read(applicationControllerProvider.notifier).updateApplication(
            id: widget.application.id,
            mouza: _mouzaController.text.trim().isNotEmpty
                ? _mouzaController.text.trim()
                : null,
            appNumber: _appNumberController.text.trim().isNotEmpty
                ? _appNumberController.text.trim()
                : null,
            caseNumber: _caseNumberController.text.trim().isNotEmpty
                ? _caseNumberController.text.trim()
                : null,
            agreedAmountPaisa: agreedPaisa,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আবেদনের তথ্য সফলভাবে হালনাগাদ করা হয়েছে।'),
          backgroundColor: AppColors.emerald,
        ),
      );

      Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আবেদন তথ্য সম্পাদনা'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            _buildEditCard(
              title: 'আবেদনকারীর তথ্য',
              children: [
                AppTextField(
                  label: 'আবেদনকারীর নাম',
                  controller: _nameController,
                  isRequired: true,
                  validator: (v) => v == null || v.trim().isEmpty ? 'নাম আবশ্যক' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'মোবাইল নম্বর',
                  controller: _phoneController,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'মোবাইল নম্বর আবশ্যক' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'ঠিকানা (ঐচ্ছিক)',
                  hint: 'গ্রাম, ডাকঘর, উপজেলা, জেলা...',
                  controller: _addressController,
                  isRequired: false,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.home_outlined, size: 18, color: AppColors.slate400),
                ),
                const SizedBox(height: AppSpacing.md),
                // Reference Person Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel(
                      label: 'রেফারেন্স ব্যক্তি',
                      isRequired: false,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    InkWell(
                      onTap: () async {
                        final selected = await ReferenceSelectorSheet.show(
                          context,
                          initialReference: _selectedReference,
                        );
                        setState(() => _selectedReference = selected);
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: _selectedReference != null ? AppColors.primary : AppColors.border,
                            width: _selectedReference != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.handshake_outlined,
                              size: 20,
                              color: _selectedReference != null ? AppColors.primary : AppColors.slate400,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _selectedReference != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedReference!.name,
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          BengaliDigits.toBengali(_selectedReference!.phone),
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'রেফারেন্স ব্যক্তি নির্বাচন করুন (যদি থাকে)',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                            ),
                            if (_selectedReference != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: AppColors.rose),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() => _selectedReference = null);
                                },
                              )
                            else
                              const Icon(Icons.arrow_drop_down, color: AppColors.slate400),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            _buildEditCard(
              title: 'কাজের তথ্য',
              children: [
                const AppFieldLabel(
                  label: 'কাজের ধরন',
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Builder(
                  builder: (context) {
                    final liveWorkTypes = ref
                        .watch(workTypesStreamProvider)
                        .valueOrNull
                        ?.map((w) => w.name)
                        .toList();
                    final types = (liveWorkTypes != null && liveWorkTypes.isNotEmpty)
                        ? liveWorkTypes
                        : DemoStore.workTypes;

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: types.map((wt) {
                        final isSel = _selectedWorkType == wt;
                        return ChoiceChip(
                          label: Text(wt),
                          selected: isSel,
                          onSelected: (sel) {
                            if (sel) setState(() => _selectedWorkType = wt);
                          },
                          selectedColor: AppColors.primarySurface,
                          backgroundColor: AppColors.slate100,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                            fontFamily: AppTypography.fontFamily,
                          ),
                          side: BorderSide(color: isSel ? AppColors.primary : AppColors.border),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'মৌজার নাম',
                  hint: 'যেমন: বাগবাড়ী (জে.এল নং ৪৫)',
                  controller: _mouzaController,
                  prefixIcon: const Icon(Icons.map_outlined, size: 18, color: AppColors.slate400),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'আবেদন নম্বর',
                        controller: _appNumberController,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: 'কেস নম্বর',
                        controller: _caseNumberController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            _buildEditCard(
              title: 'আর্থিক চুক্তি ও নোট',
              children: [
                MoneyField(
                  label: 'চুক্তিকৃত মোট টাকা',
                  controller: _agreedAmountController,
                  isRequired: true,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'বিশেষ নোট',
                  controller: _notesController,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'পরিবর্তন সংরক্ষণ করুন',
              icon: Icons.check,
              onPressed: _saveChanges,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard({required String title, required List<Widget> children}) {
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
          Text(title, style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

