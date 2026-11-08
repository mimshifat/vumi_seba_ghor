import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../data/demo_reference_store.dart';
import '../screens/reference_detail_screen.dart';
import 'reference_stats_row.dart';

class ReferenceCard extends StatelessWidget {
  final DemoReference reference;
  final VoidCallback? onRefresh;

  const ReferenceCard({
    super.key,
    required this.reference,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final stats = ReferenceHelper.getStats(reference.id, reference.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ReferenceDetailScreen(reference: reference),
            ),
          ).then((_) => onRefresh?.call());
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Name, Phone & Call action
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reference.name,
                          style: AppTypography.headingSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_android, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              BengaliDigits.toBengali(reference.phone),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (reference.address != null && reference.address!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  reference.address!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_in_talk, size: 19, color: AppColors.emerald),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFECFDF5),
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${reference.name} (${reference.phone})-এ কল করা হচ্ছে...')),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Total service amount & applications count banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.slate200, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_shared_outlined, size: 15, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'মোট আবেদন: ${BengaliDigits.toBengali(stats.totalApplications.toString())}টি',
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'সেবা মূল্য: ${stats.totalAgreed.formatBengali()}',
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // 4 status breakdown chips
              ReferenceStatsRow(stats: stats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (reference.photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        child: Image.memory(
          reference.photo!,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: const Center(
        child: Icon(
          Icons.handshake_outlined,
          color: Color(0xFFD97706),
          size: 22,
        ),
      ),
    );
  }
}
