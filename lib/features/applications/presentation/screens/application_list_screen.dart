import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../offices/presentation/providers/office_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/application_providers.dart';
import '../widgets/application_card.dart';
import 'application_create_screen.dart';

class ApplicationListScreen extends ConsumerStatefulWidget {
  final String? initialStatusFilter;

  const ApplicationListScreen({super.key, this.initialStatusFilter});

  @override
  ConsumerState<ApplicationListScreen> createState() =>
      _ApplicationListScreenState();
}

class _ApplicationListScreenState extends ConsumerState<ApplicationListScreen> {
  final _searchController = TextEditingController();
  late FilterCriteria _criteria;

  @override
  void initState() {
    super.initState();
    _criteria = FilterCriteria(selectedStatus: widget.initialStatusFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialStatusFilter != null) {
        ref
            .read(applicationFilterProvider.notifier)
            .setQuickFilterKey(widget.initialStatusFilter);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterBottomSheet() {
    final workTypes = ref
            .read(workTypesStreamProvider)
            .valueOrNull
            ?.map((w) => w.name)
            .toList() ??
        DemoStore.workTypes;
    final offices = ref
            .read(officesStreamProvider)
            .valueOrNull
            ?.map((o) => o.name)
            .toList() ??
        DemoStore.offices.map((o) => o.name).toList();

    FilterBottomSheet.show(
      context,
      initialCriteria: _criteria,
      availableStatuses: DemoStore.statuses,
      availableWorkTypes: workTypes,
      availableOffices: offices,
      onApply: (updated) {
        setState(() {
          _criteria = updated;
        });
        ref.read(applicationFilterProvider.notifier).setCriteria(updated);
        if (updated.selectedStatus != null) {
          ref
              .read(applicationFilterProvider.notifier)
              .setQuickFilterKey(updated.selectedStatus);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];
    final filteredApps = ref.watch(filteredApplicationsProvider);
    final filterState = ref.watch(applicationFilterProvider);

    final ongoingCount = allApps
        .where((a) =>
            a.application.status != 'সম্পন্ন' &&
            a.application.status != 'নামঞ্জুর' &&
            a.application.status != 'বাতিল')
        .length;
    final hearingCount =
        allApps.where((a) => a.application.status == 'শুনানি').length;
    final dueCount = allApps.where((a) => a.effectiveDue.isPositive).length;
    final completedCount =
        allApps.where((a) => a.application.status == 'সম্পন্ন').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('সকল আবেদন ও ফাইল'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'নতুন আবেদন',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (ctx) => const ApplicationCreateScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: AppFloatingButton(
        label: 'নতুন আবেদন',
        icon: Icons.add,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (ctx) => const ApplicationCreateScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.sm),
            color: Colors.white,
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hint: 'গ্রাহক নাম, মোবাইল, আবেদন বা কেস নং...',
                  activeFilterCount: _criteria.activeCount,
                  onChanged: (val) {
                    ref
                        .read(applicationFilterProvider.notifier)
                        .setSearchQuery(val);
                  },
                  onClear: () {
                    _searchController.clear();
                    ref
                        .read(applicationFilterProvider.notifier)
                        .setSearchQuery('');
                  },
                  onFilterTap: _openFilterBottomSheet,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Fast High-Efficiency Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickFilterPill(
                        key: 'all',
                        label:
                            'সব (${BengaliDigits.toBengali(allApps.length)})',
                        color: AppColors.primary,
                        currentKey: filterState.quickFilterKey,
                      ),
                      _buildQuickFilterPill(
                        key: 'ongoing',
                        label:
                            'চলমান (${BengaliDigits.toBengali(ongoingCount)})',
                        color: AppColors.primary,
                        currentKey: filterState.quickFilterKey,
                      ),
                      _buildQuickFilterPill(
                        key: 'hearing',
                        label:
                            'শুনানি (${BengaliDigits.toBengali(hearingCount)})',
                        color: const Color(0xFF8B5CF6),
                        currentKey: filterState.quickFilterKey,
                      ),
                      _buildQuickFilterPill(
                        key: 'has_due',
                        label:
                            'বকেয়া আছে (${BengaliDigits.toBengali(dueCount)})',
                        color: AppColors.rose,
                        currentKey: filterState.quickFilterKey,
                      ),
                      _buildQuickFilterPill(
                        key: 'completed',
                        label:
                            'সম্পন্ন (${BengaliDigits.toBengali(completedCount)})',
                        color: AppColors.emerald,
                        currentKey: filterState.quickFilterKey,
                      ),
                      ...DemoStore.statuses
                          .where((s) => s != 'শুনানি' && s != 'সম্পন্ন')
                          .map((st) {
                        final cnt = allApps
                            .where((a) => a.application.status == st)
                            .length;
                        return _buildQuickFilterPill(
                          key: st,
                          label: '$st (${BengaliDigits.toBengali(cnt)})',
                          color: AppColors.getStatusColor(st),
                          currentKey: filterState.quickFilterKey,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active criteria indicator bar (when advanced filter used)
          if (_criteria.activeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: 8),
              color: AppColors.primarySurface,
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_criteria.selectedWorkType != null)
                            _buildActivePill(
                                'কাজের ধরন: ${_criteria.selectedWorkType}', () {
                              setState(() => _criteria.selectedWorkType = null);
                              ref
                                  .read(applicationFilterProvider.notifier)
                                  .setSelectedWorkType(null);
                            }),
                          if (_criteria.selectedOffice != null)
                            _buildActivePill(
                                'অফিস: ${_criteria.selectedOffice}', () {
                              setState(() => _criteria.selectedOffice = null);
                              ref
                                  .read(applicationFilterProvider.notifier)
                                  .setSelectedOffice(null);
                            }),
                          if (_criteria.dueStatus != null &&
                              _criteria.dueStatus != 'all')
                            _buildActivePill(
                              _criteria.dueStatus == 'has_due'
                                  ? 'বকেয়া আছে'
                                  : 'পরিশোধিত',
                              () {
                                setState(() => _criteria.dueStatus = 'all');
                                ref
                                    .read(applicationFilterProvider.notifier)
                                    .setDueStatus('all');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _criteria.clear();
                      });
                      ref
                          .read(applicationFilterProvider.notifier)
                          .clearFilters();
                    },
                    child: Text(
                      'রিসেট',
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.rose, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Count summary bar
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'মোট দেখানো হচ্ছে: ${BengaliDigits.toBengali(filteredApps.length)} টি ফাইল',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                InkWell(
                  onTap: _openFilterBottomSheet,
                  child: Row(
                    children: [
                      const Icon(Icons.sort, size: 14, color: AppColors.slate500),
                      const SizedBox(width: 4),
                      Text(
                        _getSortLabel(_criteria.sortBy),
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Application Cards List
          Expanded(
            child: filteredApps.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: 'কোনো আবেদন পাওয়া যায়নি',
                    message:
                        'অনুসন্ধানের শব্দ পরিবর্তন করুন অথবা ফিল্টার রিসেট করুন।',
                    actionText: 'সব ফিল্টার মুছুন',
                    onAction: () {
                      setState(() {
                        _searchController.clear();
                        _criteria.clear();
                      });
                      ref
                          .read(applicationFilterProvider.notifier)
                          .clearFilters();
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.base, 0, AppSpacing.base, 80),
                    itemCount: filteredApps.length,
                    separatorBuilder: (ctx, i) =>
                        const SizedBox(height: AppSpacing.base),
                    itemBuilder: (ctx, i) {
                      final item = filteredApps[i];
                      return ApplicationCard(
                        application: item.toDemoApplication(),
                        showFinancials: true,
                        onRefresh: () {
                          ref.invalidate(
                              applicationsWithFinancialsStreamProvider);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterPill({
    required String key,
    required String label,
    required Color color,
    required String? currentKey,
  }) {
    final isSelected = currentKey == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontFamily: AppTypography.fontFamily,
        ),
        backgroundColor: AppColors.slate100,
        selectedColor: color.withValues(alpha: 0.15),
        side: BorderSide(
          color: isSelected ? color : AppColors.border,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        onSelected: (_) {
          final nextKey = isSelected ? 'all' : key;
          ref
              .read(applicationFilterProvider.notifier)
              .setQuickFilterKey(nextKey);
          if (key != 'all' &&
              key != 'ongoing' &&
              key != 'hearing' &&
              key != 'has_due' &&
              key != 'completed') {
            setState(() {
              _criteria.selectedStatus = isSelected ? null : key;
            });
            ref
                .read(applicationFilterProvider.notifier)
                .setSelectedStatus(isSelected ? null : key);
          }
        },
      ),
    );
  }

  Widget _buildActivePill(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 12, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String key) {
    switch (key) {
      case 'oldest':
        return 'পুরাতন আগে';
      case 'due_desc':
        return 'সর্বোচ্চ বকেয়া';
      case 'name_asc':
        return 'নামের ক্রমে';
      default:
        return 'নতুন আগে';
    }
  }
}
