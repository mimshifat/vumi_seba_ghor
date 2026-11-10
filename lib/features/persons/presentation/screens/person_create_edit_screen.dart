import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/person_providers.dart';

class PersonCreateEditScreen extends ConsumerStatefulWidget {
  final dynamic person; // accepts Person or DemoPerson

  const PersonCreateEditScreen({super.key, this.person});

  @override
  ConsumerState<PersonCreateEditScreen> createState() =>
      _PersonCreateEditScreenState();
}

class _PersonCreateEditScreenState
    extends ConsumerState<PersonCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool get _isEditing => widget.person != null;

  String? get _personId => widget.person is Person
      ? (widget.person as Person).id
      : widget.person is DemoPerson
          ? (widget.person as DemoPerson).id
          : null;

  @override
  void initState() {
    super.initState();
    String initName = '';
    String initPhone = '';
    String initAddress = '';
    String initNotes = '';

    if (widget.person is Person) {
      final p = widget.person as Person;
      initName = p.name;
      initPhone = p.phone;
      initAddress = p.address ?? '';
      initNotes = p.notes ?? '';
    } else if (widget.person is DemoPerson) {
      final p = widget.person as DemoPerson;
      initName = p.name;
      initPhone = p.phone;
      initAddress = p.address ?? '';
      initNotes = p.notes ?? '';
    }

    _nameController = TextEditingController(text: initName);
    _phoneController = TextEditingController(text: initPhone);
    _addressController = TextEditingController(text: initAddress);
    _notesController = TextEditingController(text: initNotes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : null;
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    try {
      if (_isEditing && _personId != null) {
        await ref.read(personControllerProvider.notifier).updatePerson(
              id: _personId!,
              name: name,
              phone: phone,
              address: address,
              notes: notes,
            );

        // Also update DemoStore if present for backwards compatibility
        final idx = DemoStore.persons.indexWhere((p) => p.id == _personId);
        if (idx != -1) {
          DemoStore.persons[idx] = DemoPerson(
            id: _personId!,
            name: name,
            phone: phone,
            address: address,
            notes: notes,
            totalAgreed: DemoStore.persons[idx].totalAgreed,
            totalDue: DemoStore.persons[idx].totalDue,
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ব্যক্তির তথ্য সফলভাবে হালনাগাদ করা হয়েছে।'),
            backgroundColor: AppColors.emerald,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final created = await ref.read(personControllerProvider.notifier).createPerson(
              name: name,
              phone: phone,
              address: address,
              notes: notes,
            );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('নতুন ব্যক্তি "$name" সফলভাবে সংরক্ষিত হয়েছে।'),
            backgroundColor: AppColors.emerald,
          ),
        );
        Navigator.pop(context, created ?? true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppFailure ? e.message : 'ব্যক্তির তথ্য সংরক্ষণ করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(personControllerProvider);
    final isLoading = mutationState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'ব্যক্তির তথ্য সম্পাদনা' : 'নতুন ব্যক্তি যোগ করুন'),
      ),
      body: Form(
        key: _formKey,
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
                children: [
                  AppTextField(
                    label: 'পুরো নাম',
                    hint: 'যেমন: মো: রহিম উদ্দিন',
                    controller: _nameController,
                    isRequired: true,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'নাম আবশ্যক' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'মোবাইল নম্বর',
                    hint: '০১৭১১২২৩৩৪8',
                    controller: _phoneController,
                    isRequired: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [BdPhoneInputFormatter()],
                    validator: AppValidators.validatePhone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'ঠিকানা',
                    hint: 'গ্রাম, ডাকঘর, থানা/উপজেলা, জেলা',
                    controller: _addressController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'মন্তব্য বা পরিচয় নোট',
                    hint: 'যেমন: অমুক সাহেবের ভাই, স্থানীয় মুরুব্বি ইত্যাদি',
                    controller: _notesController,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: _isEditing ? 'পরিবর্তন সংরক্ষণ করুন' : 'সংরক্ষণ করুন',
              icon: Icons.check,
              isLoading: isLoading,
              onPressed: isLoading ? null : _savePerson,
            ),
          ],
        ),
      ),
    );
  }
}
