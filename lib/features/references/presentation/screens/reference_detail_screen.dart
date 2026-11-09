import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_field_label.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../applications/presentation/widgets/application_card.dart';
import '../../domain/models/reference_stats.dart';
import '../providers/reference_providers.dart';
import '../widgets/reference_stats_row.dart';

class ReferenceDetailScreen extends ConsumerStatefulWidget {
  final dynamic reference; // Reference or DemoReference
  final String? referenceId;

  const ReferenceDetailScreen({
    super.key,
    this.reference,
    this.referenceId,
  });

  @override
  ConsumerState<ReferenceDetailScreen> createState() =>
      _ReferenceDetailScreenState();
}

class _ReferenceDetailScreenState
    extends ConsumerState<ReferenceDetailScreen> {
  String get _referenceId {
    if (widget.referenceId != null) return widget.referenceId!;
    if (widget.reference is Reference) return (widget.reference as Reference).id;
    if (widget.reference is DemoReference) {
      return (widget.reference as DemoReference).id;
    }
    return '';
  }

  void _showEditReferenceDialog(Reference current) {
    final nameController = TextEditingController(text: current.name);
    final phoneController = TextEditingController(text: current.phone);
    final addressController =
        TextEditingController(text: current.address ?? '');
    final notesController = TextEditingController(text: current.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.base,
          right: AppSpacing.base,
          top: AppSpacing.base,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.base,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'রেফারেন্স তথ্য সম্পাদনা',
                style: AppTypography.headingSmall
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.base),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  label: AppFieldLabel.inline(
                      label: 'রেফারেন্স ব্যক্তির নাম', isRequired: true),
                  hintText: 'যেমন: করিম মিয়া',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  label: AppFieldLabel.inline(
                      label: 'মোবাইল নম্বর', isRequired: true),
                  hintText: '০১৭১১২২৩৩৪8',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'ঠিকানা',
                  hintText: 'গ্রাম/এলাকা, থানা, জেলা',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'নোট বা মন্তব্য',
                  hintText: 'পরিচিতি বা কাজের বিবরণ',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('বাতিল'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        final newPhone = phoneController.text.trim();
                        if (newName.isEmpty || newPhone.isEmpty) return;

                        try {
                          await ref
                              .read(referenceControllerProvider.notifier)
                              .updateReference(
                                id: _referenceId,
                                name: newName,
                                phone: newPhone,
                                address:
                                    addressController.text.trim().isNotEmpty
                                        ? addressController.text.trim()
                                        : null,
                                notes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                              );

                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('রেফারেন্স তথ্য আপডেট করা হয়েছে'),
                              backgroundColor: AppColors.emerald,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          final msg = e is AppFailure
                              ? e.message
                              : 'রেফারেন্স আপডেট করা যায়নি।';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(msg),
                                backgroundColor: AppColors.rose),
                          );
                        }
                      },
                      child: const Text('সংরক্ষণ করুন'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'রেফারেন্স ব্যক্তি মুছে ফেলা',
        message:
            'আপনি কি নিশ্চিত এই রেফারেন্স ব্যক্তির তথ্য মুছে ফেলতে চান? অতীতে যুক্ত ফাইলের রেফারেন্স নাম সংরক্ষিত থাকবে।',
        confirmText: 'হ্যাঁ, মুছুন',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    try {
      final wasDeleted = await ref
          .read(referenceControllerProvider.notifier)
          .deleteReference(_referenceId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasDeleted == true
              ? '$name এর তথ্য মুছে ফেলা হয়েছে।'
              : '$name এর তথ্য নিষ্ক্রিয় করা হয়েছে।'),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.message
          : 'রেফারেন্স ব্যক্তি মুছতে সমস্যা হয়েছে।';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final refAsync = ref.watch(referenceDetailProvider(_referenceId));
    final liveRef = refAsync.valueOrNull;

    final name = liveRef?.name ??
        (widget.reference is Reference
            ? (widget.reference as Reference).name
            : (widget.reference is DemoReference
                ? (widget.reference as DemoReference).name
                : 'রেফারেন্স'));
    final phone = liveRef?.phone ??
        (widget.reference is Reference
            ? (widget.reference as Reference).phone
            : (widget.reference is DemoReference
                ? (widget.reference as DemoReference).phone
                : ''));
    final address = liveRef?.address ??
        (widget.reference is Reference
            ? (widget.reference as Reference).address
            : (widget.reference is DemoReference
                ? (widget.reference as DemoReference).address
                : null));
    final notes = liveRef?.notes ??
        (widget.reference is Reference
            ? (widget.reference as Reference).notes
            : (widget.reference is DemoReference
                ? (widget.reference as DemoReference).notes
                : null));

    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? [];

    final matchingApps = allApps.where((a) {
      final app = a.application;
      return (app.referenceId != null &&
              app.referenceId == _referenceId) ||
          (name.isNotEmpty &&
              app.referenceName != null &&
              app.referenceName!.trim() == name.trim());
    }).toList();

    final stats = ReferenceStats.fromApplications(matchingApps);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'সম্পাদনা',
            onPressed: () {
              if (liveRef != null) {
                _showEditReferenceDialog(liveRef);
              } else {
                _showEditReferenceDialog(Reference(
                  id: _referenceId,
                  name: name,
                  phone: phone,
                  address: address,
                  notes: notes,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                ));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.rose),
            tooltip: 'মুছে ফেলুন',
            onPressed: () => _confirmDelete(name),
          ),
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: AppColors.emerald),
            tooltip: 'কল করুন',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$name ($phone)-এ কল করা হচ্ছে...')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Profile Card
          _buildProfileCard(name: name, phone: phone, address: address, notes: notes),

          const SizedBox(height: AppSpacing.base),

          // Operational Status Breakdown
          _buildSectionHeader('আবেদনের বর্তমান অগ্রগতি', Icons.pie_chart_outline),
          const SizedBox(height: AppSpacing.sm),
          ReferenceStatsRow(stats: stats),

          const SizedBox(height: AppSpacing.base),

          // Financial Summary Card
          _buildFinancialSummaryCard(stats),

          const SizedBox(height: AppSpacing.lg),

          // Associated Applications Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                'যুক্ত আবেদনসমূহ (${BengaliDigits.toBengali(matchingApps.length.toString())})',
                Icons.folder_shared_outlined,
              ),
              if (matchingApps.isNotEmpty)
                Text(
                  'রেফারেন্সের হিস্টোরি',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Applications List
          if (matchingApps.isEmpty)
            const EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'কোনো আবেদন নেই',
              message:
                  'এই রেফারেন্স ব্যক্তির মাধ্যমে এখনও কোনো আবেদন এন্ট্রি করা হয়নি।',
            )
          else
            ...matchingApps.map(
              (appWithFin) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ApplicationCard(
                  application: appWithFin.toDemoApplication(),
                  onRefresh: () => setState(() {}),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String phone,
    String? address,
    String? notes,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLargeAvatar(),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTypography.headingMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        'রেফারেন্স',
                        style: AppTypography.labelMedium.copyWith(
                          color: const Color(0xFFD97706),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_android,
                        size: 15, color: AppColors.emerald),
                    const SizedBox(width: 6),
                    Text(
                      BengaliDigits.toBengali(phone),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (address != null && address.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppColors.slate400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
                if (notes != null && notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      border:
                          Border.all(color: AppColors.slate200, width: 0.8),
                    ),
                    child: Text(
                      notes,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: const Center(
        child: Icon(
          Icons.handshake_outlined,
          color: Color(0xFFD97706),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(ReferenceStats stats) {
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
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'রেফারেন্সভিত্তিক আর্থিক সারসংক্ষেপ',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildFinancialTile(
                  label: 'মোট সেবা মূল্য',
                  amount: stats.totalAgreed.formatBengali(),
                  color: AppColors.primary,
                  bgColor: AppColors.primarySurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildFinancialTile(
                  label: 'মোট আদায়',
                  amount: stats.totalReceived.formatBengali(),
                  color: AppColors.emerald,
                  bgColor: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildFinancialTile(
                  label: 'মোট বকেয়া',
                  amount: stats.totalDue.formatBengali(),
                  color: stats.totalDue.isPositive
                      ? AppColors.rose
                      : AppColors.slate600,
                  bgColor: stats.totalDue.isPositive
                      ? const Color(0xFFFFF1F2)
                      : AppColors.slate100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTile({
    required String label,
    required String amount,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }
}
