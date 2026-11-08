import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/widgets/application_card.dart';
import 'person_create_edit_screen.dart';

class PersonDetailScreen extends StatefulWidget {
  final DemoPerson person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  late DemoPerson _person;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
  }

  List<DemoApplication> get _personApplications {
    return DemoStore.applications.where((a) {
      return a.applicantId == _person.id ||
          a.applicantName == _person.name ||
          a.applicantPhone == _person.phone;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final apps = _personApplications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_person.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => PersonCreateEditScreen(person: _person),
                ),
              ).then((updated) {
                if (updated is DemoPerson) {
                  setState(() => _person = updated);
                }
              });
            },
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
                    _person.name.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _person.name,
                  style: AppTypography.headingMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android, size: 16, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      BengaliDigits.toBengali(_person.phone),
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk, size: 18, color: AppColors.emerald),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${_person.phone} নম্বরে কল করা হচ্ছে...')),
                        );
                      },
                    ),
                  ],
                ),
                if (_person.address != null && _person.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.slate400),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _person.address!,
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_person.notes != null && _person.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      _person.notes!,
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
                _buildStat('মোট চুক্তি', _person.totalAgreed.formatBengali(), AppColors.textPrimary),
                Container(height: 30, width: 1, color: AppColors.border),
                _buildStat(
                  'পরিশোধিত',
                  (_person.totalAgreed - _person.totalDue).formatBengali(),
                  AppColors.emerald,
                ),
                Container(height: 30, width: 1, color: AppColors.border),
                _buildStat(
                  'মোট বকেয়া',
                  _person.totalDue.formatBengali(),
                  _person.totalDue.isPositive ? AppColors.rose : AppColors.emerald,
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
                'যুক্ত আবেদনসমূহ (${BengaliDigits.toBengali(apps.length)})',
                style: AppTypography.headingSmall.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (apps.isEmpty)
            const EmptyState(
              icon: Icons.folder_open,
              title: 'কোনো আবেদন নেই',
              message: 'এই ব্যক্তির নামে এখনো কোনো আবেদন তৈরি করা হয়নি।',
            )
          else
            ...apps.map((app) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.base),
                  child: ApplicationCard(
                    application: app,
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

