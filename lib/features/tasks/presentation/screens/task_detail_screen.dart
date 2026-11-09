import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../applications/presentation/screens/application_detail_screen.dart';
import '../providers/task_providers.dart';
import 'task_create_edit_screen.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final DemoTask? task;
  final String? taskId;

  const TaskDetailScreen({
    super.key,
    this.task,
    this.taskId,
  }) : assert(task != null || taskId != null, 'Provide either task or taskId');

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  String get _id => widget.taskId ?? widget.task!.id;

  Future<void> _setStatus(String newStatus, DemoTask currentTask) async {
    if (currentTask.status == newStatus) return;

    if (newStatus == 'সম্পন্ন') {
      await ref.read(taskControllerProvider.notifier).markCompleted(_id, true);
    } else {
      await ref.read(taskControllerProvider.notifier).updateTask(
            id: _id,
            title: currentTask.title,
            description: currentTask.description,
            dueDate: currentTask.dueDate,
            dueTime: currentTask.dueTime,
            priority: currentTask.priority,
            status: newStatus,
            category: currentTask.category,
            applicationId: currentTask.relatedApplicationId,
          );
      if (currentTask.status == 'সম্পন্ন') {
        await ref
            .read(taskControllerProvider.notifier)
            .markCompleted(_id, false);
      }
    }

    Color bg;
    if (newStatus == 'সম্পন্ন') {
      bg = AppColors.emerald;
    } else if (newStatus == 'চলমান') {
      bg = AppColors.primary;
    } else {
      bg = AppColors.amberDark;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('কাজের অবস্থা পরিবর্তিত হয়ে "$newStatus" হয়েছে।'),
        backgroundColor: bg,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _advanceStatus(DemoTask currentTask) {
    if (currentTask.status == 'করতে হবে') {
      _setStatus('চলমান', currentTask);
    } else if (currentTask.status == 'চলমান') {
      _setStatus('সম্পন্ন', currentTask);
    } else {
      _setStatus('করতে হবে', currentTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveTask = ref.watch(taskDetailProvider(_id)).valueOrNull;
    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];

    DemoTask task;
    if (liveTask != null) {
      String? appName;
      if (liveTask.applicationId != null) {
        final match = allApps
            .where((a) => a.application.id == liveTask.applicationId)
            .firstOrNull;
        appName = match?.application.applicantName;
      }
      task = DemoTask(
        id: liveTask.id,
        title: liveTask.title,
        description: liveTask.description,
        dueDate: DateTime.fromMillisecondsSinceEpoch(liveTask.dueDate),
        dueTime: liveTask.dueTime,
        priority: liveTask.priority,
        status: liveTask.status,
        category: liveTask.category,
        relatedApplicationId: liveTask.applicationId,
        relatedApplicantName: appName,
        completedAt: liveTask.completedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(liveTask.completedAt!)
            : null,
      );
    } else if (widget.task != null) {
      task = widget.task!;
    } else {
      task = DemoTask(
        id: _id,
        title: 'লোড হচ্ছে...',
        dueDate: DateTime.now(),
        priority: 'সাধারণ',
        status: 'করতে হবে',
        category: 'সাধারণ',
      );
    }

    final isDone = task.status == 'সম্পন্ন';
    final isUrgent = task.priority == 'জরুরি';
    final isToday = task.isToday;
    final isOverdue = task.isOverdue;

    DemoApplication? relApp;
    if (task.relatedApplicationId != null) {
      final match = allApps
          .where((a) => a.application.id == task.relatedApplicationId)
          .firstOrNull;
      relApp = match?.toDemoApplication();
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
                  builder: (ctx) => TaskCreateEditScreen(task: task),
                ),
              );
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
                await ref
                    .read(taskControllerProvider.notifier)
                    .deleteTask(task.id);
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
          // Header Status Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDone ? const Color(0xFFBBF7D0) : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? const Color(0xFFFFF1F2)
                            : (task.priority == 'মাঝারি'
                                ? const Color(0xFFFEF3C7)
                                : AppColors.slate100),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isUrgent
                              ? AppColors.rose
                              : (task.priority == 'মাঝারি'
                                  ? const Color(0xFFB45309)
                                  : AppColors.slate700),
                        ),
                      ),
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.emeraldSurface
                            : (task.status == 'চলমান'
                                ? const Color(0xFFEEF2FF)
                                : AppColors.slate100),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        task.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDone
                              ? AppColors.emerald
                              : (task.status == 'চলমান'
                                  ? const Color(0xFF4338CA)
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  task.title,
                  style: AppTypography.headingMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.slate400 : AppColors.textPrimary,
                  ),
                ),

                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    task.description!,
                    style: AppTypography.bodyMedium.copyWith(
                      color:
                          isDone ? AppColors.slate400 : AppColors.slate700,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.base),
                const Divider(),
                const SizedBox(height: AppSpacing.xs),

                // Date & Time Row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isOverdue && !isDone
                          ? AppColors.rose
                          : AppColors.slate500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'তারিখ: ${BengaliDigits.toBengali('${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOverdue && !isDone
                            ? AppColors.rose
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                        child: const Text(
                          'আজ',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (task.dueTime != null && task.dueTime!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          size: 16, color: AppColors.slate500),
                      const SizedBox(width: 6),
                      Text(
                        task.dueTime!,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Linked Application (if any)
          if (relApp != null)
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
                  const Text(
                    'সংশ্লিষ্ট আবেদন ফাইল',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) =>
                              ApplicationDetailScreen(application: relApp!),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.folder_open_rounded,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  relApp.applicantName,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${relApp.workType} • ${relApp.officeName}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.base),

          // Status Action Buttons
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
                const Text(
                  'অবস্থা দ্রুত পরিবর্তন করুন',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusBtn(
                        label: 'করতে হবে',
                        isSelected: task.status == 'করতে হবে',
                        color: AppColors.textSecondary,
                        onTap: () => _setStatus('করতে হবে', task),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusBtn(
                        label: 'চলমান',
                        isSelected: task.status == 'চলমান',
                        color: const Color(0xFF4338CA),
                        onTap: () => _setStatus('চলমান', task),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusBtn(
                        label: 'সম্পন্ন',
                        isSelected: task.status == 'সম্পন্ন',
                        color: AppColors.emerald,
                        onTap: () => _setStatus('সম্পন্ন', task),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Big Advance Action Button
          AppButton(
            text: isDone
                ? 'কাজটি পুনরায় সক্রিয় করুন'
                : (task.status == 'করতে হবে'
                    ? 'কাজটি চলমান করুন'
                    : 'কাজটি সম্পন্ন চিহ্নিত করুন'),
            icon: isDone ? Icons.refresh : Icons.check_circle_outline,
            variant: isDone ? ButtonVariant.secondary : ButtonVariant.primary,
            onPressed: () => _advanceStatus(task),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBtn({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.slate50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
