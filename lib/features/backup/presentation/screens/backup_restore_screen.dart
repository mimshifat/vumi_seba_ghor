import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog_action_row.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../main.dart';
import '../providers/backup_providers.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  final _botTokenController = TextEditingController();
  final _chatIdController = TextEditingController();
  bool _isExportingPhone = false;
  bool _isExportingTelegram = false;
  bool _isImporting = false;

  @override
  void dispose() {
    _botTokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  // ১. ফোনে সুরক্ষিত অফলাইন ব্যাকআপ এক্সপোর্ট
  Future<void> _exportBackupToPhone() async {
    setState(() => _isExportingPhone = true);
    try {
      final file =
          await ref.read(backupControllerProvider.notifier).exportToPhone();
      if (!mounted) return;

      if (file != null) {
        final fileName = p.basename(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('ব্যাকআপ ফাইলটি সেভ হয়েছে: $fileName'),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final failure = AppFailure.fromException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingPhone = false);
    }
  }

  // ২. ফাইল থেকে ডেটাবেজ রিস্টোর (জিরো ডাটা লস ও ব্যাকগ্রাউন্ড ইন্টিগ্রিটি চেক)
  Future<void> _importBackupFromPhone() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'ব্যাকআপ ফাইল নির্বাচন করুন',
      );

      if (result == null || result.files.isEmpty) return;

      final pickedPath = result.files.first.path;
      if (pickedPath == null) return;
      final file = File(pickedPath);
      if (!file.existsSync()) return;

      if (!mounted) return;
      setState(() => _isImporting = true);

      // ব্যাকগ্রাউন্ড আইসোলেটে ফাইল পরীক্ষা (Zero-Freeze & Anti-Corruption)
      final validation = await ref
          .read(backupControllerProvider.notifier)
          .validateFile(pickedPath);

      if (!mounted) return;
      setState(() => _isImporting = false);

      if (validation == null || !validation.isValid) {
        final failure = AppFailure.corruptBackup(validation?.errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // ফাইল সারাংশ ও বিস্তারিত প্রদর্শন করে কনফার্মেশন ডায়ালগ
      final fileSizeKb =
          (validation.fileSizeBytes / 1024).toStringAsFixed(1);
      final sizeBn = BengaliDigits.toBengali(fileSizeKb);
      final appsBn = BengaliDigits.toBengali(validation.totalApplications);
      final paysBn = BengaliDigits.toBengali(validation.totalPayments);
      final expsBn = BengaliDigits.toBengali(validation.totalExpenses);

      final confirmed = await ConfirmDialog.show(
        context,
        title: 'ডেটা রিস্টোর করবেন?',
        message: 'নির্বাচিত ফাইল: ${p.basename(pickedPath)} ($sizeBn KB)\n\n'
            'ফাইলের সংরক্ষিত তথ্য:\n'
            '• মোট আবেদন: $appsBn টি\n'
            '• মোট জমা রসিদ: $paysBn টি\n'
            '• মোট খরচ ভাউচার: $expsBn টি\n\n'
            'এই ফাইল থেকে সমস্ত তথ্য পুনরুদ্ধার করা হবে। বর্তমান তথ্যের একটি নিরাপত্তা ব্যাকআপ রাখা হবে। আপনি কি নিশ্চিত?',
        confirmText: 'হ্যাঁ, রিস্টোর করুন',
        isDestructive: true,
        icon: Icons.restore_page_outlined,
      );

      if (confirmed != true || !mounted) return;

      setState(() => _isImporting = true);

      // মূল রিস্টোর প্রক্রিয়া (Automatic Swap & Rollback Safety)
      await ref.read(backupControllerProvider.notifier).restoreFromFile(
        pickedPath,
        onDatabaseReopened: (newDb) {
          rootAppKey.currentState?.replaceDatabase(newDb);
        },
      );

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
      final failure = AppFailure.fromException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ৩. টেলিগ্রাম ক্লাউড ব্যাকআপ
  Future<void> _exportBackupToTelegram() async {
    final savedToken = ref.read(telegramBotTokenStreamProvider).valueOrNull;
    final savedChatId = ref.read(telegramChatIdStreamProvider).valueOrNull;

    final token = _botTokenController.text.trim().isNotEmpty
        ? _botTokenController.text.trim()
        : (savedToken ?? '');
    final chatId = _chatIdController.text.trim().isNotEmpty
        ? _chatIdController.text.trim()
        : (savedChatId ?? '');

    if (token.isEmpty || chatId.isEmpty) {
      _showTelegramConfigDialog();
      return;
    }

    setState(() => _isExportingTelegram = true);
    try {
      await ref.read(backupControllerProvider.notifier).exportToTelegram(
            botToken: token,
            chatId: chatId,
          );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('টেলিগ্রাম বটে ক্লাউড ব্যাকআপ সফলভাবে পাঠানো হয়েছে!'),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final failure = AppFailure.fromException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingTelegram = false);
    }
  }

  // টেলিগ্রাম বট কনফিগ ডায়ালগ
  void _showTelegramConfigDialog() {
    final savedToken = ref.read(telegramBotTokenStreamProvider).valueOrNull;
    final savedChatId = ref.read(telegramChatIdStreamProvider).valueOrNull;

    if (_botTokenController.text.isEmpty && savedToken != null) {
      _botTokenController.text = savedToken;
    }
    if (_chatIdController.text.isEmpty && savedChatId != null) {
      _chatIdController.text = savedChatId;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
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
        actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        actions: [
          AppDialogActionRow(
            confirmText: 'সংরক্ষণ',
            onConfirm: () async {
              final token = _botTokenController.text.trim();
              final chatId = _chatIdController.text.trim();
              await ref
                  .read(backupControllerProvider.notifier)
                  .saveTelegramConfig(
                    botToken: token,
                    chatId: chatId,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('টেলিগ্রাম বট সেটিংস সংরক্ষিত হয়েছে'),
                    backgroundColor: AppColors.emerald,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastBackupTime =
        ref.watch(lastBackupTimeStreamProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ডেটা ব্যাকআপ ও রিস্টোর'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // ১. হিরো স্ট্যাটাস কার্ড (সান্ত্বনাদায়ক ও স্পষ্ট)
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
                  child: const Icon(Icons.shield_outlined,
                      color: AppColors.emeraldDark, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'আপনার ডেটা সম্পূর্ণ নিরাপদ',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastBackupTime != null && lastBackupTime.isNotEmpty
                            ? 'সর্বশেষ ব্যাকআপ: $lastBackupTime'
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

          // ২. ডিভাইস ব্যাকআপ ও ফাইল রিস্টোর সেকশন
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.file_download_outlined,
                        color: Color(0xFF4F46E5), size: 22),
                  ),
                  title: const Text('ফোনে ব্যাকআপ নিন',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Downloads ফোল্ডারে ফাইল সেভ হবে',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.folder_open_outlined,
                        color: Color(0xFFD97706), size: 22),
                  ),
                  title: const Text('ফাইল থেকে রিস্টোর',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('পূর্বে সংরক্ষিত ফাইল বাছুন',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
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

          // ৩. টেলিগ্রাম ক্লাউড ব্যাকআপ
          _buildSectionHeader('টেলিগ্রাম ক্লাউড ব্যাকআপ'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // প্রতিদিন স্বয়ংক্রিয় ব্যাকআপ টগল
                Consumer(
                  builder: (context, ref, child) {
                    final isAutoBackup = ref
                            .watch(autoBackupTelegramStreamProvider)
                            .valueOrNull ??
                        false;
                    final lastAutoBackupDate = ref
                        .watch(lastTelegramAutoBackupDateStreamProvider)
                        .valueOrNull;

                    return SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base, vertical: 4),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(Icons.autorenew_rounded,
                            color: Color(0xFF2563EB), size: 22),
                      ),
                      title: const Text(
                        'প্রতিদিন স্বয়ংক্রিয় ব্যাকআপ',
                        style: TextStyle(
                            fontSize: 14.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'সাইজ হালকা রাখতে দলিলের ভারী পিডিএফ বাদ দিয়ে শুধু আবেদন ও আর্থিক হিসাব ক্লাউডে পাঠানো হবে।',
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.textMuted),
                          ),
                          if (lastAutoBackupDate != null &&
                              lastAutoBackupDate.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                'আজকের স্ট্যাটাস: ব্যাকআপ সম্পন্ন ($lastAutoBackupDate)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.emeraldDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      value: isAutoBackup,
                      activeColor: AppColors.primary,
                      onChanged: (val) async {
                        final token = ref
                            .read(telegramBotTokenStreamProvider)
                            .valueOrNull;
                        final chatId = ref
                            .read(telegramChatIdStreamProvider)
                            .valueOrNull;

                        if (val &&
                            (token == null ||
                                token.isEmpty ||
                                chatId == null ||
                                chatId.isEmpty)) {
                          _showTelegramConfigDialog();
                          return;
                        }

                        await ref
                            .read(backupControllerProvider.notifier)
                            .setAutoBackupTelegram(val);
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                // ম্যানুয়াল ব্যাকআপ পাঠান
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFF0284C7), size: 22),
                  ),
                  title: const Text('টেলিগ্রামে এখনই পাঠান',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: GestureDetector(
                    onTap: _showTelegramConfigDialog,
                    child: const Text(
                      'বট সেটিংস কনফিগার করুন ⚙️',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.w500),
                    ),
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
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // আশ্বস্তকরণ বার্তা
          Center(
            child: Text(
              'ফোন পরিবর্তন করলেও ব্যাকআপ ফাইলের মাধ্যমে সব ডেটা ফিরে পাবেন।',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted, fontSize: 11.5),
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
