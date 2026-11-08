import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';

class OfficeManagementScreen extends StatefulWidget {
  const OfficeManagementScreen({super.key});

  @override
  State<OfficeManagementScreen> createState() => _OfficeManagementScreenState();
}

class _OfficeManagementScreenState extends State<OfficeManagementScreen> {
  void _showAddEditDialog([DemoOffice? office]) {
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (isEditing) {
                    final idx = DemoStore.offices.indexWhere((o) => o.id == office.id);
                    if (idx != -1) {
                      DemoStore.offices[idx] = DemoOffice(
                        id: office.id,
                        name: text,
                        activeApplications: office.activeApplications,
                      );
                    }
                  } else {
                    DemoStore.offices.add(
                      DemoOffice(
                        id: 'off-${DateTime.now().millisecondsSinceEpoch}',
                        name: text,
                      ),
                    );
                  }
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(isEditing ? 'সংরক্ষণ' : 'যোগ করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = DemoStore.offices;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ভূমি অফিস তালিকা'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add_business),
        label: const Text('নতুন অফিস'),
      ),
      body: list.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_outlined,
              title: 'কোনো অফিস সংরক্ষিত নেই',
              message: 'নতুন অফিসের নাম যোগ করুন।',
              actionText: 'নতুন অফিস যোগ করুন',
              onAction: () => _showAddEditDialog(),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 80),
              itemCount: list.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final off = list[i];
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
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.account_balance, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              off.name,
                              style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'চলমান কাজ: ${BengaliDigits.toBengali(off.activeApplications)} টি',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.slate500),
                        tooltip: 'সম্পাদনা',
                        onPressed: () => _showAddEditDialog(off),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.rose),
                        tooltip: 'মুছুন',
                        onPressed: () async {
                          final ok = await ConfirmDialog.show(
                            context,
                            title: 'অফিস মুছবেন?',
                            message: '${off.name} তালিকা থেকে মুছে ফেলা হবে।',
                            confirmText: 'মুছুন',
                            isDestructive: true,
                          );
                          if (ok == true) {
                            setState(() {
                              DemoStore.offices.removeWhere((o) => o.id == off.id);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

