import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/widgets/app_field_label.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _addCustomWorkType() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন কাজের ধরন'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'কাজের নাম', isRequired: true),
            hintText: 'যেমন: বাটোয়ারা বা খাস জমি বন্দোবস্ত',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => DemoStore.workTypes.add(controller.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
  }

  void _addExpenseCategory() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন খরচের খাত'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            label: AppFieldLabel.inline(label: 'খাতের নাম', isRequired: true),
            hintText: 'যেমন: আপ্যায়ন বা কম্পিউটার মেরামত',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => DemoStore.expenseCategories.add(controller.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('যোগ করুন'),
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
        title: const Text('সেটিংস ও কাস্টমাইজেশন'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Section 1: Work Types Customization
          _buildSettingsCard(
            title: 'কাজের ধরনের তালিকা (Work Types)',
            subtitle: 'আবেদন এন্ট্রির সময় এই তালিকা থেকে নির্বাচন করা হয়:',
            action: TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('নতুন যোগ করুন'),
              onPressed: _addCustomWorkType,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DemoStore.workTypes.map((wt) {
                return Chip(
                  label: Text(wt),
                  backgroundColor: AppColors.slate100,
                  side: const BorderSide(color: AppColors.border),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => DemoStore.workTypes.remove(wt));
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Section 2: Expense Categories Customization
          _buildSettingsCard(
            title: 'খরচের খাতের তালিকা (Expense Categories)',
            subtitle: 'খরচ এন্ট্রির সময় এই খাতগুলো ব্যবহৃত হয়:',
            action: TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('নতুন খাত'),
              onPressed: _addExpenseCategory,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DemoStore.expenseCategories.map((cat) {
                return Chip(
                  label: Text(cat),
                  backgroundColor: AppColors.roseSurface,
                  side: const BorderSide(color: AppColors.roseLight),
                  deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.rose),
                  onDeleted: () {
                    setState(() => DemoStore.expenseCategories.remove(cat));
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Section 3: App Info & About
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Image.asset(
                          'assets/images/app_logo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'রজব ভূমি সেবা ঘর',
                            style: AppTypography.headingSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            'সংস্করণ ১.০.০ • সম্পূর্ণ অফলাইন ফার্স্ট অ্যাপ্লিকেশন',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('ডেটাবেস ইঞ্জিন'),
                  trailing: Text('SQLite (Drift)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('বাংলা ফন্ট ফ্যামিলি'),
                  trailing: Text('Noto Sans Bengali (Bundled)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('ডেটাবেস ব্যাকআপ ইঞ্জিন'),
                  trailing: Text('Telegram Bot API (AES-256)', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required Widget action,
    required Widget child,
  }) {
    return Container(
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
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              action,
            ],
          ),
          Text(subtitle, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
