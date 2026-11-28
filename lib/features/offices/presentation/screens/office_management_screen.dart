import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_dialog_action_row.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../providers/office_providers.dart';

class OfficeManagementScreen extends ConsumerStatefulWidget {
  const OfficeManagementScreen({super.key});

  @override
  ConsumerState<OfficeManagementScreen> createState() =>
      _OfficeManagementScreenState();
}

class _OfficeManagementScreenState
    extends ConsumerState<OfficeManagementScreen> {
  void _showAddMouzaDialog(String officeName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('নতুন মৌজা যোগ করুন ($officeName)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'মৌজার নাম', isRequired: true),
            hintText: 'যেমন: বাগবাড়ী (জে.এল নং ৪৫)',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          AppDialogActionRow(
            confirmText: 'যুক্ত করুন',
            onConfirm: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                await ref
                    .read(officeControllerProvider.notifier)
                    .addCustomMouza(
                      officeName: officeName,
                      mouzaName: text,
                    );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('নতুন মৌজা "$text" যুক্ত হয়েছে।'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  void _showEditMouzaDialog(String officeName, String oldMouzaName) {
    final controller = TextEditingController(text: oldMouzaName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মৌজার নাম পরিবর্তন'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'মৌজার নাম', isRequired: true),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          AppDialogActionRow(
            confirmText: 'সংরক্ষণ',
            onConfirm: () async {
              final text = controller.text.trim();
              if (text.isEmpty || text == oldMouzaName) {
                Navigator.pop(ctx);
                return;
              }
              try {
                await ref
                    .read(officeControllerProvider.notifier)
                    .updateMouza(
                      officeName: officeName,
                      oldMouzaName: oldMouzaName,
                      newMouzaName: text,
                    );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('মৌজার নাম পরিবর্তন করে "$text" করা হয়েছে।'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMouza(String officeName, String mouzaName) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'মৌজা মুছবেন?',
      message: '"$mouzaName" এই অফিসের তালিকা থেকে মুছে ফেলা হবে।',
      confirmText: 'মুছুন',
      isDestructive: true,
    );

    if (ok != true) return;

    try {
      await ref.read(officeControllerProvider.notifier).deleteMouza(
            officeName: officeName,
            mouzaName: mouzaName,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('মৌজা "$mouzaName" মুছে ফেলা হয়েছে।'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (_) {}
  }

  void _showMouzaListSheet(Office office) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filter = '';
        return Consumer(
          builder: (context, ref, _) {
            final mouzas = ref.watch(mouzasForOfficeProvider(office.name));
            final customMap =
                ref.watch(customMouzasStreamProvider).valueOrNull ?? {};
            final customMouzas = customMap[office.name.trim()] ?? [];

            return StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = filter.trim().isEmpty
                    ? mouzas
                    : mouzas
                        .where((m) => m
                            .toLowerCase()
                            .contains(filter.trim().toLowerCase()))
                        .toList();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.slate300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    office.name,
                                    style: AppTypography.headingSmall
                                        .copyWith(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'মোট ${BengaliDigits.toBengali(mouzas.length.toString())}টি মৌজা',
                                    style: AppTypography.bodySmall
                                        .copyWith(color: AppColors.slate500),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                _showAddMouzaDialog(office.name);
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('নতুন মৌজা'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                textStyle: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'মৌজা খুঁজুন...',
                            prefixIcon: const Icon(Icons.search,
                                size: 20, color: AppColors.slate400),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                          onChanged: (val) => setSheetState(() => filter = val),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'কোনো মৌজা পাওয়া যায়নি',
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: AppColors.slate400),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, index) {
                                  final m = filtered[index];
                                  final isCustom = customMouzas.contains(m);

                                  return ListTile(
                                    leading: Icon(
                                      isCustom
                                          ? Icons.bookmark_add_outlined
                                          : Icons.map_outlined,
                                      size: 20,
                                      color: isCustom
                                          ? AppColors.emerald
                                          : AppColors.primary,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(m,
                                              style: AppTypography.bodyMedium),
                                        ),
                                        if (isCustom)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.emerald
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: AppColors.emerald
                                                      .withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              'কাস্টম',
                                              style: AppTypography.labelMedium
                                                  .copyWith(
                                                color: AppColors.emerald,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 18,
                                              color: AppColors.slate500),
                                          tooltip: 'সম্পাদনা',
                                          onPressed: () =>
                                              _showEditMouzaDialog(
                                                  office.name, m),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: AppColors.rose),
                                          tooltip: 'মুছুন',
                                          onPressed: () => _deleteMouza(
                                              office.name, m),
                                        ),
                                      ],
                                    ),
                                    dense: true,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddEditDialog([Office? office]) {
    final controller = TextEditingController(text: office?.name ?? '');
    final isEditing = office != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'অফিসের নাম পরিবর্তন' : 'নতুন অফিস যোগ করুন'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'অফিসের নাম', isRequired: true),
            hintText: 'যেমন: উপজেলা ভূমি অফিস, চাঁপাইনবাবগঞ্জ সদর',
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          AppDialogActionRow(
            confirmText: isEditing ? 'সংরক্ষণ' : 'যোগ করুন',
            onConfirm: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              try {
                if (isEditing) {
                  await ref
                      .read(officeControllerProvider.notifier)
                      .updateOffice(id: office.id, name: text);

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('অফিসের নাম পরিবর্তন করা হয়েছে।'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                } else {
                  await ref
                      .read(officeControllerProvider.notifier)
                      .createOffice(name: text);

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('নতুন অফিস "$text" যুক্ত হয়েছে।'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                final msg = e is AppFailure
                    ? e.message
                    : 'অফিসের তথ্য সংরক্ষণ করা যায়নি।';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOffice(Office office) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'অফিস মুছবেন?',
      message:
          '${office.name} তালিকা থেকে মুছে ফেলা হবে। অতীতে যুক্ত আবেদনের অফিসের নাম সংরক্ষিত থাকবে।',
      confirmText: 'মুছুন',
      isDestructive: true,
    );

    if (ok != true) return;

    try {
      final wasDeleted =
          await ref.read(officeControllerProvider.notifier).deleteOffice(office.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasDeleted == true
              ? '${office.name} সফলভাবে মুছে ফেলা হয়েছে।'
              : '${office.name} নিষ্ক্রিয় করা হয়েছে।'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppFailure ? e.message : 'অফিস মুছতে সমস্যা হয়েছে।';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveOfficesAsync = ref.watch(officesStreamProvider);
    final offices = liveOfficesAsync.valueOrNull ?? [];

    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ভূমি অফিস ও মৌজা ব্যবস্থাপনা'),
      ),
      floatingActionButton: AppFloatingButton(
        onPressed: () => _showAddEditDialog(),
        icon: Icons.add_business,
        label: 'নতুন অফিস',
      ),
      body: offices.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_outlined,
              title: 'কোনো অফিস সংরক্ষিত নেই',
              message: 'নতুন অফিসের নাম যোগ করুন।',
              actionText: 'নতুন অফিস যোগ করুন',
              onAction: () => _showAddEditDialog(),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.base,
                AppSpacing.base,
                80,
              ),
              itemCount: offices.length,
              separatorBuilder: (ctx, i) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final off = offices[i];

                final activeAppsCount = allApps.where((a) {
                  final app = a.application;
                  final matches = app.officeId == off.id ||
                      app.officeName.trim() == off.name.trim();
                  final isDone = app.status == 'সম্পন্ন' ||
                      app.status == 'মঞ্জুর' ||
                      app.status == 'পাশ' ||
                      app.status == 'বাতিল' ||
                      app.status == 'খারিজ';
                  return matches && !isDone;
                }).length;

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.account_balance,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              off.name,
                              style: AppTypography.headingSmall.copyWith(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            () {
                              final mouzas = ref.watch(mouzasForOfficeProvider(off.name));
                              return Row(
                                children: [
                                  Text(
                                    'চলমান কাজ: ${BengaliDigits.toBengali(activeAppsCount.toString())} টি',
                                    style: AppTypography.bodySmall,
                                  ),
                                  const Text(' • ',
                                      style: TextStyle(color: AppColors.slate400)),
                                  InkWell(
                                    onTap: () => _showMouzaListSheet(off),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.map_outlined,
                                            size: 14, color: AppColors.primary),
                                        const SizedBox(width: 2),
                                        Text(
                                          'মৌজা: ${BengaliDigits.toBengali(mouzas.length.toString())} টি',
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }(),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 20, color: AppColors.slate500),
                        tooltip: 'সম্পাদনা',
                        onPressed: () => _showAddEditDialog(off),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: AppColors.rose),
                        tooltip: 'মুছুন',
                        onPressed: () => _deleteOffice(off),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
