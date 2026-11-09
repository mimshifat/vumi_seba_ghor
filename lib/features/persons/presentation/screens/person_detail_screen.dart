import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../applications/presentation/widgets/application_card.dart';
import '../providers/person_providers.dart';
import 'person_create_edit_screen.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  final dynamic person; // Person or DemoPerson
  final String? personId;

  const PersonDetailScreen({
    super.key,
    this.person,
    this.personId,
  });

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  String get _id {
    if (widget.personId != null) return widget.personId!;
    if (widget.person is Person) return (widget.person as Person).id;
    if (widget.person is DemoPerson) return (widget.person as DemoPerson).id;
    return '';
  }

  Future<void> _confirmDelete(BuildContext context, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'গ্রাহক মুছে ফেলা',
        message: 'আপনি কি নিশ্চিত এই ব্যক্তির তথ্য মুছে ফেলতে চান? যদি তার কোনো ফাইল থাকে তবে তা কেবল লুকানো হবে।',
        confirmText: 'হ্যাঁ, মুছুন',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;

    try {
      final wasDeleted =
          await ref.read(personControllerProvider.notifier).deletePerson(_id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasDeleted == true
              ? '$name এর তথ্য সফলভাবে মুছে ফেলা হয়েছে।'
              : '$name এর তথ্য নিষ্ক্রিয় করা হয়েছে।'),
          backgroundColor: AppColors.emerald,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppFailure ? e.message : 'ব্যক্তি মুছতে সমস্যা হয়েছে।';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final livePersonAsync = ref.watch(personDetailProvider(_id));
    final livePerson = livePersonAsync.valueOrNull;

    // Fallbacks
    final name = livePerson?.name ??
        (widget.person is Person
            ? (widget.person as Person).name
            : (widget.person is DemoPerson ? (widget.person as DemoPerson).name : 'গ্রাহক'));
    final phone = livePerson?.phone ??
        (widget.person is Person
            ? (widget.person as Person).phone
            : (widget.person is DemoPerson ? (widget.person as DemoPerson).phone : ''));
    final address = livePerson?.address ??
        (widget.person is Person
            ? (widget.person as Person).address
            : (widget.person is DemoPerson ? (widget.person as DemoPerson).address : null));
    final notes = livePerson?.notes ??
        (widget.person is Person
            ? (widget.person as Person).notes
            : (widget.person is DemoPerson ? (widget.person as DemoPerson).notes : null));

    // Live applications for this person
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? [];
    final matchingApps = allApps.where((appWithFin) {
      final a = appWithFin.application;
      return a.applicantId == _id ||
          a.applicantPhone == phone ||
          a.applicantName == name;
    }).toList();

    // Financial summaries
    int totalAgreedPaisa = 0;
    int totalPaidPaisa = 0;
    int totalDuePaisa = 0;

    for (final appWithFin in matchingApps) {
      totalAgreedPaisa += appWithFin.agreed.paisa;
      totalPaidPaisa += appWithFin.received.paisa;
      totalDuePaisa += appWithFin.effectiveDue.paisa;
    }

    final totalAgreed = Money.fromPaisa(totalAgreedPaisa);
    final totalPaid = Money.fromPaisa(totalPaidPaisa);
    final totalDue = Money.fromPaisa(totalDuePaisa);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'সম্পাদনা',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => PersonCreateEditScreen(
                    person: livePerson ?? widget.person,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.rose),
            tooltip: 'মুছে ফেলুন',
            onPressed: () => _confirmDelete(context, name),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : 'গ',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  name,
                  style: AppTypography.headingMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android, size: 16, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      BengaliDigits.toBengali(phone),
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk, size: 18, color: AppColors.emerald),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$phone নম্বরে কল করা হচ্ছে...')),
                        );
                      },
                    ),
                  ],
                ),
                if (address != null && address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.slate400),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          address,
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      notes,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Person's Financial Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('মোট চুক্তি', totalAgreed.formatBengali(), AppColors.textPrimary),
                Container(height: 30, width: 1, color: AppColors.border),
                _buildStat(
                  'পরিশোধিত',
                  totalPaid.formatBengali(),
                  AppColors.emerald,
                ),
                Container(height: 30, width: 1, color: AppColors.border),
                _buildStat(
                  'মোট বকেয়া',
                  totalDue.formatBengali(),
                  totalDue.isPositive ? AppColors.rose : AppColors.emerald,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Connected Applications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'যুক্ত আবেদনসমূহ (${BengaliDigits.toBengali(matchingApps.length)})',
                style: AppTypography.headingSmall.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (matchingApps.isEmpty)
            const EmptyState(
              icon: Icons.folder_open,
              title: 'কোনো আবেদন নেই',
              message: 'এই ব্যক্তির নামে এখনো কোনো আবেদন তৈরি করা হয়নি।',
            )
          else
            ...matchingApps.map((appWithFin) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.base),
                  child: ApplicationCard(
                    application: appWithFin.toDemoApplication(),
                    onRefresh: () => setState(() {}),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.moneyMedium.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
