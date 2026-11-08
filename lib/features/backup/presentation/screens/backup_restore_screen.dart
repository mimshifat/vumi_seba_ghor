import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog_action_row.dart';
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
  bool _isExportingPhone = false;
  bool _isExportingTelegram = false;
  bool _isImporting = false;
  String? _lastBackupTime = '০৮ নভেম্বর ২০২৬, সকাল ১০:১৫';

  @override
  void dispose() {
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  // 1. Export Backup to Phone
  Future<void> _exportBackupToPhone() async {
    setState(() => _isExportingPhone = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    final now = DateTime.now();
    final fileName = 'rojob_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.db';

    setState(() {
      _isExportingPhone = false;
      _lastBackupTime = BengaliDigits.toBengali(
        '${now.day.toString().padLeft(2, '0')} নভেম্বর ${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ব্যাকআপ ফাইলটি Downloads ফোল্ডারে সেভ হয়েছে ($fileName)'),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 2. Import Backup from Phone
  Future<void> _importBackupFromPhone() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'ব্যাকআপ ফাইল নির্বাচন করুন',
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (!mounted) return;

      final confirmed = await ConfirmDialog.show(
        context,
        title: 'ডেটা রিস্টোর করবেন?',
        message: 'নির্বাচিত ফাইল: ${file.name}\n\nএই ব্যাকআপ ফাইলটি থেকে সমস্ত তথ্য পুনরুদ্ধার করা হবে। আপনি কি নিশ্চিত?',
        confirmText: 'হ্যাঁ, রিস্টোর করুন',
        isDestructive: true,
        icon: Icons.restore_page_outlined,
      );

      if (confirmed != true || !mounted) return;

      setState(() => _isImporting = true);
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;
      setState(() => _isImporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সফলভাবে সমস্ত ডেটা রিস্টোর সম্পন্ন হয়েছে!'),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ফাইল নির্বাচনে সমস্যা হয়েছে: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  // 3. Export to Telegram
  Future<void> _exportBackupToTelegram() async {
    setState(() => _isExportingTelegram = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final now = DateTime.now();
    setState(() {
      _isExportingTelegram = false;
      _lastBackupTime = BengaliDigits.toBengali(
        '${now.day.toString().padLeft(2, '0')} নভেম্বর ${now.year}, ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('টেলিগ্রাম বটে ক্লাউড ব্যাকআপ সফলভাবে পাঠানো হয়েছে!'),
        backgroundColor: AppColors.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Telegram Config Dialog
  void _showTelegramConfigDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: const Text('টেলিগ্রাম বট সেটিংস'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Telegram Bot Token',
              hint: 'BotFather থেকে পাওয়া টোকেন',
              controller: _botTokenController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Telegram Chat ID',
              hint: 'আপনার চ্যাট আইডি',
              controller: _chatIdController,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          AppDialogActionRow(
            confirmText: 'সংরক্ষণ',
            onConfirm: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('টেলিগ্রাম বট সেটিংস সংরক্ষিত হয়েছে')),
              );
            },
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
        title: const Text('ডেটা ব্যাকআপ ও রিস্টোর'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // 1. Hero Status Card (Simple & Reassuring)
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
                    color: AppColors.emeraldSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.emeraldDark, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'আপনার ডেটা সম্পূর্ণ নিরাপদ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _lastBackupTime != null
                            ? 'সর্বশেষ ব্যাকআপ: $_lastBackupTime'
                            : 'এখনও কোনো ব্যাকআপ নেওয়া হয়নি',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // 2. Main Action Card (Phone Export & Import)
          _buildSectionHeader('ডিভাইস ব্যাকআপ (অফলাইন)'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Export Tile
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.file_download_outlined, color: Color(0xFF4F46E5), size: 22),
                  ),
                  title: const Text('ফোনে ব্যাকআপ নিন', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Downloads ফোল্ডারে ফাইল সেভ হবে', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  trailing: AppButton(
                    text: 'ব্যাকআপ',
                    width: 92,
                    height: 36,
                    isLoading: _isExportingPhone,
                    onPressed: _exportBackupToPhone,
                  ),
                ),
                const Divider(height: 1),
                // Import Tile
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.folder_open_outlined, color: Color(0xFFD97706), size: 22),
                  ),
                  title: const Text('ফাইল থেকে রিস্টোর', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('পূর্বে সংরক্ষিত ফাইল বাছুন', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  trailing: AppButton(
                    text: 'ফাইল বাছুন',
                    variant: ButtonVariant.outline,
                    width: 92,
                    height: 36,
                    isLoading: _isImporting,
                    onPressed: _importBackupFromPhone,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // 3. Telegram Cloud Backup (Optional & Compact)
          _buildSectionHeader('ক্লাউড ব্যাকআপ (ঐচ্ছিক)'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.send_rounded, color: Color(0xFF0284C7), size: 22),
              ),
              title: const Text('টেলিগ্রাম ব্যাকআপ', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              subtitle: GestureDetector(
                onTap: _showTelegramConfigDialog,
                child: const Text('বট সেটিংস কনফিগার করুন ⚙️', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w500)),
              ),
              trailing: AppButton(
                text: 'পাঠান',
                variant: ButtonVariant.outline,
                width: 80,
                height: 36,
                isLoading: _isExportingTelegram,
                onPressed: _exportBackupToTelegram,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Simple Help Note
          Center(
            child: Text(
              'ফোন পরিবর্তন করলেও ব্যাকআপ ফাইলের মাধ্যমে সব ডেটা ফিরে পাবেন।',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
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
