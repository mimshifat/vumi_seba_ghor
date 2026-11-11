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
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog_action_row.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/attachment_picker_sheet.dart';
import '../../../../core/widgets/case_number_field.dart';
import '../../../../core/widgets/money_field.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import '../../../offices/presentation/providers/office_providers.dart';
import '../../../persons/presentation/providers/person_providers.dart';
import '../../../references/presentation/widgets/reference_selector_sheet.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/services/land_portal_helper.dart';
import '../providers/application_providers.dart';
import '../widgets/form_step_indicator.dart';

class ApplicationCreateScreen extends ConsumerStatefulWidget {
  const ApplicationCreateScreen({super.key});

  @override
  ConsumerState<ApplicationCreateScreen> createState() =>
      _ApplicationCreateScreenState();
}

class _ApplicationCreateScreenState
    extends ConsumerState<ApplicationCreateScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Step 1: Applicant Information
  String? _selectedPersonId;
  bool _isSavedCustomerSelected = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _useSamePhoneForPortal = true;
  final _portalPhoneController = TextEditingController();
  final _portalPasswordController =
      TextEditingController(text: LandPortalHelper.defaultPortalPassword);
  bool _obscurePortalPassword = true;

  // Step 2: Work & Office Information
  String _selectedWorkType = 'নামজারি';
  String _selectedOffice = 'উপজেলা ভূমি অফিস, চাঁপাইনবাবগঞ্জ সদর';
  DateTime _applicationDate = DateTime.now();
  final _mouzaController = TextEditingController();
  final _appNumberController = TextEditingController();
  final _caseNumberController = TextEditingController();

  // Step 3: Financials, Reference & Documents
  DemoReference? _selectedReference;
  final _agreedAmountController = TextEditingController();
  final _initialPaymentController = TextEditingController();
  final List<PickedAttachment> _attachedFiles = [];
  bool _isPickingAttachment = false;
  final _notesController = TextEditingController();

  static const _steps = [
    StepItem(
      title: 'গ্রাহকের তথ্য',
      icon: Icons.person_outline,
    ),
    StepItem(
      title: 'কাজ ও অফিস',
      icon: Icons.work_outline,
    ),
    StepItem(
      title: 'চুক্তি ও সম্পন্ন',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _portalPhoneController.dispose();
    _portalPasswordController.dispose();
    _mouzaController.dispose();
    _appNumberController.dispose();
    _caseNumberController.dispose();
    _agreedAmountController.dispose();
    _initialPaymentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _normalizeCaseNumberInput() {
    final raw = _caseNumberController.text.trim();
    if (raw.isEmpty) return;
    final formatted = CaseNumberFormatter.format(
      raw,
      referenceDate: _applicationDate,
    );
    if (formatted != null && formatted != _caseNumberController.text) {
      _caseNumberController.text = formatted;
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      return _step1FormKey.currentState?.validate() ?? false;
    } else if (step == 1) {
      _normalizeCaseNumberInput();
      return _step2FormKey.currentState?.validate() ?? false;
    } else if (step == 2) {
      return _step3FormKey.currentState?.validate() ?? false;
    }
    return true;
  }

  void _goToStep(int targetStep) {
    if (targetStep < 0 || targetStep >= _steps.length) return;
    if (targetStep > _currentStep) {
      for (int s = _currentStep; s < targetStep; s++) {
        if (!_validateStep(s)) return;
      }
    }
    _pageController.animateToPage(
      targetStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      _goToStep(1);
    } else if (_currentStep == 1) {
      _normalizeCaseNumberInput();
      if (!_step2FormKey.currentState!.validate()) return;
      _goToStep(2);
    } else if (_currentStep == 2) {
      if (!_step3FormKey.currentState!.validate()) return;
      _saveApplication();
    }
  }

  void _onPrevStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _showPersonSelector() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final livePersons = ref.read(personsStreamProvider).valueOrNull;
          final personList = livePersons != null
              ? livePersons
                  .map((p) => DemoPerson(
                        id: p.id,
                        name: p.name,
                        phone: p.phone,
                        address: p.address,
                        totalAgreed: Money.zero,
                        totalDue: Money.zero,
                      ))
                  .toList()
              : const <DemoPerson>[];

          final filteredPersons = personList.where((p) {
            if (searchQuery.isEmpty) return true;
            final query = searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.phone.contains(query) ||
                BengaliDigits.toBengali(p.phone).contains(query);
          }).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: AppSpacing.md,
              left: AppSpacing.base,
              right: AppSpacing.base,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'সংরক্ষিত গ্রাহক নির্বাচন',
                        style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppColors.slate500),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'গ্রাহক নির্বাচন করলে নাম, মোবাইল ও ঠিকানা স্বয়ংক্রিয় পূরণ হবে',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'নাম বা মোবাইল নম্বর দিয়ে খুঁজুন...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.slate400),
                      filled: true,
                      fillColor: AppColors.slate50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        searchQuery = val.trim();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: filteredPersons.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_off_outlined, size: 40, color: AppColors.slate300),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'কোনো গ্রাহক পাওয়া যায়নি',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredPersons.length,
                            separatorBuilder: (c, i) => const Divider(height: 1),
                            itemBuilder: (c, i) {
                              final p = filteredPersons[i];
                              final isCurrent = _selectedPersonId == p.id;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                leading: CircleAvatar(
                                  backgroundColor: isCurrent ? AppColors.primary : AppColors.primarySurface,
                                  child: Text(
                                    p.name.isNotEmpty ? p.name.characters.first : '?',
                                    style: TextStyle(
                                      color: isCurrent ? Colors.white : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      BengaliDigits.toBengali(p.phone),
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                    if (p.address != null && p.address!.isNotEmpty)
                                      Text(
                                        p.address!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.slate400,
                                          fontSize: 11.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                                trailing: isCurrent
                                    ? const Icon(Icons.check_circle, size: 20, color: AppColors.primary)
                                    : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.slate400),
                                onTap: () {
                                  setState(() {
                                    _selectedPersonId = p.id;
                                    _isSavedCustomerSelected = true;
                                    _nameController.text = p.name;
                                    _phoneController.text = p.phone;
                                    _addressController.text = p.address ?? '';
                                  });
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddOfficeDialog({void Function(String)? onAdded}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন অফিস যোগ করুন'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'অফিসের নাম', isRequired: true),
            hintText: 'যেমন: উপজেলা ভূমি অফিস, চাঁপাইনবাবগঞ্জ সদর',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          AppDialogActionRow(
            confirmText: 'যোগ করুন',
            onConfirm: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref
                    .read(officeControllerProvider.notifier)
                    .createOffice(name: newName);
                setState(() {
                  _selectedOffice = newName;
                });
                onAdded?.call(newName);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddWorkTypeDialog({void Function(String)? onAdded}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন কাজের ধরন যোগ করুন'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'কাজের নাম', isRequired: true),
            hintText: 'যেমন: মিস কেস বা নামজারি আপিল',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          AppDialogActionRow(
            confirmText: 'যোগ করুন',
            onConfirm: () {
              final newType = controller.text.trim();
              if (newType.isNotEmpty) {
                ref
                    .read(categoryControllerProvider.notifier)
                    .createWorkType(name: newType);
                setState(() {
                  _selectedWorkType = newType;
                });
                onAdded?.call(newType);
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _applicationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _applicationDate = picked);
    }
  }

  Future<void> _saveApplication() async {
    // ১. নিরাপদ ফিল্ড-লেভেল ভ্যালিডেশন (আনমাউন্টেড কী ক্র্যাশ প্রতিরোধে)
    final cleanName = _nameController.text.trim();
    if (cleanName.isEmpty) {
      _goToStep(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে আবেদনকারীর নাম লিখুন'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cleanPhone = AppValidators.standardizePhone(_phoneController.text.trim());
    if (!AppValidators.isValidPhone(cleanPhone)) {
      _goToStep(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('১১ ডিজিটের সঠিক মোবাইল নম্বর দিন'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_appNumberController.text.trim().isEmpty) {
      _goToStep(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আবেদন নম্বর আবশ্যক'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedWorkType.trim().isEmpty) {
      _goToStep(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কাজের ধরন নির্বাচন আবশ্যক'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedOffice.trim().isEmpty) {
      _goToStep(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ভূমি অফিস নির্বাচন আবশ্যক'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_step3FormKey.currentState?.validate() == false) {
      return;
    }

    final agreedTaka = int.tryParse(BengaliDigits.toEnglish(
            _agreedAmountController.text.replaceAll(',', ''))) ??
        0;
    final initialTaka = int.tryParse(BengaliDigits.toEnglish(
            _initialPaymentController.text.replaceAll(',', ''))) ??
        0;

    final agreedPaisa = Money.fromTaka(agreedTaka).paisa;
    final initialPaymentPaisa =
        initialTaka > 0 ? Money.fromTaka(initialTaka).paisa : null;

    final rawPortalPhone = _portalPhoneController.text.trim();
    if (!_useSamePhoneForPortal &&
        rawPortalPhone.isNotEmpty &&
        !AppValidators.isValidPhone(rawPortalPhone)) {
      _goToStep(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সঠিক পোর্টাল লগইন মোবাইল নম্বর দিন'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final portalPhoneToSave = _useSamePhoneForPortal
        ? null
        : (rawPortalPhone.isNotEmpty
            ? AppValidators.standardizePhone(rawPortalPhone)
            : null);
    final portalPasswordToSave = _portalPasswordController.text.trim().isNotEmpty
        ? _portalPasswordController.text.trim()
        : null;

    try {
      final createdApp = await ref.read(applicationControllerProvider.notifier).createApplication(
            applicantId: _selectedPersonId,
            applicantName: cleanName,
            applicantPhone: cleanPhone,
            applicantAddress: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
            referenceId: _selectedReference?.id,
            referenceName: _selectedReference?.name,
            officeName: _selectedOffice,
            mouza: _mouzaController.text.trim().isNotEmpty
                ? _mouzaController.text.trim()
                : null,
            appNumber: _appNumberController.text.trim().isNotEmpty
                ? _appNumberController.text.trim()
                : null,
            caseNumber: _caseNumberController.text.trim().isNotEmpty
                ? CaseNumberFormatter.format(
                    _caseNumberController.text,
                    referenceDate: _applicationDate,
                  )
                : null,
            workType: _selectedWorkType,
            applicationDate: _applicationDate,
            status: 'আবেদন',
            agreedAmountPaisa: agreedPaisa,
            portalPhone: portalPhoneToSave,
            portalPassword: portalPasswordToSave,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            initialPaymentPaisa: initialPaymentPaisa,
            initialPaymentMethod: 'নগদ',
          );

      if (!mounted) return;

      if (createdApp == null) {
        final failure = ref.read(applicationControllerProvider).error;
        final message = failure is AppFailure
            ? failure.message
            : 'সংরক্ষণে একটি সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // সংযুক্ত ডকুমেন্টসমূহ থাকলে তা ডেটাবেজে সংরক্ষণ করি
      var docSaveFailed = false;
      for (final doc in _attachedFiles) {
        final savedDoc = await ref.read(applicationControllerProvider.notifier).addDocument(
              applicationId: createdApp.id,
              fileName: doc.fileName,
              fileType: doc.fileType,
              fileData: doc.bytes,
              fileSize: doc.fileSize,
            );
        if (!mounted) return;
        if (savedDoc == null) {
          docSaveFailed = true;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            docSaveFailed
                ? 'আবেদন "$cleanName" সংরক্ষিত হয়েছে, তবে সংযুক্ত ফাইলটি সেভ করা যায়নি।'
                : 'আবেদন "$cleanName" সফলভাবে সংরক্ষিত হয়েছে!',
          ),
          backgroundColor: docSaveFailed ? AppColors.amberDark : AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );

      ref.invalidate(applicationsWithFinancialsStreamProvider);
      ref.invalidate(allUnifiedTransactionsStreamProvider);

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e is AppFailure
          ? e.message
          : 'সংরক্ষণে একটি সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('নতুন আবেদন এন্ট্রি'),
      ),
      body: Column(
        children: [
          // Visual Step Indicator
          FormStepIndicator(
            currentStep: _currentStep,
            steps: _steps,
            onStepTapped: (step) => _goToStep(step),
          ),

          // Multi-step PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Managed via Next/Prev buttons
              onPageChanged: (page) {
                setState(() => _currentStep = page);
              },
              children: [
                _KeepAlivePage(child: _buildStep1CustomerInfo()),
                _KeepAlivePage(child: _buildStep2WorkAndOffice()),
                _KeepAlivePage(child: _buildStep3PaymentAndFinish()),
              ],
            ),
          ),

          // Pinned Bottom Navigation Controls
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 1: গ্রাহকের তথ্য
  // -------------------------------------------------------------
  Widget _buildStep1CustomerInfo() {
    return Form(
      key: _step1FormKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Main Inputs Container with integrated customer selection
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with integrated quick select action
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'আবেদনকারীর বিবরণ',
                            style: AppTypography.headingSmall.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'নতুন অথবা সংরক্ষিত খাতা থেকে নির্বাচন করুন',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showPersonSelector,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            border: Border.all(color: AppColors.primaryLight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_search_outlined, size: 15, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                'সংরক্ষিত গ্রাহক',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),

                // Selected customer badge (if filled from saved profile)
                if (_isSavedCustomerSelected) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.emerald),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'সংরক্ষিত গ্রাহকের তথ্য পূরণ করা হয়েছে',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isSavedCustomerSelected = false;
                              _selectedPersonId = null;
                              _nameController.clear();
                              _phoneController.clear();
                              _addressController.clear();
                              _useSamePhoneForPortal = true;
                              _portalPhoneController.clear();
                              _portalPasswordController.text =
                                  LandPortalHelper.defaultPortalPassword;
                            });
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.clear, size: 14, color: AppColors.slate500),
                                const SizedBox(width: 3),
                                Text(
                                  'রিসেট',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.slate600,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Name
                AppTextField(
                  label: 'আবেদনকারীর নাম',
                  hint: 'যেমন: মো: রহিম উদ্দিন',
                  controller: _nameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.slate400),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'আবেদনকারীর নাম আবশ্যক';
                    if (val.trim().length < 2) return 'সঠিক নাম লিখুন (কমপক্ষে ২ অক্ষর)';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.base),

                // Phone
                AppTextField(
                  label: 'মোবাইল নম্বর',
                  hint: '০১৭১১২২৩৩৪৪',
                  controller: _phoneController,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [BdPhoneInputFormatter()],
                  prefixIcon: const Icon(Icons.phone_android_outlined, size: 18, color: AppColors.slate400),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'মোবাইল নম্বর আবশ্যক';
                    final cleaned = BengaliDigits.toEnglish(val.replaceAll(RegExp(r'[\s\-]'), ''));
                    if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(cleaned)) {
                      return 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: ০১৭১১২২৩৩৪৪)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.base),

                // Address
                AppTextField(
                  label: 'ঠিকানা',
                  hint: 'গ্রাম, ডাকঘর, উপজেলা, জেলা...',
                  controller: _addressController,
                  isRequired: false,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.home_outlined, size: 18, color: AppColors.slate400),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Land Portal Login Credentials Container (Optional)
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.04),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ভূমি পোর্টাল লগইন তথ্য (LSG)',
                            style: AppTypography.headingSmall.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'অটো-লগইনের জন্য পোর্টালের নম্বর ও পাসওয়ার্ড সংরক্ষণ করুন',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  value: _useSamePhoneForPortal,
                  onChanged: (val) {
                    setState(() {
                      _useSamePhoneForPortal = val ?? true;
                    });
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
                    hint: 'আবেদনে ব্যবহৃত আলাদা মোবাইল নম্বর (যেমন: ০১৭...)',
                    controller: _portalPhoneController,
                    isRequired: false,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [BdPhoneInputFormatter()],
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
                  hint: 'ডিফল্ট: ${LandPortalHelper.defaultPortalPassword}',
                  helperText:
                      'ডিফল্ট পাসওয়ার্ড: ${LandPortalHelper.defaultPortalPassword} (প্রয়োজনে পরিবর্তন করতে পারেন)',
                  controller: _portalPasswordController,
                  isRequired: false,
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
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 2: কাজ ও অফিস
  // -------------------------------------------------------------
  Widget _buildStep2WorkAndOffice() {
    return Form(
      key: _step2FormKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.work_outline, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'কাজের ধরন ও সংশ্লিষ্ট ভূমি অফিস',
                      style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // 1. TOP: Application & Case Numbers
                AppTextField(
                  label: 'আবেদন নম্বর',
                  hint: 'SAV-MUT-২০২৬...',
                  controller: _appNumberController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.tag, size: 18, color: AppColors.slate400),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'আবেদন নম্বর আবশ্যক';
                    }
                    if (val.trim().length < 3) {
                      return 'সঠিক আবেদন নম্বর দিন';
                    }
                    final allApps = ref
                        .read(applicationsWithFinancialsStreamProvider)
                        .valueOrNull ??
                        const [];
                    final isDuplicate = allApps.any(
                      (a) =>
                          a.application.appNumber != null &&
                          a.application.appNumber!.trim().toLowerCase() ==
                              val.trim().toLowerCase(),
                    );
                    if (isDuplicate) {
                      return 'নম্বরটি ইতিমধ্যে ব্যবহৃত';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CaseNumberField(
                  controller: _caseNumberController,
                  referenceDate: _applicationDate,
                ),

                const SizedBox(height: AppSpacing.base),

                // 2. Work Type Selection
                FormField<String>(
                  initialValue: _selectedWorkType,
                  validator: (val) {
                    if (_selectedWorkType.trim().isEmpty) {
                      return 'কাজের ধরন নির্বাচন আবশ্যক';
                    }
                    return null;
                  },
                  builder: (fieldState) {
                    final liveWorkTypes = ref
                        .watch(workTypesStreamProvider)
                        .valueOrNull
                        ?.map((w) => w.name)
                        .toList();
                    final workTypeList =
                        (liveWorkTypes != null && liveWorkTypes.isNotEmpty)
                            ? liveWorkTypes
                            : DemoStore.workTypes;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppFieldLabel(
                              label: 'কাজের ধরন',
                              isRequired: true,
                            ),
                            InkWell(
                              onTap: () => _showAddWorkTypeDialog(onAdded: (val) {
                                fieldState.didChange(val);
                              }),
                              child: Text(
                                '+ নতুন ধরন',
                                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: workTypeList.map((wt) {
                            final isSelected = _selectedWorkType == wt;
                            return ChoiceChip(
                              label: Text(wt),
                              selected: isSelected,
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() => _selectedWorkType = wt);
                                  fieldState.didChange(wt);
                                }
                              },
                              selectedColor: AppColors.primarySurface,
                              backgroundColor: AppColors.slate100,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 12.5,
                                fontFamily: AppTypography.fontFamily,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primary
                                    : (fieldState.hasError ? AppColors.rose : AppColors.border),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                            );
                          }).toList(),
                        ),
                        if (fieldState.hasError) ...[
                          const SizedBox(height: 4),
                          Text(
                            fieldState.errorText!,
                            style: const TextStyle(
                              color: AppColors.rose,
                              fontSize: 12,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // 3. Office Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppFieldLabel(
                      label: 'অফিসের নাম',
                      isRequired: true,
                    ),
                    InkWell(
                      onTap: () => _showAddOfficeDialog(onAdded: (val) {
                        setState(() => _selectedOffice = val);
                      }),
                      child: Text(
                        '+ নতুন অফিস',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                () {
                  final liveOffices = ref
                      .watch(officesStreamProvider)
                      .valueOrNull
                      ?.map((o) => o.name)
                      .toList();
                  final officeList =
                      (liveOffices != null && liveOffices.isNotEmpty)
                          ? liveOffices
                          : DemoStore.offices.map((o) => o.name).toList();

                  final effectiveOffice = _selectedOffice.isNotEmpty &&
                          officeList.contains(_selectedOffice)
                      ? _selectedOffice
                      : (officeList.isNotEmpty ? officeList.first : null);

                  return DropdownButtonFormField<String>(
                    initialValue: effectiveOffice,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.account_balance_outlined, size: 18, color: AppColors.slate400),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.rose),
                      ),
                    ),
                    items: officeList.map((offName) {
                      return DropdownMenuItem(
                        value: offName,
                        child: Text(offName, style: AppTypography.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedOffice = val);
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'ভূমি অফিস নির্বাচন আবশ্যক';
                      }
                      return null;
                    },
                  );
                }(),

                const SizedBox(height: AppSpacing.md),

                // 4. Application Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel(
                      label: 'আবেদনের তারিখ',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    InkWell(
                      onTap: _selectDate,
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
                            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              BengaliDigits.toBengali('${_applicationDate.day}/${_applicationDate.month}/${_applicationDate.year}'),
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar, size: 16, color: AppColors.slate400),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 5. Mouza Input
                AppTextField(
                  label: 'মৌজার নাম',
                  hint: 'যেমন: বাগবাড়ী (জে.এল নং ৪৫)',
                  controller: _mouzaController,
                  prefixIcon: const Icon(Icons.map_outlined, size: 18, color: AppColors.slate400),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 3: চুক্তি, রেফারেন্স, ডকুমেন্ট ও সম্পন্ন
  // -------------------------------------------------------------
  Widget _buildStep3PaymentAndFinish() {
    return Form(
      key: _step3FormKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Prominent Summary Card at the Top
          _buildSummaryCard(),

          const SizedBox(height: AppSpacing.base),

          // Reference and Financials Container
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
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'রেফারেন্স ও চুক্তির হিসাব',
                      style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
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

                const SizedBox(height: AppSpacing.base),

                // Agreed Service Fee
                MoneyField(
                  label: 'চুক্তিকৃত মোট সার্ভিস ফি (টাকা)',
                  hint: '৭০০০',
                  controller: _agreedAmountController,
                  isRequired: true,
                  showQuickChips: true,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'চুক্তির সার্ভিস ফি উল্লেখ করুন';
                    final fee = int.tryParse(BengaliDigits.toEnglish(val.replaceAll(',', '').trim()));
                    if (fee == null || fee <= 0) return 'চুক্তির সার্ভিস ফি উল্লেখ করুন';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Initial Payment / Advance
                MoneyField(
                  label: 'প্রাথমিক জমা / অগ্রিম',
                  hint: '০',
                  controller: _initialPaymentController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final advance = int.tryParse(BengaliDigits.toEnglish(val.replaceAll(',', '').trim())) ?? 0;
                    if (advance < 0) return 'অগ্রিম জমা ঋণাত্মক হতে পারে না';
                    final fee = int.tryParse(BengaliDigits.toEnglish(_agreedAmountController.text.replaceAll(',', '').trim())) ?? 0;
                    if (fee > 0 && advance > fee) {
                      return 'অগ্রিম জমা মোট চুক্তির টাকার চেয়ে বেশি হতে পারে না';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Document and Notes Container
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
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'ডকুমেন্ট ও বিশেষ মন্তব্য',
                      style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // Document Attachment
                if (_attachedFiles.isEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: _pickAttachment,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.upload_file_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'আবেদন PDF বা ছবি সংযুক্ত করুন',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Text(
                                  'একসাথে এক বা একাধিক ফাইল নির্বাচন করতে পারেন',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _pickAttachment,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text('ফাইল বাছুন'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'সংযুক্ত ফাইলসমূহ (${BengaliDigits.toBengali(_attachedFiles.length)}টি)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate700,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 15),
                                label: const Text('আরও যোগ করুন', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: _pickAttachment,
                              ),
                            ],
                          ),
                        ),
                        ..._attachedFiles.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final file = entry.value;
                          final isImage = file.fileType == 'image';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                if (isImage)
                                  GestureDetector(
                                    onTap: () {
                                      AttachmentPickerSheet.showImagePreviewDialog(
                                        context,
                                        bytes: file.bytes,
                                        title: file.fileName,
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.memory(
                                        file.bytes,
                                        width: 32,
                                        height: 32,
                                        cacheWidth: 96,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.rose.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: AppColors.rose,
                                      size: 18,
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.fileName,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        file.fileSize,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.slate400),
                                  tooltip: 'মুছে ফেলুন',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    setState(() {
                                      _attachedFiles.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.md),

                // Special Notes
                AppTextField(
                  label: 'বিশেষ নোট বা গ্রাহকের নির্দেশ',
                  hint: 'কোনো বিশেষ নির্দেশনা থাকলে লিখে রাখুন...',
                  controller: _notesController,
                  maxLines: 2,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _pickAttachment() async {
    if (_isPickingAttachment) return;
    _isPickingAttachment = true;
    try {
      final pickedList = await AttachmentPickerSheet.pickMultiple(context);
      if (pickedList.isEmpty || !mounted) return;
      setState(() {
        _attachedFiles.addAll(pickedList);
      });
    } finally {
      _isPickingAttachment = false;
    }
  }

  // -------------------------------------------------------------
  // সারসংক্ষেপ কার্ড (Summary Card)
  // -------------------------------------------------------------
  Widget _buildSummaryCard() {
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'নাম দেওয়া হয়নি';
    final phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : 'ফোন নম্বর নেই';
    final address = _addressController.text.trim();
    final mouza = _mouzaController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit triggers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg - 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_turned_in_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'আবেদনের সারসংক্ষেপ',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _goToStep(0),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'সম্পাদনা',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              children: [
                // Client Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        name.isNotEmpty ? name.characters.first : '?',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.phone_android, size: 13, color: AppColors.slate400),
                              const SizedBox(width: 4),
                              Text(
                                BengaliDigits.toBengali(phone),
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.slate400),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(height: 1),
                ),

                // Work & Office Details Grid
                Row(
                  children: [
                    // Work Type & Office
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                ),
                                child: Text(
                                  _selectedWorkType,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedOffice,
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_appNumberController.text.trim().isNotEmpty || _caseNumberController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (_appNumberController.text.trim().isNotEmpty) 'আবেদন: ${_appNumberController.text.trim()}',
                                if (_caseNumberController.text.trim().isNotEmpty)
                                  'কেস: ${CaseNumberFormatter.format(_caseNumberController.text, referenceDate: _applicationDate)}',
                              ].join(' • '),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Date & Mouza
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.slate400),
                            const SizedBox(width: 4),
                            Text(
                              BengaliDigits.toBengali('${_applicationDate.day}/${_applicationDate.month}/${_applicationDate.year}'),
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        if (mouza.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            mouza,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Pinned Bottom Navigation Controls
  // -------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == _steps.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            if (!isFirstStep) ...[
              Expanded(
                flex: 1,
                child: AppButton(
                  text: 'পূর্ববর্তী',
                  variant: ButtonVariant.outline,
                  icon: Icons.arrow_back,
                  onPressed: _onPrevStep,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],

            // Next or Save button
            Expanded(
              flex: isFirstStep ? 1 : 2,
              child: AppButton(
                text: isLastStep ? 'আবেদন সংরক্ষণ করুন' : 'পরবর্তী ধাপ',
                icon: isLastStep ? Icons.check_circle_outline : Icons.arrow_forward,
                isLoading: isLastStep && ref.watch(applicationControllerProvider).isLoading,
                onPressed: _onNextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// পেজভিউ-এর ধাপগুলোকে মেমরিতে সক্রিয় রাখার সহায়ক উইজেট
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
