import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/screens/application_detail_screen.dart';
import 'payment_form_screen.dart';

class DueManagementScreen extends StatefulWidget {
  const DueManagementScreen({super.key});

  @override
  State<DueManagementScreen> createState() => _DueManagementScreenState();
}

class _DueManagementScreenState extends State<DueManagementScreen> {
  List<DemoApplication> get _dueApplications {
    final list = DemoStore.applications.where((a) => a.dueAmount.isPositive).toList();
    list.sort((a, b) => b.dueAmount.compareTo(a.dueAmount)); // Highest due first
    return list;
  }

  Money get _totalOutstandingDue {
    Money sum = Money.zero;
    for (var a in _dueApplications) {
      sum += a.dueAmount;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final list = _dueApplications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('বকেয়া হিসাব ও তাগাদা'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.rose),
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
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.amberDark, size: 28),
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
                          _totalOutstandingDue.formatBengali(),
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.amberDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'মোট ${BengaliDigits.toBengali(list.length)} জন গ্রাহকের কাছে পাওনা রয়েছে',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
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
          const Divider(),

          // Dues list
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'কোনো বকেয়া নেই!',
                    message: 'সকল গ্রাহকের সার্ভিস ফি সম্পূর্ণ পরিশোধিত রয়েছে।',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    itemCount: list.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: AppSpacing.base),
                    itemBuilder: (ctx, i) {
                      final app = list[i];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (ctx) => ApplicationDetailScreen(application: app),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              app.applicantName,
                                              style: AppTypography.headingSmall.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${app.workType} • ${app.officeName}',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone_in_talk, color: AppColors.emerald),
                                  tooltip: 'ফোন করুন',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${app.applicantPhone} নম্বরে তাগাদার কল করা হচ্ছে...')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('চুক্তি', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                                      Text(app.agreedAmount.formatBengali(), style: AppTypography.moneySmall),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('পরিশোধিত', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.emerald)),
                                      Text(
                                        app.receivedAmount.formatBengali(),
                                        style: AppTypography.moneySmall.copyWith(color: AppColors.emerald),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('বকেয়া', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.rose)),
                                      Text(
                                        app.dueAmount.formatBengali(),
                                        style: AppTypography.moneySmall.copyWith(
                                          color: AppColors.rose,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.check_circle_outline, size: 14),
                                  label: const Text('পরিশোধিত চিহ্নিত', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.emeraldDark,
                                    side: const BorderSide(color: AppColors.emeraldLight),
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final confirmed = await ConfirmDialog.show(
                                      context,
                                      title: 'পরিশোধিত হিসেবে চিহ্নিত?',
                                      message: '${app.applicantName}-এর অবশিষ্ট ${app.dueAmount.formatBengali()} টাকা মওকুফ করে সম্পূর্ণ পরিশোধিত চিহ্নিত করতে চান?',
                                      confirmText: 'হ্যাঁ, চিহ্নিত করুন',
                                      icon: Icons.check_circle_outline,
                                    );
                                    if (confirmed == true) {
                                      final updated = app.copyWith(isMarkedAsPaid: true);
                                      final idx = DemoStore.applications.indexWhere((a) => a.id == app.id);
                                      if (idx != -1) DemoStore.applications[idx] = updated;
                                      setState(() {});
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('বকেয়া মওকুফ করে পরিশোধিত হিসেবে চিহ্নিত করা হয়েছে।'),
                                          backgroundColor: AppColors.emerald,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => PaymentFormScreen(
                                          defaultApplicationId: app.id,
                                          defaultApplicantName: app.applicantName,
                                          dueAmount: app.dueAmount,
                                        ),
                                      ),
                                    ).then((_) => setState(() {}));
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

