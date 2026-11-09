import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/app_launcher.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../providers/person_providers.dart';
import 'person_create_edit_screen.dart';
import 'person_detail_screen.dart';

class PersonListScreen extends ConsumerStatefulWidget {
  const PersonListScreen({super.key});

  @override
  ConsumerState<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends ConsumerState<PersonListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final livePersonsAsync = ref.watch(personsStreamProvider);
    final livePersons = livePersonsAsync.valueOrNull;

    // Use live database persons if available; otherwise fallback to DemoStore
    final List<Person> dbPersons = livePersons ?? [];
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? [];

    // Filter persons by search query
    final filteredPersons = dbPersons.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.phone.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('গ্রাহক ও ব্যক্তি তালিকা'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
            tooltip: 'নতুন ব্যক্তি',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const PersonCreateEditScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: AppFloatingButton(
        label: 'নতুন ব্যক্তি',
        icon: Icons.person_add,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const PersonCreateEditScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'ব্যক্তির নাম বা মোবাইল নম্বর দিয়ে খুঁজুন...',
                prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Divider(),

          // Person count info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'মোট সংরক্ষিত ব্যক্তি: ${BengaliDigits.toBengali(filteredPersons.length)} জন',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: filteredPersons.isEmpty
                ? const EmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'কোনো ব্যক্তি পাওয়া যায়নি',
                    message: 'অন্য নামে বা নম্বরে খুঁজে দেখুন।',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, 80),
                    itemCount: filteredPersons.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      final p = filteredPersons[i];

                      // Calculate person stats from live applications
                      final personApps = allApps.where((appWithFin) {
                        final a = appWithFin.application;
                        return a.applicantId == p.id ||
                            a.applicantPhone == p.phone ||
                            a.applicantName == p.name;
                      }).toList();

                      final appCount = personApps.length;
                      int totalDuePaisa = 0;
                      for (final a in personApps) {
                        totalDuePaisa += a.effectiveDue.paisa;
                      }
                      final totalDue = Money.fromPaisa(totalDuePaisa);
                      final hasDue = totalDue.isPositive;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => PersonDetailScreen(
                                  person: p,
                                  personId: p.id,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.base),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primarySurface,
                                  child: Text(
                                    p.name.isNotEmpty ? p.name.substring(0, 1) : 'গ',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      InkWell(
                                        onTap: () => AppLauncher.makePhoneCall(
                                          context,
                                          p.phone,
                                          contactName: p.name,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Text(
                                          BengaliDigits.toBengali(p.phone),
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.slate100,
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                            ),
                                            child: Text(
                                              'আবেদন: ${BengaliDigits.toBengali(appCount)} টি',
                                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                            ),
                                          ),
                                          if (hasDue) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.roseSurface,
                                                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                              ),
                                              child: Text(
                                                'বকেয়া: ${totalDue.formatBengali()}',
                                                style: AppTypography.bodySmall.copyWith(
                                                  color: AppColors.rose,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone_in_talk, color: AppColors.emerald, size: 20),
                                  tooltip: 'কল করুন',
                                  onPressed: () => AppLauncher.makePhoneCall(
                                    context,
                                    p.phone,
                                    contactName: p.name,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
