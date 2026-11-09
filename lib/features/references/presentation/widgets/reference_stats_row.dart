import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../domain/models/reference_stats.dart';

class ReferenceStatsRow extends StatelessWidget {
  final ReferenceStats stats;

  const ReferenceStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            label: 'মোট',
            count: stats.totalApplications,
            color: AppColors.primary,
            bgColor: AppColors.primarySurface,
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: _buildStatItem(
            label: 'সম্পন্ন',
            count: stats.completedCount,
            color: AppColors.emerald,
            bgColor: const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: _buildStatItem(
            label: 'চলমান',
            count: stats.ongoingCount,
            color: const Color(0xFF6366F1),
            bgColor: const Color(0xFFEEF2FF),
          ),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: _buildStatItem(
            label: 'অপেক্ষমাণ',
            count: stats.pendingCount,
            color: AppColors.amber,
            bgColor: const Color(0xFFFFFBEB),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            BengaliDigits.toBengali(count.toString()),
            style: AppTypography.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

