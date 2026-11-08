import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../widgets/application_card.dart';
import 'application_create_screen.dart';

class ApplicationListScreen extends StatefulWidget {
  final String? initialStatusFilter;

  const ApplicationListScreen({super.key, this.initialStatusFilter});

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _quickFilterKey; // 'all', 'ongoing', 'hearing', 'has_due', 'completed', or specific status name
  late FilterCriteria _criteria;

  @override
  void initState() {
    super.initState();
    _quickFilterKey = widget.initialStatusFilter ?? 'all';
    _criteria = FilterCriteria(selectedStatus: widget.initialStatusFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DemoApplication> get _filteredApplications {
    return DemoStore.applications.where((app) {
      // 1. Search Query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = app.applicantName.toLowerCase().contains(q);
        final phoneMatch = app.applicantPhone.contains(q);
        final appNumMatch = app.appNumber != null && app.appNumber!.toLowerCase().contains(q);
        final caseNumMatch = app.caseNumber != null && app.caseNumber!.toLowerCase().contains(q);
        if (!nameMatch && !phoneMatch && !appNumMatch && !caseNumMatch) {
          return false;
        }
      }

      // 2. High-priority Quick Filter Chips
      if (_quickFilterKey != null && _quickFilterKey != 'all') {
        if (_quickFilterKey == 'ongoing') {
          if (app.status == 'সম্পন্ন' || app.status == 'নামঞ্জুর' || app.status == 'বাতিল') return false;
        } else if (_quickFilterKey == 'has_due') {
          if (!app.dueAmount.isPositive) return false;
        } else if (_quickFilterKey == 'hearing') {
          if (app.status != 'শুনানি') return false;
        } else if (_quickFilterKey == 'completed') {
          if (app.status != 'সম্পন্ন') return false;
        } else {
          // Specific status name
          if (app.status != _quickFilterKey) return false;
        }
      }

      // 3. Criteria from BottomSheet (if active)
      if (_criteria.selectedStatus != null && _criteria.selectedStatus!.isNotEmpty) {
        if (app.status != _criteria.selectedStatus) return false;
      }

      if (_criteria.selectedWorkType != null && _criteria.selectedWorkType!.isNotEmpty) {
        if (app.workType != _criteria.selectedWorkType) return false;
      }

      if (_criteria.selectedOffice != null && _criteria.selectedOffice!.isNotEmpty) {
        if (app.officeName != _criteria.selectedOffice) return false;
      }

      if (_criteria.dueStatus == 'has_due') {
        if (!app.dueAmount.isPositive) return false;
      } else if (_criteria.dueStatus == 'paid') {
        if (app.dueAmount.isPositive) return false;
      }

      return true;
    }).toList();
  }

  void _openFilterBottomSheet() {
    FilterBottomSheet.show(
      context,
      initialCriteria: _criteria,
      availableStatuses: DemoStore.statuses,
      availableWorkTypes: DemoStore.workTypes,
      availableOffices: DemoStore.offices.map((o) => o.name).toList(),
      onApply: (updated) {
        setState(() {
          _criteria = updated;
          if (updated.selectedStatus != null) {
            _quickFilterKey = updated.selectedStatus;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredApplications;

    final ongoingCount = DemoStore.applications
        .where((a) => a.status != 'সম্পন্ন' && a.status != 'নামঞ্জুর' && a.status != 'বাতিল')
        .length;
    final hearingCount = DemoStore.applications.where((a) => a.status == 'শুনানি').length;
    final dueCount = DemoStore.applications.where((a) => a.dueAmount.isPositive).length;
    final completedCount = DemoStore.applications.where((a) => a.status == 'সম্পন্ন').length;

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
                MaterialPageRoute(builder: (ctx) => const ApplicationCreateScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      floatingActionButton: AppFloatingButton(
        label: 'নতুন আবেদন',
        icon: Icons.add,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const ApplicationCreateScreen()),
          ).then((_) => setState(() {}));
        },
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.sm),
            color: Colors.white,
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hint: 'গ্রাহক নাম, মোবাইল, আবেদন বা কেস নং...',
                  activeFilterCount: _criteria.activeCount,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  onClear: () => setState(() => _searchQuery = ''),
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
                        label: 'সব (${BengaliDigits.toBengali(DemoStore.applications.length)})',
                        color: AppColors.primary,
                      ),
                      _buildQuickFilterPill(
                        key: 'ongoing',
                        label: 'চলমান (${BengaliDigits.toBengali(ongoingCount)})',
                        color: AppColors.primary,
                      ),
                      _buildQuickFilterPill(
                        key: 'hearing',
                        label: 'শুনানি (${BengaliDigits.toBengali(hearingCount)})',
                        color: const Color(0xFF8B5CF6),
                      ),
                      _buildQuickFilterPill(
                        key: 'has_due',
                        label: 'বকেয়া আছে (${BengaliDigits.toBengali(dueCount)})',
                        color: AppColors.rose,
                      ),
                      _buildQuickFilterPill(
                        key: 'completed',
                        label: 'সম্পন্ন (${BengaliDigits.toBengali(completedCount)})',
                        color: AppColors.emerald,
                      ),
                      ...DemoStore.statuses.where((s) => s != 'শুনানি' && s != 'সম্পন্ন').map((st) {
                        final cnt = DemoStore.applications.where((a) => a.status == st).length;
                        return _buildQuickFilterPill(
                          key: st,
                          label: '$st (${BengaliDigits.toBengali(cnt)})',
                          color: AppColors.getStatusColor(st),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 8),
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
                            _buildActivePill('কাজের ধরন: ${_criteria.selectedWorkType}', () {
                              setState(() => _criteria.selectedWorkType = null);
                            }),
                          if (_criteria.selectedOffice != null)
                            _buildActivePill('অফিস: ${_criteria.selectedOffice}', () {
                              setState(() => _criteria.selectedOffice = null);
                            }),
                          if (_criteria.dueStatus != null && _criteria.dueStatus != 'all')
                            _buildActivePill(
                              _criteria.dueStatus == 'has_due' ? 'বকেয়া আছে' : 'পরিশোধিত',
                              () => setState(() => _criteria.dueStatus = 'all'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _criteria.clear();
                        _quickFilterKey = 'all';
                      });
                    },
                    child: Text(
                      'রিসেট',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.rose, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Count summary bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'মোট দেখানো হচ্ছে: ${BengaliDigits.toBengali(list.length)} টি ফাইল',
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
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Application Cards List (With Financials visible safely in this list, or tap for detail)
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: 'কোনো আবেদন পাওয়া যায়নি',
                    message: 'অনুসন্ধানের শব্দ পরিবর্তন করুন অথবা ফিল্টার রিসেট করুন।',
                    actionText: 'সব ফিল্টার মুছুন',
                    onAction: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _quickFilterKey = 'all';
                        _criteria.clear();
                      });
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, 80),
                    itemCount: list.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: AppSpacing.base),
                    itemBuilder: (ctx, i) {
                      return ApplicationCard(
                        application: list[i],
                        showFinancials: true,
                        onRefresh: () => setState(() {}),
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
  }) {
    final isSelected = _quickFilterKey == key;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (sel) {
          setState(() {
            _quickFilterKey = sel ? key : 'all';
            if (sel && DemoStore.statuses.contains(key)) {
              _criteria.selectedStatus = key;
            } else if (key == 'all') {
              _criteria.selectedStatus = null;
            }
          });
        },
        selectedColor: isSelected ? color.withValues(alpha: 0.15) : AppColors.slate100,
        backgroundColor: AppColors.slate100,
        labelStyle: TextStyle(
          color: isSelected ? color : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 11.5,
          fontFamily: AppTypography.fontFamily,
        ),
        side: BorderSide(
          color: isSelected ? color : AppColors.border,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
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
            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
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
