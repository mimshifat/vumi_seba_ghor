import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../applications/presentation/screens/application_detail_screen.dart';
import 'task_create_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final DemoTask task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late DemoTask _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  void _setStatus(String newStatus) {
    if (_task.status == newStatus) return;

    final updated = _task.copyWith(
      status: newStatus,
      completedAt: newStatus == 'সম্পন্ন' ? DateTime.now() : null,
    );

    final idx = DemoStore.tasks.indexWhere((t) => t.id == _task.id);
    if (idx != -1) DemoStore.tasks[idx] = updated;

    setState(() => _task = updated);

    Color bg;
    if (newStatus == 'সম্পন্ন') {
      bg = AppColors.emerald;
    } else if (newStatus == 'চলমান') {
      bg = AppColors.primary;
    } else {
      bg = AppColors.amberDark;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('কাজের অবস্থা পরিবর্তিত হয়ে "$newStatus" হয়েছে।'),
        backgroundColor: bg,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _advanceStatus() {
    if (_task.status == 'করতে হবে') {
      _setStatus('চলমান');
    } else if (_task.status == 'চলমান') {
      _setStatus('সম্পন্ন');
    } else {
      _setStatus('করতে হবে');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _task.status == 'সম্পন্ন';
    final isUrgent = _task.priority == 'জরুরি';
    final isToday = _task.isToday;
    final isOverdue = _task.isOverdue;

    DemoApplication? relApp;
    if (_task.relatedApplicationId != null) {
      try {
        relApp = DemoStore.applications.firstWhere((a) => a.id == _task.relatedApplicationId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('কাজের বিস্তারিত'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'সম্পাদনা',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => TaskCreateEditScreen(task: _task),
                ),
              ).then((updated) {
                if (updated is DemoTask) setState(() => _task = updated);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.rose),
            tooltip: 'মুছে ফেলুন',
            onPressed: () async {
              final ok = await ConfirmDialog.show(
                context,
                title: 'কাজটি মুছে ফেলবেন?',
                message: 'এই টাস্কটি তালিকা থেকে স্থায়ীভাবে মুছে যাবে।',
                confirmText: 'মুছুন',
                isDestructive: true,
              );
              if (ok == true) {
                DemoStore.tasks.removeWhere((t) => t.id == _task.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // 3-Stage Interactive Status Stepper
          _buildStatusStepper(),

          const SizedBox(height: AppSpacing.base),

          // Main Task Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.04),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent ? AppColors.roseSurface : AppColors.slate100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(color: isUrgent ? AppColors.roseLight : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUrgent ? Icons.priority_high : Icons.flag_outlined,
                            size: 13,
                            color: isUrgent ? AppColors.rose : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _task.priority,
                            style: AppTypography.labelMedium.copyWith(
                              color: isUrgent ? AppColors.rose : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.emeraldSurface
                            : (_task.status == 'চলমান' ? AppColors.primarySurface : AppColors.amberSurface),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(
                          color: isDone
                              ? AppColors.emeraldLight
                              : (_task.status == 'চলমান' ? AppColors.primaryLight : AppColors.amberLight),
                        ),
                      ),
                      child: Text(
                        _task.status,
                        style: AppTypography.labelMedium.copyWith(
                          color: isDone
                              ? AppColors.emeraldDark
                              : (_task.status == 'চলমান' ? AppColors.primary : AppColors.amberDark),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Today / Overdue Alert
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          'আজকের কাজ',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.roseSurface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          'মেয়াদোত্তীর্ণ',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.rose, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  _task.title,
                  style: AppTypography.headingMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),

                if (_task.description != null && _task.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _task.description!,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                // Due Date & Time Strip
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      BengaliDigits.toBengali('${_task.dueDate.day}/${_task.dueDate.month}/${_task.dueDate.year}'),
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (_task.dueTime != null) ...[
                      const SizedBox(width: 14),
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.slate500),
                      const SizedBox(width: 4),
                      Text(
                        _task.dueTime!,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Linked Application or Personal Task Card
          if (relApp != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'সংশ্লিষ্ট আবেদন ফাইল',
                        style: AppTypography.titleMedium.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              relApp.applicantName,
                              style: AppTypography.headingSmall.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${relApp.workType} • মৌজা: ${relApp.mouza}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            Text(
                              'কেস: ${relApp.caseNumber ?? relApp.appNumber ?? 'নির্ধারিত নয়'}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.slate400, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text('ফাইল দেখুন'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: AppColors.primarySurface,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => ApplicationDetailScreen(application: relApp!)),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.person_outline, color: AppColors.slate600, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ব্যক্তিগত কাজ',
                          style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'নির্দিষ্ট কোনো আবেদন ফাইলের সাথে যুক্ত নয়',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ],

          // Primary Status Transition Action
          AppButton(
            text: isDone
                ? 'পুনরায় কাজ শুরু করুন (করতে হবে)'
                : (_task.status == 'চলমান' ? 'কাজ সম্পন্ন চিহ্নিত করুন ✓' : 'কাজ শুরু করুন (চলমান চিহ্নিত করুন) ➔'),
            icon: isDone ? Icons.refresh : ( _task.status == 'চলমান' ? Icons.check_circle : Icons.play_arrow),
            variant: isDone ? ButtonVariant.outline : ButtonVariant.primary,
            onPressed: _advanceStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper() {
    final stages = [
      {'key': 'করতে হবে', 'label': 'করতে হবে', 'icon': Icons.schedule},
      {'key': 'চলমান', 'label': 'চলমান', 'icon': Icons.autorenew},
      {'key': 'সম্পন্ন', 'label': 'সম্পন্ন', 'icon': Icons.check_circle},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: stages.map((st) {
          final isCurrent = _task.status == st['key'];
          Color chipColor;
          if (st['key'] == 'সম্পন্ন') {
            chipColor = AppColors.emerald;
          } else if (st['key'] == 'চলমান') {
            chipColor = AppColors.primary;
          } else {
            chipColor = AppColors.amberDark;
          }

          return Expanded(
            child: InkWell(
              onTap: () => _setStatus(st['key'] as String),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent ? chipColor.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isCurrent ? chipColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      st['icon'] as IconData,
                      size: 18,
                      color: isCurrent ? chipColor : AppColors.slate400,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      st['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent ? chipColor : AppColors.textSecondary,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
