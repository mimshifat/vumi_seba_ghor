import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/app_launcher.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../documents/presentation/screens/document_viewer_screen.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import '../../../finance/presentation/screens/payment_form_screen.dart';
import '../../../references/presentation/providers/reference_providers.dart';
import '../../../references/presentation/screens/reference_detail_screen.dart';
import '../../data/services/land_portal_helper.dart';
import '../providers/application_providers.dart';
import 'application_edit_screen.dart';
import 'land_portal_webview_screen.dart';

class ApplicationDetailScreen extends ConsumerStatefulWidget {
  final DemoApplication application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  ConsumerState<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState
    extends ConsumerState<ApplicationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DemoApplication _app;
  bool _showPortalPassword = false;
  bool _isOpeningPortal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _app = widget.application;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showStatusChangeDialog() {
    String selectedStatus = _app.status;
    final noteController = TextEditingController();
    final amountController = TextEditingController();
    DateTime hearingDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay hearingTime = const TimeOfDay(hour: 11, minute: 0);
    bool createHearingTask = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildStatusChip(String st) {
            final isSelected = selectedStatus == st;
            final color = AppColors.getStatusColor(st);
            return ChoiceChip(
              label: Text(st),
              selected: isSelected,
              onSelected: (sel) {
                if (sel) {
                  setDialogState(() {
                    selectedStatus = st;
                  });
                }
              },
              selectedColor: color.withValues(alpha: 0.16),
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
                fontFamily: AppTypography.fontFamily,
              ),
              side: BorderSide(
                color: isSelected ? color : const Color(0xFFCBD5E1),
                width: isSelected ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            );
          }

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.base + 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'আবেদনের অবস্থা পরিবর্তন',
                            style: AppTypography.headingSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'বর্তমান অবস্থা: ',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            _app.status,
                            style: TextStyle(
                              color: AppColors.getStatusColor(_app.status),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Section 1: Normal Happy Flow
                    Row(
                      children: [
                        const Icon(Icons.timeline_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'স্বাভাবিক অগ্রগতি (ধাপসমূহ):',
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: DemoStore.progressStatuses.map(buildStatusChip).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),

                    // Section 2: Exceptions
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.amber),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'বিশেষ অবস্থা বা আপত্তি:',
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: DemoStore.exceptionStatuses.map(buildStatusChip).toList(),
                    ),

                    // Hearing Date & Time Picker (visible when 'শুনানি' selected)
                    if (selectedStatus == 'শুনানি') ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm + 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: const Icon(Icons.event_rounded, size: 15, color: Color(0xFF7C3AED)),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'শুনানির তারিখ ও সময় নির্ধারণ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6D28D9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: hearingDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setDialogState(() => hearingDate = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        border: Border.all(color: const Color(0xFFDDD6FE)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF7C3AED)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${BengaliDigits.toBengali(hearingDate.day)}/${BengaliDigits.toBengali(hearingDate.month)}/${BengaliDigits.toBengali(hearingDate.year)}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: hearingTime,
                                      );
                                      if (picked != null) {
                                        setDialogState(() => hearingTime = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        border: Border.all(color: const Color(0xFFDDD6FE)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF7C3AED)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${BengaliDigits.toBengali(hearingTime.hourOfPeriod == 0 ? 12 : hearingTime.hourOfPeriod)}:${BengaliDigits.toBengali(hearingTime.minute.toString().padLeft(2, '0'))} ${hearingTime.period == DayPeriod.am ? 'সকাল' : 'বিকাল'}',
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: createHearingTask,
                                    activeColor: const Color(0xFF7C3AED),
                                    onChanged: (val) => setDialogState(() => createHearingTask = val ?? true),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'টাস্ক তালিকায় শুনানির রিমাইন্ডার যোগ করুন',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF4C1D95)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.base),

                    // Modern Financial Entry Section
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 15,
                                  color: AppColors.slate700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'কাজের খরচ বা ফি',
                                style: AppTypography.titleMedium.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'এই ধাপে কোনো খরচ বা ফি প্রদান করলে লিখুন, অন্যথায় খালি রাখুন।',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.3),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Amount Field
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              labelText: 'খরচের পরিমাণ',
                              hintText: '০',
                              prefixText: '৳ ',
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.base),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'বিবরণ বা অগ্রগতি নোট',
                        hintText: 'অগ্রগতি বা প্রয়োজনীয় মন্তব্য লিখুন (ঐচ্ছিক)...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'বাতিল',
                            variant: ButtonVariant.outline,
                            height: 42,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            text: 'অবস্থা হালনাগাদ',
                            height: 42,
                            onPressed: () async {
                              final rawAmount = amountController.text
                                  .replaceAll(',', '')
                                  .replaceAll('৳', '')
                                  .trim();
                              final taka = int.tryParse(BengaliDigits.toEnglish(rawAmount)) ?? 0;
                              final expensePaisa = taka > 0 ? Money.fromTaka(taka).paisa : null;
                              final userNote = noteController.text.trim();

                              final statusChanged = selectedStatus != _app.status;
                              final hasExpense = taka > 0;

                              if (!statusChanged && !hasExpense && userNote.isEmpty) {
                                Navigator.pop(ctx);
                                return;
                              }

                              DateTime? hDueDate;
                              String? hTaskTitle;
                              if (selectedStatus == 'শুনানি' && createHearingTask) {
                                hDueDate = DateTime(
                                  hearingDate.year,
                                  hearingDate.month,
                                  hearingDate.day,
                                  hearingTime.hour,
                                  hearingTime.minute,
                                );
                                hTaskTitle = '${_app.applicantName} - শুনানিতে উপস্থিতি';
                              }

                              try {
                                await ref
                                    .read(applicationControllerProvider.notifier)
                                    .transitionStatus(
                                      applicationId: _app.id,
                                      newStatus: selectedStatus,
                                      note: userNote.isNotEmpty ? userNote : null,
                                      feeExpensePaisa: expensePaisa,
                                      feeExpenseCategory: 'কাজের খরচ',
                                      hearingTaskTitle: hTaskTitle,
                                      hearingTaskDueDate: hDueDate,
                                      hearingTaskPriority: 'জরুরি',
                                    );

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);

                                if (mounted) {
                                  setState(() {
                                    _app = _app.copyWith(status: selectedStatus);
                                  });
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('ফাইলের অবস্থা সফলভাবে "$selectedStatus" এ হালনাগাদ হয়েছে।'),
                                    backgroundColor: AppColors.emerald,
                                  ),
                                );
                              } catch (e) {
                                if (!ctx.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppColors.rose,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMarkAsPaidDialog() {
    final noteCtrl = TextEditingController(text: 'বকেয়া মওকুফ');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base + 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.emerald, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'বকেয়া মওকুফ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.emeraldSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'অবশিষ্ট ${_app.rawDueAmount.formatBengali()} টাকা মওকুফ করে সম্পূর্ণ পরিশোধিত চিহ্নিত করা হবে।',
                  style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.emeraldDark, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'মন্তব্য',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.slate50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('বাতিল', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        ref
                            .read(applicationControllerProvider.notifier)
                            .markAsPaid(_app.id, true);

                        setState(() {
                          _app = _app.copyWith(isMarkedAsPaid: true);
                        });

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('বকেয়া মওকুফ করে সম্পূর্ণ পরিশোধিত হিসেবে চিহ্নিত করা হয়েছে।'),
                            backgroundColor: AppColors.emerald,
                          ),
                        );
                      },
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'মওকুফ করুন',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _unmarkAsPaid() {
    ref
        .read(applicationControllerProvider.notifier)
        .markAsPaid(_app.id, false);
    setState(() {
      _app = _app.copyWith(isMarkedAsPaid: false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('বকেয়া পুনঃবহাল করা হয়েছে।'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsWithFin =
        ref.watch(applicationsWithFinancialsStreamProvider).valueOrNull;
    final matched = appsWithFin
        ?.where((a) => a.application.id == _app.id)
        .firstOrNull;
    if (matched != null) {
      _app = matched.toDemoApplication();
    }

    final livePayments =
        ref.watch(applicationPaymentsProvider(_app.id)).valueOrNull;
    final liveExpenses =
        ref.watch(applicationExpensesProvider(_app.id)).valueOrNull;
    final liveHistory =
        ref.watch(applicationStatusHistoryProvider(_app.id)).valueOrNull;

    if (livePayments != null) {
      _app = _app.copyWith(
        payments: livePayments
            .map((p) => DemoPayment(
                  id: p.id,
                  applicationId: p.applicationId,
                  amount: Money.fromPaisa(p.amount),
                  date: DateTime.fromMillisecondsSinceEpoch(p.date),
                  method: p.method,
                  note: p.note,
                  statusHistoryId: p.statusHistoryId,
                  statusName: p.statusName,
                  isStatusFee: p.isStatusFee == 1,
                ))
            .toList(),
      );
    }

    if (liveExpenses != null) {
      _app = _app.copyWith(
        expenses: liveExpenses
            .map((e) => DemoExpense(
                  id: e.id,
                  applicationId: e.applicationId,
                  applicationTitle: '${_app.workType} - ${_app.applicantName}',
                  amount: Money.fromPaisa(e.amount),
                  category: e.category,
                  date: DateTime.fromMillisecondsSinceEpoch(e.date),
                  isGeneral: e.isGeneral == 1,
                  note: e.note,
                  statusHistoryId: e.statusHistoryId,
                  statusName: e.statusName,
                  isStatusExpense: e.isStatusExp == 1,
                ))
            .toList(),
      );
    }

    if (liveHistory != null) {
      _app = _app.copyWith(
        statusHistory: liveHistory
            .map((h) => DemoStatusHistory(
                  id: h.id,
                  prevStatus: h.prevStatus ?? '',
                  newStatus: h.newStatus,
                  changedAt: DateTime.fromMillisecondsSinceEpoch(h.changedAt),
                  note: h.note,
                ))
            .toList(),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _app.applicantName,
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.5,
                  color: AppColors.slate900,
                  height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${_app.workType}${_app.officeName.isNotEmpty ? ' • ${_app.officeName}' : ''}',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
            visualDensity: VisualDensity.compact,
            tooltip: 'আবেদন সম্পাদনা',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ApplicationEditScreen(application: _app),
                ),
              ).then((updated) {
                if (updated == true || updated is DemoApplication) {
                  ref.invalidate(applicationsWithFinancialsStreamProvider);
                  if (mounted) setState(() {});
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.rose),
            visualDensity: VisualDensity.compact,
            tooltip: 'মুছে ফেলুন',
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context,
                title: 'আবেদন মুছে ফেলবেন?',
                message: 'এই আবেদন এবং এর সংযুক্ত ফাইলগুলো মুছে যাবে।',
                confirmText: 'হ্যাঁ, মুছুন',
                isDestructive: true,
                icon: Icons.delete_forever_rounded,
              );
              if (confirmed == true) {
                if (!context.mounted) return;
                await ref
                    .read(applicationControllerProvider.notifier)
                    .deleteApplication(_app.id);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('আবেদনটি মুছে ফেলা হয়েছে।'),
                    backgroundColor: AppColors.rose,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.slate200, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.slate500,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              tabs: const [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('১. তথ্য'),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('২. অগ্রগতি'),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('৩. টাকার হিসাব'),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('৪. ডকুমেন্ট'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Quick Status & Action Strip
          _buildQuickActionBar(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppInfoTab(),
                _buildProgressTab(),
                _buildFinanceTab(),
                _buildDocumentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar() {
    final hasDue = _app.dueAmount.isPositive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            child: StatusBadge(status: _app.status, isLarge: false),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          // Action Buttons
          OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz_rounded, size: 14),
            label: const Text('অবস্থা বদলান', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primaryLight, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            onPressed: _showStatusChangeDialog,
          ),
          if (hasDue) ...[
            const SizedBox(width: 6),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_card_rounded, size: 14),
              label: const Text('জমা নিন', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PaymentFormScreen(
                      defaultApplicationId: _app.id,
                      defaultApplicantName: _app.applicantName,
                      dueAmount: _app.dueAmount,
                    ),
                  ),
                ).then((_) {
                  ref.invalidate(applicationsWithFinancialsStreamProvider);
                  ref.invalidate(allUnifiedTransactionsStreamProvider);
                  if (mounted) setState(() {});
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // Primary Card: Applicant & Work Type
        _buildSectionCard(
          title: 'মূল বিবরণ',
          icon: Icons.person_outline_rounded,
          children: [
            _buildDetailRow('আবেদনকারী', _app.applicantName, isBold: true),
            _buildDetailRow(
              'মোবাইল নম্বর',
              BengaliDigits.toBengali(_app.applicantPhone),
              isCopyable: true,
              trailing: InkWell(
                onTap: () => AppLauncher.makePhoneCall(
                  context,
                  _app.applicantPhone,
                  contactName: _app.applicantName,
                ),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_in_talk_rounded, size: 15, color: AppColors.emerald),
                ),
              ),
            ),
            if (_app.applicantAddress != null && _app.applicantAddress!.isNotEmpty)
              _buildDetailRow('ঠিকানা', _app.applicantAddress!),
            if (_app.referencePersonName != null && _app.referencePersonName!.isNotEmpty)
              _buildDetailRow(
                'রেফারেন্স ব্যক্তি',
                _app.referencePersonName!,
                trailing: InkWell(
                  onTap: () {
                    DemoReference? ref;
                    final liveRefs = this.ref.read(referencesStreamProvider).valueOrNull;
                    if (_app.referencePersonId != null && liveRefs != null) {
                      final found = liveRefs.where((r) => r.id == _app.referencePersonId).firstOrNull;
                      if (found != null) {
                        ref = DemoReference(id: found.id, name: found.name, phone: found.phone, address: found.address);
                      }
                    }
                    if (ref == null && liveRefs != null) {
                      final found = liveRefs.where((r) => r.name == _app.referencePersonName).firstOrNull;
                      if (found != null) {
                        ref = DemoReference(id: found.id, name: found.name, phone: found.phone, address: found.address);
                      }
                    }
                    ref ??= DemoStore.references.cast<DemoReference?>().firstWhere(
                          (r) => r?.id == _app.referencePersonId || r?.name == _app.referencePersonName,
                          orElse: () => null,
                        );
                    if (ref != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ReferenceDetailScreen(reference: ref!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('রেফারেন্স: ${_app.referencePersonName}')),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'প্রোফাইল',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 13, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            _buildDetailRow('কাজের ধরন', _app.workType, isBadge: true),
            if (_app.mouza != null && _app.mouza!.trim().isNotEmpty)
              _buildDetailRow('মৌজার নাম', _app.mouza!),
            _buildDetailRow('অফিসের নাম', _app.officeName),
            _buildDetailRow(
              'আবেদনের তারিখ',
              BengaliDigits.toBengali('${_app.applicationDate.day}/${_app.applicationDate.month}/${_app.applicationDate.year}'),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.base),

        // Identifiers Card
        _buildSectionCard(
          title: 'সরকারি নম্বর ও রেফারেন্স',
          icon: Icons.tag_rounded,
          children: [
            _buildDetailRow(
              'আবেদন নম্বর',
              _app.appNumber ?? 'দেওয়া হয়নি',
              isCopyable: _app.appNumber != null,
            ),
            _buildDetailRow(
              'কেস নম্বর',
              _app.caseNumber ?? 'দেওয়া হয়নি',
              isCopyable: _app.caseNumber != null,
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.base),

        // Land Portal Card (LSG Auto-login)
        _buildSectionCard(
          title: 'ভূমি পোর্টাল লগইন (LSG)',
          icon: Icons.language_rounded,
          children: [
            _buildDetailRow(
              'লগইন নম্বর',
              BengaliDigits.toBengali(_app.effectivePortalPhone),
              isCopyable: true,
              copyValue: _app.effectivePortalPhone,
              trailing: (_app.portalPhone != null &&
                      _app.portalPhone!.trim().isNotEmpty &&
                      _app.portalPhone!.trim() != _app.applicantPhone.trim())
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amberSurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      child: Text(
                        'আলাদা নম্বর',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.amberDark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
            _buildDetailRow(
              'পাসওয়ার্ড',
              (_app.portalPassword != null && _app.portalPassword!.isNotEmpty)
                  ? (_showPortalPassword
                      ? _app.portalPassword!
                      : '•' * _app.portalPassword!.length)
                  : 'দেওয়া হয়নি',
              isCopyable: _app.portalPassword != null && _app.portalPassword!.isNotEmpty,
              copyValue: _app.portalPassword,
              trailing: (_app.portalPassword != null && _app.portalPassword!.isNotEmpty)
                  ? IconButton(
                      icon: Icon(
                        _showPortalPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 17,
                        color: AppColors.slate500,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: _showPortalPassword ? 'লুকান' : 'দেখুন',
                      onPressed: () {
                        setState(() => _showPortalPassword = !_showPortalPassword);
                      },
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  (_app.portalPassword != null && _app.portalPassword!.isNotEmpty)
                      ? 'পোর্টালে অটো-ফিল ও লগইন'
                      : 'ভূমি পোর্টাল খুলুন',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onPressed: _isOpeningPortal
                    ? null
                    : () async {
                        setState(() => _isOpeningPortal = true);
                        try {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => LandPortalWebViewScreen(
                                initialUrl: LandPortalHelper.lsgLoginUrl,
                                portalPhone: _app.effectivePortalPhone,
                                portalPassword: _app.portalPassword,
                                applicationId: _app.id,
                                applicantName: _app.applicantName,
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isOpeningPortal = false);
                          }
                        }
                      },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.base),

        // Notes
        if (_app.notes != null && _app.notes!.isNotEmpty)
          _buildSectionCard(
            title: 'বিশেষ নোট ও মন্তব্য',
            icon: Icons.sticky_note_2_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _app.notes!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  (Color, IconData) _getProgressVisuals(String status, bool isLatest) {
    final s = status.trim();
    if (s == 'মঞ্জুর' || s == 'পাশ' || s == 'সম্পন্ন') {
      return (AppColors.emerald, Icons.check_circle_rounded);
    } else if (s == 'বাতিল' || s == 'নামঞ্জুর') {
      return (AppColors.rose, Icons.cancel_rounded);
    } else if (s == 'আপত্তি') {
      return (const Color(0xFFEA580C), Icons.warning_amber_rounded);
    } else if (s == 'সংশোধন প্রয়োজন' || s == 'সংশোধন প্রয়োজন') {
      return (AppColors.rose, Icons.build_circle_outlined);
    } else if (s == 'অপেক্ষমাণ') {
      return (AppColors.amber, Icons.hourglass_top_rounded);
    } else {
      // Normal Happy Flow (আবেদন, প্রস্তাব প্রেরণ, প্রতিবেদন দাখিল, শুনানি, ডিসিআর প্রস্তুত, ইত্যাদি)
      return (
        AppColors.primary,
        isLatest ? Icons.radio_button_checked_rounded : Icons.check_rounded,
      );
    }
  }

  Widget _buildProgressTab() {
    if (_app.statusHistory.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        title: 'অগ্রগতির ইতিহাস নেই',
        message: 'অবস্থা পরিবর্তন করলে এখানে স্বয়ংক্রিয়ভাবে ইতিহাস সংরক্ষিত হবে।',
        actionText: 'অবস্থা পরিবর্তন করুন',
        onAction: _showStatusChangeDialog,
      );
    }

    final historyList = List<DemoStatusHistory>.from(_app.statusHistory)
      ..sort((a, b) => b.changedAt.compareTo(a.changedAt));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'অগ্রগতির সময়রেখা (${BengaliDigits.toBengali(historyList.length)} টি ধাপ)',
              style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('নতুন ধাপ', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: _showStatusChangeDialog,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.slate200),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historyList.length,
            itemBuilder: (ctx, i) {
              final item = historyList[i];
              final isLatest = i == 0;
              final isLast = i == historyList.length - 1;
              final (color, statusIcon) = _getProgressVisuals(item.newStatus, isLatest);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline indicator column with vertical connecting line
                    Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isLatest ? color : color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                            boxShadow: isLatest
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.28),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(
                            statusIcon,
                            size: 13,
                            color: isLatest ? Colors.white : color,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: AppColors.slate200,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Timeline Content Card
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.base),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 5,
                                    runSpacing: 4,
                                    children: [
                                      // Origin status
                                      if (item.prevStatus.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.slate100,
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                            border: Border.all(color: AppColors.slate200, width: 0.8),
                                          ),
                                          child: Text(
                                            item.prevStatus,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.slate600,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 13,
                                          color: AppColors.slate400,
                                        ),
                                      ],
                                      // Destination / New status
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                          border: Border.all(color: color.withValues(alpha: 0.35), width: 0.9),
                                        ),
                                        child: Text(
                                          item.newStatus,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      // Active current indicator tag
                                      if (isLatest)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                          ),
                                          child: Text(
                                            'বর্তমান',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  BengaliDigits.toBengali(
                                    '${item.changedAt.day}/${item.changedAt.month}/${item.changedAt.year}',
                                  ),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (item.note != null && item.note!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  item.note!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.slate700,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        // Financial Overview Summary Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(15, 23, 42, 0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Hero Net Income Banner (কাজ শেষে আপনার কত টাকা সার্ভিস ইনকাম থাকল)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.emeraldDark, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'এই ফাইলে আপনার প্রকৃত ইনকাম (আয়)',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.emeraldDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _app.actualIncome.formatBengali(),
                              maxLines: 1,
                              style: AppTypography.displayLarge.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'আদায় ${_app.receivedAmount.formatBengali()} — কাজের খরচ ${_app.expenseAmount.formatBengali()}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Responsive 2-column grid for key financial metrics
              Row(
                children: [
                  Expanded(
                    child: _buildFinanceTile(
                      title: 'চুক্তিকৃত টাকা',
                      value: _app.agreedAmount.formatBengali(),
                      color: AppColors.textPrimary,
                      icon: Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinanceTile(
                      title: 'মোট আদায়',
                      value: _app.receivedAmount.formatBengali(),
                      color: AppColors.emerald,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildFinanceTile(
                      title: 'কাজের মোট খরচ',
                      value: _app.expenseAmount.formatBengali(),
                      color: AppColors.rose,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinanceTile(
                      title: 'বকেয়া',
                      value: _app.dueAmount.isPositive
                          ? _app.dueAmount.formatBengali()
                          : (_app.isMarkedAsPaid ? 'পরিশোধিত ✓ (মওকুফ)' : 'পরিশোধিত ✓'),
                      color: _app.dueAmount.isPositive ? AppColors.rose : AppColors.emerald,
                      icon: _app.dueAmount.isPositive ? Icons.pending_outlined : Icons.check_circle_outline_rounded,
                    ),
                  ),
                ],
              ),
              if (_app.rawDueAmount.isPositive) ...[
                const SizedBox(height: 10),
                if (!_app.isMarkedAsPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'বাকি ${_app.rawDueAmount.formatBengali()} মওকুফ করবেন?',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showMarkAsPaidDialog,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldSurface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              border: Border.all(color: AppColors.emeraldLight),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 12, color: AppColors.emeraldDark),
                                SizedBox(width: 4),
                                Text(
                                  'মওকুফ',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.emeraldDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.emerald),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'বকেয়া ${_app.rawDueAmount.formatBengali()} মওকুফ করা হয়েছে',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _unmarkAsPaid,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Text(
                              'পুনঃবহাল',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.base),

        // Payments History
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'টাকা জমার ইতিহাস (${BengaliDigits.toBengali(_app.payments.length)})',
              style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('জমা যোগ করুন', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PaymentFormScreen(
                      defaultApplicationId: _app.id,
                      defaultApplicantName: _app.applicantName,
                      dueAmount: _app.dueAmount,
                    ),
                  ),
                ).then((_) {
                  ref.invalidate(applicationsWithFinancialsStreamProvider);
                  ref.invalidate(allUnifiedTransactionsStreamProvider);
                  if (mounted) setState(() {});
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_app.payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.slate200),
            ),
            child: const Center(
              child: Text(
                'কোনো জমার রেকর্ড নেই',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ..._app.payments.map((p) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.slate200),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.02),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, color: AppColors.emerald, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p.amount.formatBengali(),
                                style: AppTypography.headingSmall.copyWith(
                                  color: AppColors.emeraldDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                ),
                                child: Text(
                                  p.method,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${BengaliDigits.toBengali('${p.date.day}/${p.date.month}/${p.date.year}')}${p.note != null && p.note!.isNotEmpty ? ' • ${p.note}' : ''}',
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
              )),

        const SizedBox(height: AppSpacing.base),

        // Expenses History
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'খরচের ইতিহাস (${BengaliDigits.toBengali(_app.expenses.length)})',
              style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_app.expenses.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.slate200),
            ),
            child: const Center(
              child: Text(
                'কোনো খরচের রেকর্ড নেই',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ..._app.expenses.map((e) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.slate200),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.02),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.roseSurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: AppColors.rose, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.amount.formatBengali(),
                                style: AppTypography.headingSmall.copyWith(
                                  color: AppColors.rose,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                ),
                                child: Text(
                                  e.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${BengaliDigits.toBengali('${e.date.day}/${e.date.month}/${e.date.year}')}${e.note != null && e.note!.isNotEmpty ? ' • ${e.note}' : ''}',
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
              )),
      ],
    );
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
        dialogTitle: 'আবেদনের PDF বা ছবি নির্বাচন করুন',
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      Uint8List? bytes = pickedFile.bytes;
      if (bytes == null && pickedFile.path != null) {
        final f = File(pickedFile.path!);
        if (await f.exists()) {
          bytes = await f.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ফাইলটি পড়া যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।'),
            backgroundColor: AppColors.rose,
          ),
        );
        return;
      }

      final ext = pickedFile.extension?.toLowerCase() ?? '';
      final isPdf = ext == 'pdf';
      final fileType = isPdf ? 'pdf' : 'image';

      final bytesLen = bytes.length;
      final String sizeStr;
      if (bytesLen >= 1024 * 1024) {
        sizeStr = '${(bytesLen / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        sizeStr = '${(bytesLen / 1024).toStringAsFixed(0)} KB';
      }

      // ডাটাবেজে সংরক্ষণ
      await ref.read(applicationControllerProvider.notifier).addDocument(
            applicationId: _app.id,
            fileName: pickedFile.name,
            fileType: fileType,
            fileData: bytes,
            fileSize: sizeStr,
          );

      final newDoc = DemoDocument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: pickedFile.name,
        type: fileType,
        size: sizeStr,
        uploadDate: DateTime.now(),
        fileData: bytes,
      );

      setState(() {
        _app = _app.copyWith(documents: [newDoc, ..._app.documents]);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${pickedFile.name}" সফলভাবে যুক্ত হয়েছে।'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ফাইল আপলোড করা যায়নি: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Widget _buildDocumentsTab() {
    final liveDocsAsync = ref.watch(applicationDocumentsProvider(_app.id));
    final liveDocs = liveDocsAsync.valueOrNull;

    final List<DemoDocument> docsList = (liveDocs != null && liveDocs.isNotEmpty)
        ? liveDocs.map((d) => DemoDocument(
              id: d.id,
              name: d.fileName,
              type: d.fileType,
              size: d.fileSize,
              uploadDate: DateTime.fromMillisecondsSinceEpoch(d.createdAt),
              fileData: d.fileData,
            )).toList()
        : _app.documents;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.base),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'সংযুক্ত ডকুমেন্ট (${BengaliDigits.toBengali(docsList.length)})',
              style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: const Text('ফাইল যোগ করুন', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              onPressed: _pickAndUploadDocument,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (docsList.isEmpty)
          EmptyState(
            icon: Icons.description_outlined,
            title: 'কোনো ডকুমেন্ট যুক্ত নেই',
            message: 'সরকারি আবেদন PDF, চালান বা দলিলে ছবি এখানে যুক্ত করে রাখতে পারেন।',
            actionText: 'ডকুমেন্ট যুক্ত করুন',
            onAction: _pickAndUploadDocument,
          )
        else
          ...docsList.map((doc) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.02),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: doc.type == 'pdf' ? AppColors.roseSurface : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      doc.type == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: doc.type == 'pdf' ? AppColors.rose : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    doc.name,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${doc.size} • আপলোড: ${BengaliDigits.toBengali('${doc.uploadDate.day}/${doc.uploadDate.month}/${doc.uploadDate.year}')}',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20),
                        tooltip: 'দেখুন',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => DocumentViewerScreen(document: doc),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate400, size: 20),
                        tooltip: 'মুছুন',
                        onPressed: () async {
                          final ok = await ConfirmDialog.show(
                            context,
                            title: 'ডকুমেন্ট মুছবেন?',
                            message: '${doc.name} ফাইলটি স্থায়ীভাবে মুছে যাবে।',
                            confirmText: 'মুছুন',
                            isDestructive: true,
                          );
                          if (ok == true) {
                            await ref.read(applicationControllerProvider.notifier).deleteDocument(
                                  documentId: doc.id,
                                  applicationId: _app.id,
                                );
                            setState(() {
                              _app = _app.copyWith(
                                documents: _app.documents.where((d) => d.id != doc.id).toList(),
                              );
                            });
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ডকুমেন্টটি মুছে ফেলা হয়েছে।'),
                                backgroundColor: AppColors.rose,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildFinanceTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.headingSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.slate100),
          const SizedBox(height: AppSpacing.xs),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isBadge = false,
    bool isCopyable = false,
    String? copyValue,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.slate500,
                fontSize: 12.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: isBadge
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                            border: Border.all(color: AppColors.primaryLight, width: 0.8),
                          ),
                          child: Text(
                            value,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : Text(
                          value,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isBold
                              ? AppTypography.headingSmall.copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                )
                              : AppTypography.bodyMedium.copyWith(
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                        ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing,
                ],
                if (isCopyable) ...[
                  const SizedBox(width: 4),
                  _DetailCopyButton(value: copyValue ?? value, label: label),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCopyButton extends StatefulWidget {
  final String value;
  final String label;

  const _DetailCopyButton({required this.value, required this.label});

  @override
  State<_DetailCopyButton> createState() => _DetailCopyButtonState();
}

class _DetailCopyButtonState extends State<_DetailCopyButton> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_copied) {
      return Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.emeraldSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.emerald),
            const SizedBox(width: 3),
            Text(
              'কপি হয়েছে',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.emerald,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
      tooltip: 'কপি করুন',
      padding: const EdgeInsets.only(left: 6),
      constraints: const BoxConstraints(),
      onPressed: _onCopy,
    );
  }
}
