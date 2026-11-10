import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/case_number_formatter.dart';
import '../../../../core/widgets/copy_chip.dart';
import '../../../../core/widgets/status_badge.dart';
import '../screens/application_detail_screen.dart';

class ApplicationCard extends StatelessWidget {
  final DemoApplication application;
  final VoidCallback? onRefresh;
  final bool showFinancials;

  const ApplicationCard({
    super.key,
    required this.application,
    this.onRefresh,
    this.showFinancials = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(application.status);
    final hasDue = application.dueAmount.isPositive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.slate200, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ApplicationDetailScreen(application: application),
                ),
              ).then((_) => onRefresh?.call());
            },
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Stack(
              children: [
                // Visual status indicator accent on left edge
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusLg),
                        bottomLeft: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                  ),
                ),

                // Card Main Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base + 2,
                    AppSpacing.md + 2,
                    AppSpacing.base,
                    AppSpacing.base,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Applicant Name & Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  application.applicantName,
                                  style: AppTypography.headingSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.slate900,
                                    height: 1.25,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Category Tags: Work Type & Mouza
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                        border: Border.all(
                                          color: AppColors.primaryLight,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        application.workType,
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    if (application.mouza != null && application.mouza!.trim().isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.slate50,
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                          border: Border.all(color: AppColors.slate200, width: 0.8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 11,
                                              color: AppColors.slate500,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              'মৌজা: ${application.mouza!}',
                                              style: AppTypography.bodySmall.copyWith(
                                                color: AppColors.slate700,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge(status: application.status),
                        ],
                      ),

                      // Identifiers Row (Application & Case Number)
                      if ((application.appNumber != null && application.appNumber!.isNotEmpty) ||
                          (application.caseNumber != null && application.caseNumber!.isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (showFinancials &&
                                application.appNumber != null &&
                                application.appNumber!.isNotEmpty)
                              CopyChip(
                                label: 'আবেদন',
                                value: application.appNumber!,
                                prefixIcon: Icons.description_outlined,
                              ),
                            if (application.caseNumber != null && application.caseNumber!.isNotEmpty)
                              CopyChip(
                                label: 'কেস',
                                value: CaseNumberFormatter.formatDisplay(
                                  application.caseNumber,
                                ),
                                prefixIcon: Icons.tag,
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Office and Date line with clean metadata styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.slate100),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_outlined,
                              size: 13.5,
                              color: AppColors.slate500,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                application.officeName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.slate700,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12.5,
                              color: AppColors.slate400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              BengaliDigits.toBengali(
                                '${application.applicationDate.day}/${application.applicationDate.month}/${application.applicationDate.year}',
                              ),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.slate500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Financial Summary Inset Bar
                      if (showFinancials) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.9),
                          ),
                          child: Row(
                            children: [
                              // Column 1: Agreed Amount (চুক্তি)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'চুক্তি',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 10.5,
                                        color: AppColors.slate500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        application.agreedAmount.formatBengali(),
                                        style: AppTypography.moneySmall.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.slate800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Vertical Divider
                              Container(
                                height: 26,
                                width: 1,
                                color: const Color(0xFFE2E8F0),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                              ),

                              // Column 2: Received Amount (জমা)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'জমা',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 10.5,
                                        color: AppColors.emeraldDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        application.receivedAmount.formatBengali(),
                                        style: AppTypography.moneySmall.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.emeraldDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Vertical Divider
                              Container(
                                height: 26,
                                width: 1,
                                color: const Color(0xFFE2E8F0),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                              ),

                              // Column 3: Due or Paid Status Pill
                              Expanded(
                                flex: 4,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                                    decoration: BoxDecoration(
                                      color: hasDue
                                          ? AppColors.amberSurface
                                          : AppColors.emeraldSurface,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                      border: Border.all(
                                        color: hasDue
                                            ? AppColors.amber.withValues(alpha: 0.35)
                                            : AppColors.emerald.withValues(alpha: 0.35),
                                        width: 0.9,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          hasDue ? Icons.schedule_rounded : Icons.check_circle_rounded,
                                          size: 12,
                                          color: hasDue ? AppColors.amberDark : AppColors.emeraldDark,
                                        ),
                                        const SizedBox(width: 3.5),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              hasDue
                                                  ? 'বকেয়া ${application.dueAmount.formatBengali()}'
                                                  : 'পরিশোধিত ✓',
                                              style: AppTypography.labelMedium.copyWith(
                                                color: hasDue
                                                    ? AppColors.amberDark
                                                    : AppColors.emeraldDark,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (application.appNumber != null && application.appNumber!.isNotEmpty)
                              CopyChip(
                                label: 'আবেদন',
                                value: application.appNumber!,
                                prefixIcon: Icons.description_outlined,
                              )
                            else
                              const SizedBox.shrink(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'বিস্তারিত দেখুন',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
