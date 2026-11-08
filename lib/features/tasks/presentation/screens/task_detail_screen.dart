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

  void _toggleStatus() {
    String nextStatus;
    if (_task.status == 'করতে হবে') {
      nextStatus = 'চলমান';
    } else if (_task.status == 'চলমান') {
      nextStatus = 'সম্পন্ন';
    } else {
      nextStatus = 'করতে হবে';
    }

    final updated = DemoTask(
      id: _task.id,
      title: _task.title,
      description: _task.description,
      dueDate: _task.dueDate,
      dueTime: _task.dueTime,
      priority: _task.priority,
      status: nextStatus,
      relatedApplicationId: _task.relatedApplicationId,
      relatedApplicantName: _task.relatedApplicantName,
    );

    final idx = DemoStore.tasks.indexWhere((t) => t.id == _task.id);
    if (idx != -1) DemoStore.tasks[idx] = updated;

    setState(() => _task = updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('কাজের অবস্থা পরিবর্তিত হয়ে "$nextStatus" হয়েছে।'),
        backgroundColor: nextStatus == 'সম্পন্ন' ? AppColors.emerald : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _task.status == 'সম্পন্ন';
    final isUrgent = _task.priority == 'জরুরি';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('কাজের বিস্তারিত'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
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
          // Main Task Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent ? AppColors.roseSurface : AppColors.slate100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(color: isUrgent ? AppColors.roseLight : AppColors.border),
                      ),
                      child: Row(
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
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.emeraldSurface : AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        _task.status,
                        style: AppTypography.labelMedium.copyWith(
                          color: isDone ? AppColors.emeraldDark : AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _task.title,
                  style: AppTypography.headingMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (_task.description != null && _task.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _task.description!,
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.alarm, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'তারিখ ও সময়: ${BengaliDigits.toBengali('${_task.dueDate.day}/${_task.dueDate.month}/${_task.dueDate.year}')} ${_task.dueTime != null ? '(${_task.dueTime})' : ''}',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Linked Application (if any)
          if (_task.relatedApplicationId != null) ...[
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
                  Text(
                    'যুক্ত আবেদন',
                    style: AppTypography.titleMedium.copyWith(fontSize: 13, color: AppColors.textMuted),
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
                        child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _task.relatedApplicantName ?? 'আবেদন',
                              style: AppTypography.headingSmall.copyWith(fontSize: 14.5, fontWeight: FontWeight.bold),
                            ),
                            Builder(
                              builder: (context) {
                                final relApp = DemoStore.applications.cast<DemoApplication?>().firstWhere(
                                  (a) => a?.id == _task.relatedApplicationId,
                                  orElse: () => null,
                                );
                                final label = relApp?.appNumber != null && relApp!.appNumber!.isNotEmpty
                                    ? 'আবেদন নং: ${relApp.appNumber}'
                                    : (relApp?.caseNumber != null && relApp!.caseNumber!.isNotEmpty
                                        ? 'কেস নং: ${relApp.caseNumber}'
                                        : 'সংযুক্ত ফাইল');
                                return Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary));
                              },
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          try {
                            final app = DemoStore.applications.firstWhere((a) => a.id == _task.relatedApplicationId);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => ApplicationDetailScreen(application: app)),
                            );
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('আবেদনটি খুঁজে পাওয়া যায়নি')),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text('আবেদন দেখুন'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ],

          // Toggle Status Action
          AppButton(
            text: isDone ? 'পুনরায় খুলুন (করতে হবে)' : 'কাজটি সম্পন্ন চিহ্নিত করুন',
            icon: isDone ? Icons.refresh : Icons.check_circle_outline,
            variant: isDone ? ButtonVariant.outline : ButtonVariant.primary,
            onPressed: _toggleStatus,
          ),
        ],
      ),
    );
  }
}
