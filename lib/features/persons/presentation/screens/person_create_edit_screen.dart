import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class PersonCreateEditScreen extends StatefulWidget {
  final DemoPerson? person;

  const PersonCreateEditScreen({super.key, this.person});

  @override
  State<PersonCreateEditScreen> createState() => _PersonCreateEditScreenState();
}

class _PersonCreateEditScreenState extends State<PersonCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool get _isEditing => widget.person != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _phoneController = TextEditingController(text: widget.person?.phone ?? '');
    _addressController = TextEditingController(text: widget.person?.address ?? '');
    _notesController = TextEditingController(text: widget.person?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _savePerson() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      final updated = DemoPerson(
        id: widget.person!.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        applicationCount: widget.person!.applicationCount,
        totalAgreed: widget.person!.totalAgreed,
        totalDue: widget.person!.totalDue,
      );

      final idx = DemoStore.persons.indexWhere((p) => p.id == widget.person!.id);
      if (idx != -1) DemoStore.persons[idx] = updated;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ব্যক্তির তথ্য হালনাগাদ করা হয়েছে।'), backgroundColor: AppColors.emerald),
      );
      Navigator.pop(context, updated);
    } else {
      final newPerson = DemoPerson(
        id: 'p-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        applicationCount: 0,
        totalAgreed: Money.zero,
        totalDue: Money.zero,
      );

      DemoStore.persons.insert(0, newPerson);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('নতুন ব্যক্তি "${newPerson.name}" সংরক্ষিত হয়েছে।'), backgroundColor: AppColors.emerald),
      );
      Navigator.pop(context, newPerson);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Photo Avatar Mockup
                  Center(
                    child: Stack(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primarySurface,
                          child: Icon(Icons.person, size: 44, color: AppColors.primary),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  AppTextField(
                    label: 'পুরো নাম',
                    hint: 'যেমন: মো: রহিম উদ্দিন',
                    controller: _nameController,
                    isRequired: true,
                    validator: (v) => v == null || v.trim().isEmpty ? 'নাম আবশ্যক' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'মোবাইল নম্বর',
                    hint: '০১৭১১২২৩৩৪8',
                    controller: _phoneController,
                    isRequired: true,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty ? 'মোবাইল নম্বর আবশ্যক' : null,
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
              onPressed: _savePerson,
            ),
          ],
        ),
      ),
    );
  }
}
