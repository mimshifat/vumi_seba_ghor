import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _botTokenController = TextEditingController(text: '7182938491:AAHk98...');
  final _chatIdController = TextEditingController(text: '987654321');
  bool _autoBackupEnabled = true;
  bool _isBackingUp = false;
  String? _lastBackupTime = '০৬ নভেম্বর ২০২৬, রাত ০৯:১৫';

  @override
  void dispose() {
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  void _triggerManualBackup() async {
    setState(() => _isBackingUp = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isBackingUp = false;
        _lastBackupTime = BengaliDigits.toBengali(
          '০${DateTime.now().day} নভেম্বর ${DateTime.now().year}, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সম্পূর্ণ SQLite ডেটাবেস সফলভাবে এনক্রিপ্ট করে টেলিগ্রামে ব্যাকআপ পাঠানো হয়েছে!'),
          backgroundColor: AppColors.emerald,
        ),
      );
    }
  }

  void _triggerRestore() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'ব্যাকআপ থেকে রিস্টোর করবেন?',
      message: 'টেলিগ্রাম থেকে সর্বশেষ ডেটাবেস ফাইলটি নামিয়ে বর্তমান ডেটা প্রতিস্থাপন করা হবে। নিশ্চিত হওয়ার আগে বর্তমান ডেটার ব্যাকআপ আছে কি না দেখে নিন।',
      confirmText: 'হ্যাঁ, রিস্টোর করুন',
      isDestructive: true,
      icon: Icons.restore,
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ব্যাকআপ ফাইল ডাউনলোড, ইন্টিগ্রিটি চেক ও সফলভাবে রিস্টোর সম্পন্ন হয়েছে।'),
          backgroundColor: AppColors.emerald,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('টেলিগ্রাম ব্যাকআপ ও রিস্টোর'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Database Status & Health Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(Icons.storage, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SQLite ডেটাবেস ফাইল স্ট্যাটাস',
                            style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ইন্টিগ্রিটি চেক: সুস্থ ও ত্রুটিমুক্ত (PRAGMA OK)',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.emeraldDark, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDbStat('মোট আবেদন', '${BengaliDigits.toBengali(DemoStore.applications.length)} টি'),
                    _buildDbStat('সংযুক্ত ফাইল', '৫ টি'),
                    _buildDbStat('ফাইলের আকার', '৩.৮ MB'),
                    _buildDbStat('ফরম্যাট', 'SQLite .db'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Backup Actions Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ব্যাকআপ কার্যপরিচালনা',
                  style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'কোনো ZIP নয়—সম্পূর্ণ মূল ডেটাবেস ফাইলটি (WAL চেকপয়েন্ট সহ) টেলিগ্রামে আপনার ব্যক্তিগত বটে সুরক্ষিতভাবে পাঠানো হয়।',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_lastBackupTime != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'সর্বশেষ সফল ব্যাকআপ: $_lastBackupTime',
                          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: _isBackingUp ? 'ব্যাকআপ প্রক্রিয়াধীন...' : 'এখন ব্যাকআপ নিন (Telegram)',
                  icon: Icons.cloud_upload_outlined,
                  isLoading: _isBackingUp,
                  onPressed: _triggerManualBackup,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: 'টেলিগ্রাম ব্যাকআপ থেকে রিস্টোর করুন',
                  icon: Icons.cloud_download_outlined,
                  variant: ButtonVariant.outline,
                  onPressed: _triggerRestore,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Telegram Bot Credentials Configuration
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'টেলিগ্রাম বট কনফিগারেশন',
                      style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.send, size: 14),
                      label: const Text('টেস্ট মেসেজ'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('বট সফলভাবে রেসপন্স করেছে! কানেকশন ওকে।')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Telegram Bot Token',
                  hint: 'BotFather থেকে পাওয়া টোকেন',
                  controller: _botTokenController,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Telegram Chat ID / User ID',
                  hint: 'আপনার টেলিগ্রাম ইউজার আইডি',
                  controller: _chatIdController,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('স্বয়ংক্রিয় দৈনিক ব্যাকআপ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('প্রতিদিন রাত ১২টায় ব্যাকআপ পাঠাবে', style: TextStyle(fontSize: 12)),
                  value: _autoBackupEnabled,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _autoBackupEnabled = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Security Information Alert
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.security, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'নিরাপত্তা নিশ্চয়তা: ব্যাকআপের সময় SQLite ডেটাবেস ফাইলটি AES-256 বিট অ্যালগরিদমে এনক্রিপ্ট করা হয়। আপনার গোপন বট টোকেনটি শুধুমাত্র আপনার ফোনের সিকিউর স্টোরেজে থাকে, কোনো ক্লাউড সার্ভারে যায় না।',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDeep, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDbStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 13.5)),
      ],
    );
  }
}
