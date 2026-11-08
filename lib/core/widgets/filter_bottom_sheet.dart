import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import 'app_button.dart';

class FilterCriteria {
  String? selectedStatus;
  String? selectedWorkType;
  String? selectedOffice;
  String? dueStatus; // 'all', 'has_due', 'paid'
  String sortBy; // 'newest', 'oldest', 'due_desc', 'name_asc'

  FilterCriteria({
    this.selectedStatus,
    this.selectedWorkType,
    this.selectedOffice,
    this.dueStatus = 'all',
    this.sortBy = 'newest',
  });

  int get activeCount {
    int count = 0;
    if (selectedStatus != null && selectedStatus!.isNotEmpty) count++;
    if (selectedWorkType != null && selectedWorkType!.isNotEmpty) count++;
    if (selectedOffice != null && selectedOffice!.isNotEmpty) count++;
    if (dueStatus != null && dueStatus != 'all') count++;
    if (sortBy != 'newest') count++;
    return count;
  }

  void clear() {
    selectedStatus = null;
    selectedWorkType = null;
    selectedOffice = null;
    dueStatus = 'all';
    sortBy = 'newest';
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterCriteria initialCriteria;
  final List<String> availableStatuses;
  final List<String> availableWorkTypes;
  final List<String> availableOffices;
  final ValueChanged<FilterCriteria> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.availableStatuses,
    required this.availableWorkTypes,
    required this.availableOffices,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required FilterCriteria initialCriteria,
    required List<String> availableStatuses,
    required List<String> availableWorkTypes,
    required List<String> availableOffices,
    required ValueChanged<FilterCriteria> onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => FilterBottomSheet(
        initialCriteria: initialCriteria,
        availableStatuses: availableStatuses,
        availableWorkTypes: availableWorkTypes,
        availableOffices: availableOffices,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterCriteria _criteria;

  @override
  void initState() {
    super.initState();
    _criteria = FilterCriteria(
      selectedStatus: widget.initialCriteria.selectedStatus,
      selectedWorkType: widget.initialCriteria.selectedWorkType,
      selectedOffice: widget.initialCriteria.selectedOffice,
      dueStatus: widget.initialCriteria.dueStatus,
      sortBy: widget.initialCriteria.sortBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.base,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'আবেদন ফিল্টার ও বাছাই',
                        style: AppTypography.headingSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _criteria.clear();
                      });
                    },
                    child: Text(
                      'রিসেট',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.rose,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _buildSectionTitle('কাজের অবস্থা (Status)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableStatuses.map((st) {
                      final isSelected = _criteria.selectedStatus == st;
                      final color = AppColors.getStatusColor(st);
                      return ChoiceChip(
                        label: Text(st),
                        selected: isSelected,
                        onSelected: (sel) {
                          setState(() {
                            _criteria.selectedStatus = sel ? st : null;
                          });
                        },
                        selectedColor: color.withValues(alpha: 0.18),
                        backgroundColor: AppColors.slate100,
                        labelStyle: TextStyle(
                          color: isSelected ? color : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 12.5,
                          fontFamily: AppTypography.fontFamily,
                        ),
                        side: BorderSide(
                          color: isSelected ? color : AppColors.border,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('কাজের ধরন (Work Type)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableWorkTypes.map((wt) {
                      final isSelected = _criteria.selectedWorkType == wt;
                      return ChoiceChip(
                        label: Text(wt),
                        selected: isSelected,
                        onSelected: (sel) {
                          setState(() {
                            _criteria.selectedWorkType = sel ? wt : null;
                          });
                        },
                        selectedColor: AppColors.primarySurface,
                        backgroundColor: AppColors.slate100,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 12.5,
                          fontFamily: AppTypography.fontFamily,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('অফিস (Office)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableOffices.map((off) {
                      final isSelected = _criteria.selectedOffice == off;
                      return ChoiceChip(
                        label: Text(off),
                        selected: isSelected,
                        onSelected: (sel) {
                          setState(() {
                            _criteria.selectedOffice = sel ? off : null;
                          });
                        },
                        selectedColor: AppColors.primarySurface,
                        backgroundColor: AppColors.slate100,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 12.5,
                          fontFamily: AppTypography.fontFamily,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('বকেয়া অবস্থা'),
                  Row(
                    children: [
                      _buildDueStatusChip('all', 'সকল আবেদন'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildDueStatusChip('has_due', 'বকেয়া আছে'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildDueStatusChip('paid', 'পরিশোধিত'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('সাজানোর ক্রম (Sort By)'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip('newest', 'নতুন আবেদন আগে'),
                      _buildSortChip('oldest', 'পুরাতন আগে'),
                      _buildSortChip('due_desc', 'সর্বোচ্চ বকেয়া'),
                      _buildSortChip('name_asc', 'নামের ক্রমানুসারে'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            // Bottom Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppButton(
                text: 'ফিল্টার প্রয়োগ করুন',
                icon: Icons.check,
                onPressed: () {
                  widget.onApply(_criteria);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDueStatusChip(String key, String label) {
    final isSelected = _criteria.dueStatus == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _criteria.dueStatus = key),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : AppColors.slate100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String key, String label) {
    final isSelected = _criteria.sortBy == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) setState(() => _criteria.sortBy = key);
      },
      selectedColor: AppColors.primarySurface,
      backgroundColor: AppColors.slate100,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 12.5,
        fontFamily: AppTypography.fontFamily,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
    );
  }
}

