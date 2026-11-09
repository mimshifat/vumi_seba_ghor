import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_floating_button.dart';
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
              TextField(
                controller: nameController,
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
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
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
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('নাম এবং মোবাইল নম্বর আবশ্যক'),
                              backgroundColor: AppColors.rose,
                            ),
                          );
                          return;
                        }

                        try {
                          await ref
                              .read(referenceControllerProvider.notifier)
                              .createReference(
                                name: name,
                                phone: phone,
                                address: addressController.text.trim().isNotEmpty
                                    ? addressController.text.trim()
                                    : null,
                                notes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                              );

                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('রেফারেন্স ব্যক্তি "$name" সফলভাবে যোগ হয়েছে'),
                              backgroundColor: AppColors.emerald,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          final msg = e is AppFailure
                              ? e.message
                              : 'রেফারেন্স ব্যক্তি যোগ করা যায়নি।';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
                          );
                        }
                      },
                      child: const Text('সংরক্ষণ করুন'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
