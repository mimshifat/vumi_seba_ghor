import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/case_number_formatter.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/case_number_field.dart';
import '../../../../core/widgets/money_field.dart';
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
  late final TextEditingController _mouzaController;
  late final TextEditingController _appNumberController;
  late final TextEditingController _caseNumberController;
  late final TextEditingController _agreedAmountController;
  late final TextEditingController _portalPhoneController;
  late final TextEditingController _portalPasswordController;
  late final TextEditingController _notesController;

  late String _selectedWorkType;
  late bool _useSamePhoneForPortal;
  bool _obscurePortalPassword = true;

  @override
  void initState() {
    super.initState();
    final app = widget.application;
    _nameController = TextEditingController(text: app.applicantName);
    _phoneController = TextEditingController(text: app.applicantPhone);
    _addressController = TextEditingController(text: app.applicantAddress ?? '');
    _mouzaController = TextEditingController(text: app.mouza ?? '');
    _appNumberController = TextEditingController(text: app.appNumber ?? '');
    _caseNumberController = TextEditingController(
      text: app.caseNumber != null && app.caseNumber!.trim().isNotEmpty
          ? CaseNumberFormatter.formatDisplay(app.caseNumber)
          : '',
    );
    _agreedAmountController = TextEditingController(text: app.agreedAmount.inTaka.toString());
    _useSamePhoneForPortal = app.portalPhone == null ||
        app.portalPhone!.trim().isEmpty ||
        app.portalPhone!.trim() == app.applicantPhone.trim();
    _portalPhoneController = TextEditingController(
      text: _useSamePhoneForPortal ? '' : (app.portalPhone ?? ''),
    );
    _portalPasswordController = TextEditingController(text: app.portalPassword ?? '');
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
    _portalPhoneController.dispose();
    _portalPasswordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final rawCase = _caseNumberController.text.trim();
    if (rawCase.isNotEmpty) {
      final formattedCase = CaseNumberFormatter.format(
        rawCase,
        referenceDate: widget.application.applicationDate,
      );
      if (formattedCase != null && formattedCase != _caseNumberController.text) {
        _caseNumberController.text = formattedCase;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    final agreedTaka = int.tryParse(BengaliDigits.toEnglish(
            _agreedAmountController.text.replaceAll(',', ''))) ??
        widget.application.agreedAmount.inTaka;
    final agreedPaisa = Money.fromTaka(agreedTaka).paisa;

    final rawPortalPhone = _portalPhoneController.text.trim();
    final portalPhoneToSave = _useSamePhoneForPortal
        ? ''
        : (rawPortalPhone.isNotEmpty
            ? AppValidators.standardizePhone(rawPortalPhone)
            : '');
    final portalPasswordToSave = _portalPasswordController.text.trim();

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
                ? CaseNumberFormatter.format(
                    _caseNumberController.text,
                    referenceDate: widget.application.applicationDate,
                  )
                : null,
            agreedAmountPaisa: agreedPaisa,
            portalPhone: portalPhoneToSave,
            portalPassword: portalPasswordToSave,
            updatePortalCredentials: true,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (!mounted) return;

      final mutationState = ref.read(applicationControllerProvider);
      if (mutationState.hasError) {
        final err = mutationState.error;
        final msg = err is AppFailure
            ? err.message
            : 'হালনাগাদে একটি সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আবেদনের তথ্য সফলভাবে হালনাগাদ করা হয়েছে।'),
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
                  readOnly: true,
                  isRequired: true,
                  validator: (v) => v == null || v.trim().isEmpty ? 'নাম আবশ্যক' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'মোবাইল নম্বর',
                  controller: _phoneController,
                  readOnly: true,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  helperText: 'মূল গ্রাহকের নম্বর অপরিবর্তনীয়; পোর্টাল নম্বর নিচে বদলাতে পারবেন',
                  validator: (v) => v == null || v.trim().isEmpty ? 'মোবাইল নম্বর আবশ্যক' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'ঠিকানা',
                  hint: 'গ্রাম, ডাকঘর, উপজেলা, জেলা...',
                  controller: _addressController,
                  readOnly: true,
                  isRequired: false,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.home_outlined, size: 18, color: AppColors.slate400),
                ),
                const SizedBox(height: AppSpacing.md),
                // Reference Person (snapshot read-only)
                if (widget.application.referencePersonName != null &&
                    widget.application.referencePersonName!.isNotEmpty)
                  AppTextField(
                    label: 'রেফারেন্স ব্যক্তি',
                    initialValue: widget.application.referencePersonName,
                    readOnly: true,
                    prefixIcon: const Icon(
                      Icons.handshake_outlined,
                      size: 18,
                      color: AppColors.slate400,
                    ),
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
                    final baseTypes = (liveWorkTypes != null && liveWorkTypes.isNotEmpty)
                        ? liveWorkTypes
                        : DemoStore.workTypes;
                    // সফট ডিলিট করা পুরনো কাজের ধরনও সম্পাদনার সময় নির্বাচনযোগ্য রাখুন
                    final types = (_selectedWorkType.isNotEmpty &&
                            !baseTypes.contains(_selectedWorkType))
                        ? [...baseTypes, _selectedWorkType]
                        : baseTypes;

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
                AppTextField(
                  label: 'আবেদন নম্বর',
                  controller: _appNumberController,
                  prefixIcon: const Icon(Icons.tag, size: 18, color: AppColors.slate400),
                ),
                const SizedBox(height: AppSpacing.md),
                CaseNumberField(
                  controller: _caseNumberController,
                  referenceDate: widget.application.applicationDate,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            _buildEditCard(
              title: 'ভূমি পোর্টাল লগইন তথ্য (LSG)',
              children: [
                CheckboxListTile(
                  value: _useSamePhoneForPortal,
                  onChanged: (val) {
                    setState(() => _useSamePhoneForPortal = val ?? true);
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: Text(
                    'আবেদনকারীর মোবাইল নম্বরই পোর্টাল লগইন নম্বর',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!_useSamePhoneForPortal) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'পোর্টাল লগইন মোবাইল নম্বর',
                    hint: 'আবেদনে ব্যবহৃত আলাদা মোবাইল নম্বর',
                    controller: _portalPhoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.sim_card_outlined, size: 18, color: AppColors.slate400),
                    validator: (val) {
                      if (_useSamePhoneForPortal || val == null || val.trim().isEmpty) {
                        return null;
                      }
                      if (!AppValidators.isValidPhone(val)) {
                        return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'পোর্টাল পাসওয়ার্ড',
                  hint: 'lsg-land-owner.land.gov.bd পাসওয়ার্ড',
                  controller: _portalPasswordController,
                  obscureText: _obscurePortalPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.slate400),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePortalPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.slate500,
                    ),
                    onPressed: () {
                      setState(() => _obscurePortalPassword = !_obscurePortalPassword);
                    },
                  ),
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

