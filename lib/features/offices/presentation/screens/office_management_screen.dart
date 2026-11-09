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
            hintText: 'যেমন: উপজেলা ভূমি অফিস, সাভার',
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
        title: const Text('ভূমি অফিস তালিকা'),
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
                            const SizedBox(height: 2),
                            Text(
                              'চলমান কাজ: ${BengaliDigits.toBengali(activeAppsCount.toString())} টি',
                              style: AppTypography.bodySmall,
                            ),
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
