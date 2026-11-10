import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_launcher.dart';
import '../../../applications/presentation/screens/proposal_print_queue_screen.dart';
import '../../../backup/presentation/screens/backup_restore_screen.dart';
import '../../../offices/presentation/screens/office_management_screen.dart';
import '../../../persons/presentation/screens/person_list_screen.dart';
import '../../../references/presentation/screens/reference_list_screen.dart';
import '../../../settings/presentation/screens/category_management_screen.dart';
import '../../../tasks/presentation/screens/task_list_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('মেনু ও অন্যান্য ব্যবস্থা'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // 1. Daily Ledgers & Management
          _buildMenuSection(
            title: 'দৈনিক ব্যবস্থাপনা ও খাতা',
            items: [
              _MenuItem(
                title: 'প্রস্তাব প্রেরণ PDF তালিকা',
                subtitle: 'নতুন কেস নম্বর PDF প্রিন্ট ও পূর্বের ব্যাচ',
                icon: Icons.picture_as_pdf_outlined,
                color: AppColors.rose,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => const ProposalPrintQueueScreen(),
                    ),
                  );
                },
              ),
              _MenuItem(
                title: 'করণীয় কাজ ও শিডিউল',
                subtitle: 'দৈনিক শিডিউল, শুনানি ও কাজের রিমাইন্ডার',
                icon: Icons.checklist_rtl,
                color: AppColors.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const TaskListScreen()),
                  );
                },
              ),
              _MenuItem(
                title: 'গ্রাহক ও ব্যক্তি খাতা',
                subtitle: 'সকল আবেদনকারী গ্রাহকের রেকর্ড ও যোগাযোগ',
                icon: Icons.people_outline,
                color: AppColors.emerald,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const PersonListScreen()),
                  );
                },
              ),
              _MenuItem(
                title: 'রেফারেন্স খাতা',
                subtitle: 'রেফারেন্স ব্যক্তি ও তাদের মাধ্যমে আসা আবেদন',
                icon: Icons.handshake_outlined,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const ReferenceListScreen()),
                  );
                },
              ),
              _MenuItem(
                title: 'ভূমি অফিস তালিকা',
                subtitle: 'উপজেলা ও ইউনিয়ন ভূমি অফিসের নাম সংরক্ষণ',
                icon: Icons.account_balance_outlined,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const OfficeManagementScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.base),

          // 2. Configurations & Data Backup
          _buildMenuSection(
            title: 'কনফিগারেশন ও ব্যাকআপ',
            items: [
              _MenuItem(
                title: 'কাজের ধরন ও খরচের খাত',
                subtitle: 'সেবার ধরন ও খরচের খাতের তালিকা পরিচালনা',
                icon: Icons.category_outlined,
                color: const Color(0xFF4F46E5),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const CategoryManagementScreen()),
                  );
                },
              ),
              _MenuItem(
                title: 'ডেটা ব্যাকআপ ও রিস্টোর',
                subtitle: 'ফোনে ব্যাকআপ ফাইল ডাউনলোড ও আপলোড',
                icon: Icons.backup_outlined,
                color: const Color(0xFF0284C7),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const BackupRestoreScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 3. Clean Developer & App Info Footer
          Center(
            child: Column(
              children: [
                const Text(
                  'রজব ভূমি সেবা ঘর • সংস্করণ ১.০.০',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.code_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'ডেভেলপার: Md Mim Shifat',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                InkWell(
                  onTap: () => AppLauncher.launchWeb(context, 'mailto:mimshifat5@gmail.com'),
                  onLongPress: () => AppLauncher.copyToClipboard(
                    context,
                    'mimshifat5@gmail.com',
                    successMessage: 'ইমেইল ঠিকানা কপি করা হয়েছে',
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'mimshifat5@gmail.com',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<_MenuItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final it = items[i];
              return ListTile(
                onTap: it.onTap,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: it.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(it.icon, color: it.color, size: 20),
                ),
                title: Text(
                  it.title,
                  style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(it.subtitle, style: AppTypography.bodySmall),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.slate400),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
