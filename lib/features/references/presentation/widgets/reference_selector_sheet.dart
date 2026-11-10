import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/attachment_picker_sheet.dart';
import '../providers/reference_providers.dart';

class ReferenceSelectorSheet extends ConsumerStatefulWidget {
  final DemoReference? initialReference;
  final ValueChanged<DemoReference?> onSelected;

  const ReferenceSelectorSheet({
    super.key,
    this.initialReference,
    required this.onSelected,
  });

  static Future<DemoReference?> show(
    BuildContext context, {
    DemoReference? initialReference,
  }) {
    return showModalBottomSheet<DemoReference>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ReferenceSelectorSheet(
        initialReference: initialReference,
        onSelected: (ref) => Navigator.of(ctx).pop(ref),
      ),
    );
  }

  @override
  ConsumerState<ReferenceSelectorSheet> createState() =>
      _ReferenceSelectorSheetState();
}

class _ReferenceSelectorSheetState
    extends ConsumerState<ReferenceSelectorSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreatingNew = false;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  String? _inlineError;

  final _newNameController = TextEditingController();
  final _newPhoneController = TextEditingController();
  final _newAddressController = TextEditingController();
  final _newNotesController = TextEditingController();
  Uint8List? _newPhoto;

  @override
  void dispose() {
    _searchController.dispose();
    _newNameController.dispose();
    _newPhoneController.dispose();
    _newAddressController.dispose();
    _newNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickNewPhoto() async {
    if (_isPickingPhoto) return;
    _isPickingPhoto = true;
    try {
      final picked = await AttachmentPickerSheet.pickImage(
        context,
        title: 'রেফারেন্স ব্যক্তির ছবি নির্বাচন করুন',
      );
      if (picked == null || !mounted) return;
      setState(() {
        _newPhoto = picked.bytes;
      });
    } finally {
      _isPickingPhoto = false;
    }
  }

  Future<void> _saveAndSelectNewReference() async {
    if (_isSaving) return;
    final name = _newNameController.text.trim();
    final phone = _newPhoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _inlineError = 'নাম এবং মোবাইল নম্বর আবশ্যক।');
      return;
    }
    final phoneErr = AppValidators.validatePhone(phone);
    if (phoneErr != null) {
      setState(() => _inlineError = phoneErr);
      return;
    }

    setState(() {
      _isSaving = true;
      _inlineError = null;
    });
    try {
      final created = await ref
          .read(referenceControllerProvider.notifier)
          .createReference(
            name: name,
            phone: phone,
            address: _newAddressController.text.trim().isNotEmpty
                ? _newAddressController.text.trim()
                : null,
            photo: _newPhoto,
            notes: _newNotesController.text.trim().isNotEmpty
                ? _newNotesController.text.trim()
                : null,
          );

      if (!mounted) return;
      if (created == null) {
        final failure = ref.read(referenceControllerProvider).error;
        final errMsg = failure is AppFailure
            ? failure.message
            : 'রেফারেন্স ব্যক্তি যোগ করা যায়নি।';
        setState(() => _inlineError = errMsg);
        return;
      }

      final demo = DemoReference(
        id: created.id,
        name: created.name,
        phone: created.phone,
        address: created.address,
        photo: created.photo,
        notes: created.notes,
      );
      widget.onSelected(demo);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppFailure ? e.message : e.toString();
      setState(() => _inlineError = msg);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      } else {
        _isSaving = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final referencesAsync = ref.watch(referencesStreamProvider);
    final allReferences = referencesAsync.valueOrNull ?? const [];

    final query = _searchQuery.trim().toLowerCase();
    final filtered = allReferences.where((r) {
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query) ||
          r.phone.contains(query) ||
          (r.address?.toLowerCase().contains(query) ?? false);
    }).map((r) => DemoReference(
          id: r.id,
          name: r.name,
          phone: r.phone,
          address: r.address,
          photo: r.photo,
          notes: r.notes,
        )).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.base,
        right: AppSpacing.base,
        top: AppSpacing.base,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _isCreatingNew
                      ? 'নতুন রেফারেন্স যোগ করুন'
                      : 'রেফারেন্স ব্যক্তি নির্বাচন',
                  style: AppTypography.headingSmall
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton.icon(
                icon: Icon(
                  _isCreatingNew ? Icons.list_alt : Icons.add_circle_outline,
                  size: 17,
                  color: AppColors.primary,
                ),
                label: Text(
                  _isCreatingNew ? 'তালিকা দেখুন' : '+ নতুন রেফারেন্স',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
                onPressed: () {
                  setState(() {
                    _isCreatingNew = !_isCreatingNew;
                    _inlineError = null;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          if (_isCreatingNew)
            _buildCreateInlineForm()
          else ...[
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'নাম, মোবাইল বা ঠিকানা দিয়ে খুঁজুন...',
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.slate400),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.slate50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Option to clear selection
            if (widget.initialReference != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: InkWell(
                  onTap: () => widget.onSelected(null),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.close, size: 16, color: AppColors.rose),
                        const SizedBox(width: 8),
                        Text(
                          'কোনো রেফারেন্স ব্যক্তি নেই (মুছে ফেলুন)',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.rose),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // List of References
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: referencesAsync.isLoading && !referencesAsync.hasValue
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : referencesAsync.hasError && !referencesAsync.hasValue
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text(
                              'রেফারেন্স তালিকা লোড করা যায়নি।',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.rose),
                            ),
                          ),
                        )
                      : filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_off_outlined,
                                size: 36, color: AppColors.slate300),
                            const SizedBox(height: 8),
                            const Text(
                              'কোনো রেফারেন্স পাওয়া যায়নি',
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('এই নামে নতুন তৈরি করুন'),
                              onPressed: () {
                                _newNameController.text = _searchQuery;
                                setState(() => _isCreatingNew = true);
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.slate100),
                      itemBuilder: (ctx, idx) {
                        final item = filtered[idx];
                        final isSelected =
                            widget.initialReference?.id == item.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          leading: _buildAvatar(item),
                          title: Text(
                            item.name,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${BengaliDigits.toBengali(item.phone)}${item.address != null ? ' • ${item.address}' : ''}',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary, size: 20)
                              : null,
                          onTap: () => widget.onSelected(item),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(DemoReference r) {
    final fallback = CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        r.name.isNotEmpty ? r.name.characters.first : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );

    if (r.photo != null && r.photo!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          r.photo!,
          width: 36,
          height: 36,
          cacheWidth: 144,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }
    return fallback;
  }

  Widget _buildCreateInlineForm() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.65,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickNewPhoto,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFEF3C7),
                        border: Border.all(
                            color: const Color(0xFFFDE68A), width: 2),
                      ),
                      child: _newPhoto != null
                          ? ClipOval(
                              child: Image.memory(
                                _newPhoto!,
                                width: 72,
                                height: 72,
                                cacheWidth: 256,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.handshake_outlined,
                                    color: Color(0xFFD97706),
                                    size: 32,
                                  ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.handshake_outlined,
                                color: Color(0xFFD97706),
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (_newPhoto != null) {
                          setState(() => _newPhoto = null);
                        } else {
                          _pickNewPhoto();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: _newPhoto != null
                              ? AppColors.rose
                              : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _newPhoto != null ? Icons.close : Icons.camera_alt,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _newPhoto != null
                  ? 'ছবি পরিবর্তন করতে ট্যাপ করুন'
                  : 'প্রোফাইল ছবি যোগ করুন (ঐচ্ছিক)',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _newNameController,
              autofocus: true,
              onChanged: (_) {
                if (_inlineError != null) setState(() => _inlineError = null);
              },
              decoration: const InputDecoration(
                label: AppFieldLabel.inline(
                    label: 'রেফারেন্স ব্যক্তির নাম', isRequired: true),
                hintText: 'যেমন: কামাল হোসেন মেম্বার',
                prefixIcon: Icon(Icons.person_outline, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _newPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [BdPhoneInputFormatter()],
              onChanged: (_) {
                if (_inlineError != null) setState(() => _inlineError = null);
              },
              decoration: const InputDecoration(
                label: AppFieldLabel.inline(
                    label: 'মোবাইল নম্বর', isRequired: true),
                hintText: '০১৮১২৩৪৫৬৭৮',
                prefixIcon: Icon(Icons.phone_android, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _newAddressController,
              decoration: const InputDecoration(
                labelText: 'ঠিকানা / এলাকা (ঐচ্ছিক)',
                hintText: 'যেমন: ভাটপাড়া, সাভার',
                prefixIcon: Icon(Icons.location_on_outlined, size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _newNotesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'নোট বা মন্তব্য (ঐচ্ছিক)',
                hintText: 'পরিচিতি বা কাজের বিবরণ',
                prefixIcon: Icon(Icons.notes, size: 18),
              ),
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.roseSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.roseLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppColors.roseDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _inlineError!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.roseDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: _isSaving ? null : _saveAndSelectNewReference,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('সংরক্ষণ ও নির্বাচন করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
