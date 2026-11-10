import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/database_seeder.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/app_launcher.dart';
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../backup/presentation/screens/backup_restore_screen.dart';
import '../providers/settings_providers.dart';
import 'category_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _useBengaliDigits = true;

  void _showEditShopProfileDialog({
    required String currentShopName,
    required String currentProprietorName,
    required String currentShopPhone,
    required String currentShopAddress,
  }) {
    final nameCtrl = TextEditingController(text: currentShopName);
    final ownerCtrl = TextEditingController(text: currentProprietorName);
    final phoneCtrl = TextEditingController(text: currentShopPhone);
    final addressCtrl = TextEditingController(text: currentShopAddress);

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
                  inputFormatters: [BdPhoneInputFormatter()],
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
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final owner = ownerCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final address = addressCtrl.text.trim();

                          if (name.isEmpty) return;
                          final phoneErr = AppValidators.validatePhone(phone);
                          if (phoneErr != null) {
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                              SnackBar(
                                content: Text(phoneErr),
                                backgroundColor: AppColors.rose,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          final cleanPhone = AppValidators.standardizePhone(phone);

                          try {
                            final ctrl = ref.read(shopSettingsControllerProvider.notifier);
                            await ctrl.setSetting('shop_name', name);
                            await ctrl.setSetting('proprietor_name', owner);
                            await ctrl.setSetting('shop_phone', cleanPhone);
                            await ctrl.setSetting('shop_address', address);

                            // Sync DemoStore as memory fallback
                            DemoStore.shopName = name;
                            DemoStore.proprietorName = owner;
                            DemoStore.shopPhone = cleanPhone;
                            DemoStore.shopAddress = address;

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('প্রতিষ্ঠানের তথ্য সফলভাবে সংরক্ষিত হয়েছে'),
                                backgroundColor: AppColors.emerald,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            final msg = e is AppFailure ? e.message : 'সেটিংস সংরক্ষণ করা যায়নি।';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
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
            _buildContactRow(
              ctx,
              Icons.phone,
              'হটলাইন নম্বর (কল করতে চাপুন)',
              '+৮৮০ ১৮০০-০০০০০০',
              onTap: () => AppLauncher.makePhoneCall(ctx, '+8801800000000'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildContactRow(
              ctx,
              Icons.chat_bubble_outline,
              'হোয়াটসঅ্যাপ সাপোর্ট (চ্যাট করতে চাপুন)',
              '+৮৮০ ১৭০০-০০০০০০',
              onTap: () => AppLauncher.launchWeb(ctx, 'https://wa.me/8801700000000'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildContactRow(
              ctx,
              Icons.schedule,
              'সময়সূচি',
              'সকাল ৯:০০ - রাত ৯:০০',
            ),
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

  static Widget _buildContactRow(
    BuildContext context,
    IconData icon,
    String title,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
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
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }

  void _showResetDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('অ্যাপ ফ্রেশ ও ডেটা রিসেট'),
        content: const Text(
          'আপনি কি সব আবেদন, ব্যক্তি ও পরীক্ষামূলক লেনদেন মুছে ফেলে অ্যাপ সম্পূর্ণ ফ্রেশ করতে চান?\n\n'
          '⚠️ এতে শুধু কাজের খাত, ভূমি অফিস ও শপ সেটিংস অক্ষত থাকবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final db = ref.read(appDatabaseProvider);
                await DatabaseSeeder.clearAllDemoData(db);
                await DatabaseSeeder.seedEssentialDefaults(db);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('সকল ডেটা মুছে অ্যাপ সম্পূর্ণ ফ্রেশ করা হয়েছে'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ত্রুটি হয়েছে: $e'),
                      backgroundColor: AppColors.rose,
                    ),
                  );
                }
              }
            },
            child: const Text('হ্যাঁ, ফ্রেশ করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(shopSettingsStreamProvider);
    final settings = settingsAsync.valueOrNull ?? {};

    final shopName = settings['shop_name'] ?? 'রজব ভূমি সেবা ঘর';
    final proprietorName = settings['proprietor_name'] ?? '';
    final shopPhone = settings['shop_phone'] ?? '';
    final shopAddress = settings['shop_address'] ?? '';

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
                        shopName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$proprietorName • $shopPhone',
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
                  onPressed: () => _showEditShopProfileDialog(
                    currentShopName: shopName,
                    currentProprietorName: proprietorName,
                    currentShopPhone: shopPhone,
                    currentShopAddress: shopAddress,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 2. Business Management Category
          _buildCategoryHeader('ব্যবসা ব্যবস্থাপনা'),
          const SizedBox(height: AppSpacing.xs),
          _buildSettingsTile(
            icon: Icons.category_outlined,
            title: 'ক্যাটাগরি ও খাত ব্যবস্থাপনা',
            subtitle: 'কাজের ধরন ও খরচের খাত পরিচালনা',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const CategoryManagementScreen()),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'মানি রিসিট ও ভাউচার লেআউট',
            subtitle: 'প্রিন্ট রশিদ ফরম্যাট ও ফুটনোট বার্তা',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Text('ডিফল্ট', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('পরবর্তী আপডেটে এই ফিচারটি সক্রিয় হবে')),
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // 3. Data & Privacy
          _buildCategoryHeader('ডেটা ও নিরাপত্তা'),
          const SizedBox(height: AppSpacing.xs),
          _buildSettingsTile(
            icon: Icons.cloud_sync_outlined,
            title: 'ব্যাকআপ ও রিস্টোর',
            subtitle: 'লোকাল ফাইল ও গুগল ড্রাইভ সংরক্ষণ',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const BackupRestoreScreen()),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'অ্যাপ লক ও বায়োমেট্রিক',
            subtitle: 'ফিঙ্গারপ্রিন্ট বা পিন নম্বর সুরক্ষা',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Text('নিষ্ক্রিয়', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('বায়োমেট্রিক সুবিধা শিগগিরই যুক্ত হচ্ছে')),
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // 4. App Preferences
          _buildCategoryHeader('ব্যবহার ও পছন্দ'),
          const SizedBox(height: AppSpacing.xs),
          _buildSettingsTile(
            icon: Icons.translate,
            title: 'সংখ্যা প্রদর্শন পদ্ধতি',
            subtitle: _useBengaliDigits ? 'বাংলা সংখ্যায় (১২৩৪৫)' : 'ইংরেজি সংখ্যায় (12345)',
            trailing: Switch.adaptive(
              value: _useBengaliDigits,
              activeTrackColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _useBengaliDigits = val);
              },
            ),
            onTap: () {
              setState(() => _useBengaliDigits = !_useBengaliDigits);
            },
          ),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'সহায়তা ও যোগাযোগ',
            subtitle: 'সমস্যা ও পরামর্শ জানাতে কল বা মেসেজ করুন',
            onTap: _showSupportDialog,
          ),
          _buildSettingsTile(
            icon: Icons.cleaning_services_outlined,
            title: 'অ্যাপ ফ্রেশ ও ডেটা রিসেট',
            subtitle: 'সব ডেমো ও পরীক্ষামূলক তথ্য মুছে একদম নতুন শুরু করুন',
            onTap: _showResetDataDialog,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  'ভূমি কাজের হিসাব • সংস্করণ ১.০.০',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'কাস্টমাইজড সফটওয়্যার ফর ল্যান্ড সার্ভিস সেন্টার',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: AppColors.slate700, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11.5),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.slate400, size: 20),
      ),
    );
  }
}
