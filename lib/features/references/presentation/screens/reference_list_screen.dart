import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/attachment_picker_sheet.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../providers/reference_providers.dart';
import '../widgets/reference_card.dart';

class ReferenceListScreen extends ConsumerStatefulWidget {
  const ReferenceListScreen({super.key});

  @override
  ConsumerState<ReferenceListScreen> createState() => _ReferenceListScreenState();
}

class _ReferenceListScreenState extends ConsumerState<ReferenceListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddReferenceSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    Uint8List? selectedPhoto;
    var isPickingPhoto = false;
    var isSaving = false;
    String? inlineError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> pickPhoto() async {
            if (isPickingPhoto) return;
            isPickingPhoto = true;
            try {
              final picked = await AttachmentPickerSheet.pickImage(
                ctx,
                title: 'রেফারেন্স ব্যক্তির ছবি নির্বাচন করুন',
              );
              if (picked == null || !ctx.mounted) return;
              setModalState(() {
                selectedPhoto = picked.bytes;
              });
            } finally {
              isPickingPhoto = false;
            }
          }

          return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.base,
            right: AppSpacing.base,
            top: AppSpacing.base,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.base,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  'নতুন রেফারেন্স ব্যক্তি যোগ করুন',
                  style: AppTypography.headingSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'রেফারেন্স ব্যক্তির তথ্য সংরক্ষণ করুন (আবেদনকারী থেকে পৃথক):',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.base),
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: pickPhoto,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFEF3C7),
                            border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                          ),
                          child: selectedPhoto != null
                              ? ClipOval(
                                  child: Image.memory(
                                    selectedPhoto!,
                                    width: 76,
                                    height: 76,
                                    cacheWidth: 256,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.handshake_outlined,
                                        color: Color(0xFFD97706),
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.handshake_outlined,
                                    color: Color(0xFFD97706),
                                    size: 36,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            if (selectedPhoto != null) {
                              setModalState(() {
                                selectedPhoto = null;
                              });
                            } else {
                              pickPhoto();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: selectedPhoto != null ? AppColors.rose : AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              selectedPhoto != null ? Icons.close : Icons.camera_alt,
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
                Center(
                  child: Text(
                    selectedPhoto != null ? 'ছবি পরিবর্তন করতে ট্যাপ করুন' : 'প্রোফাইল ছবি যোগ করুন (ঐচ্ছিক)',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                TextField(
                  controller: nameController,
                  onChanged: (_) {
                    if (inlineError != null) {
                      setModalState(() => inlineError = null);
                    }
                  },
                  decoration: const InputDecoration(
                    label: AppFieldLabel.inline(label: 'রেফারেন্স ব্যক্তির নাম', isRequired: true),
                    hintText: 'যেমন: করিম মিয়া',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [BdPhoneInputFormatter()],
                  onChanged: (_) {
                    if (inlineError != null) {
                      setModalState(() => inlineError = null);
                    }
                  },
                  decoration: const InputDecoration(
                    label: AppFieldLabel.inline(label: 'মোবাইল নম্বর', isRequired: true),
                    hintText: '০১৭১১২২৩৩৪8',
                    prefixIcon: Icon(Icons.phone_android, size: 18),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'ঠিকানা',
                    hintText: 'গ্রাম/এলাকা, থানা, জেলা',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'নোট বা মন্তব্য',
                    hintText: 'পরিচিতি বা কাজের বিবরণ',
                    prefixIcon: Icon(Icons.notes, size: 18),
                  ),
                ),
                if (inlineError != null) ...[
                  const SizedBox(height: AppSpacing.md),
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
                            inlineError!,
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
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                        child: const Text('বাতিল'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final phone = phoneController.text.trim();
                                if (name.isEmpty || phone.isEmpty) {
                                  setModalState(() {
                                    inlineError = 'নাম এবং মোবাইল নম্বর আবশ্যক।';
                                  });
                                  return;
                                }
                                final phoneErr = AppValidators.validatePhone(phone);
                                if (phoneErr != null) {
                                  setModalState(() {
                                    inlineError = phoneErr;
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isSaving = true;
                                  inlineError = null;
                                });

                                try {
                                  final created = await ref
                                      .read(referenceControllerProvider.notifier)
                                      .createReference(
                                        name: name,
                                        phone: phone,
                                        address: addressController.text.trim().isNotEmpty
                                            ? addressController.text.trim()
                                            : null,
                                        photo: selectedPhoto,
                                        notes: notesController.text.trim().isNotEmpty
                                            ? notesController.text.trim()
                                            : null,
                                      );

                                  if (!ctx.mounted) return;
                                  if (created == null) {
                                    final failure =
                                        ref.read(referenceControllerProvider).error;
                                    final msg = failure is AppFailure
                                        ? failure.message
                                        : 'রেফারেন্স ব্যক্তি যোগ করা যায়নি।';
                                    setModalState(() {
                                      isSaving = false;
                                      inlineError = msg;
                                    });
                                    return;
                                  }

                                  Navigator.pop(ctx);
                                  if (!mounted) return;
                                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                    SnackBar(
                                      content: Text('রেফারেন্স ব্যক্তি "$name" সফলভাবে যোগ হয়েছে'),
                                      backgroundColor: AppColors.emerald,
                                    ),
                                  );
                                } catch (e) {
                                  final msg = e is AppFailure
                                      ? e.message
                                      : 'রেফারেন্স ব্যক্তি যোগ করা যায়নি।';
                                  if (ctx.mounted) {
                                    setModalState(() {
                                      isSaving = false;
                                      inlineError = msg;
                                    });
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('সংরক্ষণ করুন'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveRefsAsync = ref.watch(referencesStreamProvider);
    final List<Reference> dbRefs = liveRefsAsync.valueOrNull ?? [];

    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? [];

    final query = _searchQuery.trim().toLowerCase();
    final list = dbRefs.where((r) {
      if (query.isEmpty) return true;
      final matchName = r.name.toLowerCase().contains(query);
      final matchPhone = r.phone.contains(query);
      final matchAddress = r.address?.toLowerCase().contains(query) ?? false;
      return matchName || matchPhone || matchAddress;
    }).toList();

    // Sort by total applications descending
    list.sort((a, b) {
      final aCount = allApps.where((appWithFin) {
        final app = appWithFin.application;
        return (app.referenceId != null && app.referenceId == a.id) ||
            (app.referenceName?.trim() == a.name.trim());
      }).length;

      final bCount = allApps.where((appWithFin) {
        final app = appWithFin.application;
        return (app.referenceId != null && app.referenceId == b.id) ||
            (app.referenceName?.trim() == b.name.trim());
      }).length;

      return bCount.compareTo(aCount);
    });

    int totalReferredApps = 0;
    for (final r in dbRefs) {
      totalReferredApps += allApps.where((appWithFin) {
        final app = appWithFin.application;
        return (app.referenceId != null && app.referenceId == r.id) ||
            (app.referenceName?.trim() == r.name.trim());
      }).length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('রেফারেন্স খাতা'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
            tooltip: 'নতুন রেফারেন্স',
            onPressed: _showAddReferenceSheet,
          ),
        ],
      ),
      floatingActionButton: AppFloatingButton(
        label: 'নতুন রেফারেন্স',
        icon: Icons.person_add_alt_1,
        onPressed: _showAddReferenceSheet,
      ),
      body: Column(
        children: [
          // Search & Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'রেফারেন্স ব্যক্তির নাম, ফোন বা ঠিকানা দিয়ে খুঁজুন...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'মোট রেফারেন্স ব্যক্তি: ${BengaliDigits.toBengali(list.length.toString())} জন',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'রেফারকৃত মোট কাজ: ${BengaliDigits.toBengali(totalReferredApps.toString())}টি',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // List
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'কোনো রেফারেন্স ব্যক্তি পাওয়া যায়নি',
                    message: 'নতুন রেফারেন্স যুক্ত করতে নিচের বোতামে চাপ দিন।',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base,
                      AppSpacing.xs,
                      AppSpacing.base,
                      88,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      return ReferenceCard(reference: list[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
