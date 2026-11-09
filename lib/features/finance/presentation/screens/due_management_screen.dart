import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_launcher.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import 'payment_form_screen.dart';

class DueManagementScreen extends ConsumerStatefulWidget {
  const DueManagementScreen({super.key});

  @override
  ConsumerState<DueManagementScreen> createState() =>
      _DueManagementScreenState();
}

class _DueManagementScreenState extends ConsumerState<DueManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];

    final dueApplications = allApps
        .where((a) => a.effectiveDue.isPositive)
        .map((a) => a.toDemoApplication())
        .toList()
      ..sort((a, b) => b.dueAmount.compareTo(a.dueAmount));

    Money totalOutstandingDue = Money.zero;
    for (var a in dueApplications) {
      totalOutstandingDue += a.dueAmount;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('বকেয়া হিসাব ও তাগাদা'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: AppColors.rose),
            tooltip: 'বকেয়া তালিকা PDF তৈরি',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('বকেয়া তালিকার অফিসিয়াল PDF তৈরি হচ্ছে...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Due Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.amberSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.amberLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppColors.amberDark, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'সর্বমোট পাওনা বকেয়া',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.slate700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalOutstandingDue.formatBengali(),
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.amberDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'মোট ${BengaliDigits.toBengali(dueApplications.length)} টি ফাইলে বকেয়া অবশিষ্ট আছে',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.slate600,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List of Due Applications
          Expanded(
            child: dueApplications.isEmpty
                ? EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'কোনো বকেয়া পাওনা নেই!',
                    message:
                        'সব গ্রাহকের কাজের চুক্তি ফি সম্পূর্ণ পরিশোধিত রয়েছে।',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    itemCount: dueApplications.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.base),
                    itemBuilder: (ctx, idx) {
                      final app = dueApplications[idx];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(15, 23, 42, 0.03),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.applicantName,
                                        style: AppTypography.headingSmall
                                            .copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 3),
                                      InkWell(
                                        onTap: () => AppLauncher.makePhoneCall(
                                          context,
                                          app.applicantPhone,
                                          contactName: app.applicantName,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${app.workType} • ',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      color: AppColors
                                                          .textSecondary),
                                            ),
                                            const Icon(Icons.phone_in_talk,
                                                size: 13,
                                                color: AppColors.emerald),
                                            const SizedBox(width: 3),
                                            Text(
                                              BengaliDigits.toBengali(
                                                  app.applicantPhone),
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'বকেয়া',
                                      style: AppTypography.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: AppColors.textMuted),
                                    ),
                                    Text(
                                      app.dueAmount.formatBengali(),
                                      style: AppTypography.moneyMedium
                                          .copyWith(
                                              color: AppColors.rose,
                                              fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Quick info row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'মোট চুক্তি: ${app.agreedAmount.formatBengali()}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'জমা: ${app.receivedAmount.formatBengali()}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.emerald),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.phone_in_talk,
                                      size: 18, color: AppColors.emerald),
                                  tooltip: 'গ্রাহককে কল করুন',
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFECFDF5),
                                    padding: const EdgeInsets.all(8),
                                    minimumSize: const Size(36, 36),
                                  ),
                                  onPressed: () => AppLauncher.makePhoneCall(
                                    context,
                                    app.applicantPhone,
                                    contactName: app.applicantName,
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 14),
                                  label: const Text('পরিশোধিত চিহ্নিত',
                                      style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.emeraldDark,
                                    side: const BorderSide(
                                        color: AppColors.emeraldLight),
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusPill),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final confirmed =
                                        await ConfirmDialog.show(
                                      context,
                                      title: 'পরিশোধিত হিসেবে চিহ্নিত?',
                                      message:
                                          '${app.applicantName}-এর অবশিষ্ট ${app.dueAmount.formatBengali()} টাকা মওকুফ করে সম্পূর্ণ পরিশোধিত চিহ্নিত করতে চান?',
                                      confirmText: 'হ্যাঁ, চিহ্নিত করুন',
                                      icon: Icons.check_circle_outline,
                                    );
                                    if (confirmed == true) {
                                      await ref
                                          .read(applicationControllerProvider
                                              .notifier)
                                          .markAsPaid(app.id, true);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'বকেয়া মওকুফ করে পরিশোধিত হিসেবে চিহ্নিত করা হয়েছে।'),
                                          backgroundColor:
                                              AppColors.emerald,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_card, size: 16),
                                  label: const Text('টাকা জমা নিন'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusPill),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => PaymentFormScreen(
                                          defaultApplicationId: app.id,
                                          defaultApplicantName:
                                              app.applicantName,
                                          dueAmount: app.dueAmount,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
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
