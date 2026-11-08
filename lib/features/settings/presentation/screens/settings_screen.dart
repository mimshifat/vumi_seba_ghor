import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../backup/presentation/screens/backup_restore_screen.dart';
import 'category_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useBengaliDigits = true;

  void _showEditShopProfileDialog() {
    final nameCtrl = TextEditingController(text: DemoStore.shopName);
    final ownerCtrl = TextEditingController(text: DemoStore.proprietorName);
    final phoneCtrl = TextEditingController(text: DemoStore.shopPhone);
    final addressCtrl = TextEditingController(text: DemoStore.shopAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'প্রতিষ্ঠানের তথ্য সম্পাদনা',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.base),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    label: AppFieldLabel.inline(label: 'প্রতিষ্ঠানের নাম', isRequired: true),
                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: ownerCtrl,
                  decoration: const InputDecoration(
                    label: AppFieldLabel.inline(label: 'স্বত্বাধিকারী / পরিচালকের নাম', isRequired: true),
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    label: AppFieldLabel.inline(label: 'মোবাইল নম্বর', isRequired: true),
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    label: AppFieldLabel.inline(label: 'দোকানের ঠিকানা', isRequired: true),
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'বাতিল',
                        variant: ButtonVariant.outline,
                        height: 42,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        text: 'সংরক্ষণ করুন',
                        height: 42,
                        onPressed: () {
                          if (nameCtrl.text.trim().isNotEmpty) {
                            setState(() {
                              DemoStore.shopName = nameCtrl.text.trim();
                              DemoStore.proprietorName = ownerCtrl.text.trim();
                              DemoStore.shopPhone = phoneCtrl.text.trim();
                              DemoStore.shopAddress = addressCtrl.text.trim();
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('প্রতিষ্ঠানের তথ্য সফলভাবে সংরক্ষিত হয়েছে'),
                                backgroundColor: AppColors.emerald,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('সহায়তা ও যোগাযোগ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'অ্যাপ ব্যবহারে কোনো সহায়তা লাগলে নির্দ্বিধায় যোগাযোগ করুন:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildContactRow(Icons.phone, 'হটলাইন নম্বর', '+৮৮০ ১৮০০-০০০০০০'),
            const SizedBox(height: AppSpacing.sm),
            _buildContactRow(Icons.chat_bubble_outline, 'হোয়াটসঅ্যাপ সাপোর্ট', '+৮৮০ ১৭০০-০০০০০০'),
            const SizedBox(height: AppSpacing.sm),
            _buildContactRow(Icons.schedule, 'সময়সূচি', 'সকাল ৯:০০ - রাত ৯:০০'),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'ঠিক আছে',
              height: 42,
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildContactRow(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('সেটিংস ও পছন্দ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // 1. Compact Shop Profile Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.storefront, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DemoStore.shopName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DemoStore.proprietorName} • ${DemoStore.shopPhone}',
                        style: AppTypography.bodySmall.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                  tooltip: 'সম্পাদনা করুন',
                  onPressed: _showEditShopProfileDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // 2. Business Configuration & Data
          _buildSectionHeader('কনফিগারেশন ও ডেটা'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: Color(0xFF4F46E5), size: 22),
                  title: const Text(
                    'কাজের ধরন ও খরচের খাত',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'সেবার ধরন ও খরচের তালিকা পরিচালনা',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.slate400),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const CategoryManagementScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_outlined, color: Color(0xFF0284C7), size: 22),
                  title: const Text(
                    'ডেটা ব্যাকআপ ও রিস্টোর',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'ফোনে ব্যাকআপ ফাইল ডাউনলোড ও আপলোড',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.slate400),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const BackupRestoreScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // 3. General Preferences
          _buildSectionHeader('অ্যাপের সাধারণ পছন্দ'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              secondary: const Icon(Icons.translate_rounded, color: AppColors.primary, size: 22),
              title: const Text(
                'বাংলা সংখ্যা প্রদর্শন (১, ২, ৩)',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'টাকা ও হিসাবের সংখ্যা বাংলায় দেখানো হবে',
                style: AppTypography.bodySmall,
              ),
              value: _useBengaliDigits,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _useBengaliDigits = val),
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // 4. Help & About Info
          _buildSectionHeader('সহায়তা ও তথ্য'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.headset_mic_outlined, color: AppColors.emerald, size: 22),
                  title: const Text(
                    'সহায়তা কেন্দ্র ও হেল্পলাইন',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'যেকোনো প্রয়োজনে আমাদের সাথে যোগাযোগ করুন',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.slate400),
                  onTap: _showSupportDialog,
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.slate600, size: 22),
                  title: Text(
                    'অ্যাপ সংস্করণ',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    '১.০.০',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Reassuring footer note
          const Center(
            child: Text(
              'রজব ভূমি সেবা ঘর • ১০০% অফলাইন ও নিরাপদ সলিউশন',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
