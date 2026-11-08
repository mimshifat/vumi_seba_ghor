import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/empty_state.dart';
import 'task_create_edit_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DemoTask> _getTasksForTab(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return DemoStore.tasks.where((t) => t.status == 'করতে হবে').toList();
      case 2:
        return DemoStore.tasks.where((t) => t.status == 'চলমান').toList();
      case 3:
        return DemoStore.tasks.where((t) => t.status == 'সম্পন্ন').toList();
      default:
        return DemoStore.tasks;
    }
  }

  void _toggleTask(DemoTask task) {
    final newStatus = task.status == 'সম্পন্ন' ? 'করতে হবে' : 'সম্পন্ন';
    final updated = DemoTask(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      priority: task.priority,
      status: newStatus,
      relatedApplicationId: task.relatedApplicationId,
      relatedApplicantName: task.relatedApplicantName,
    );
    final idx = DemoStore.tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      setState(() => DemoStore.tasks[idx] = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('করণীয় কাজ ও রিমাইন্ডার'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              tabs: [
                Tab(text: 'সব (${BengaliDigits.toBengali(DemoStore.tasks.length)})'),
                Tab(text: 'করতে হবে (${BengaliDigits.toBengali(DemoStore.tasks.where((t) => t.status == 'করতে হবে').length)})'),
                Tab(text: 'চলমান (${BengaliDigits.toBengali(DemoStore.tasks.where((t) => t.status == 'চলমান').length)})'),
                Tab(text: 'সম্পন্ন (${BengaliDigits.toBengali(DemoStore.tasks.where((t) => t.status == 'সম্পন্ন').length)})'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const TaskCreateEditScreen()),
          ).then((_) => setState(() {}));
        },
        icon: const Icon(Icons.add_task),
        label: const Text('নতুন কাজ'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (index) => _buildTaskList(index)),
      ),
    );
  }

  Widget _buildTaskList(int tabIndex) {
    final tasks = _getTasksForTab(tabIndex);

    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt,
        title: 'কোনো কাজ নেই',
        message: 'নতুন টাস্ক বা রিমাইন্ডার যুক্ত করুন।',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 80),
      itemCount: tasks.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (ctx, i) {
        final t = tasks[i];
        final isDone = t.status == 'সম্পন্ন';
        final isUrgent = t.priority == 'জরুরি';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => TaskDetailScreen(task: t)),
              ).then((_) => setState(() {}));
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  InkWell(
                    onTap: () => _toggleTask(t),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.emerald : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: isDone ? AppColors.emerald : AppColors.slate400,
                          width: 1.8,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isUrgent) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.roseSurface,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                ),
                                child: Text(
                                  'জরুরি',
                                  style: AppTypography.labelMedium.copyWith(color: AppColors.rose, fontSize: 10.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDone ? AppColors.emeraldSurface : AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                              ),
                              child: Text(
                                t.status,
                                style: AppTypography.labelMedium.copyWith(
                                  color: isDone ? AppColors.emeraldDark : AppColors.primary,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.title,
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                            color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                          ),
                        ),
                        if (t.relatedApplicantName != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.link, size: 12, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                t.relatedApplicantName!,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.slate400),
                            const SizedBox(width: 4),
                            Text(
                              BengaliDigits.toBengali('${t.dueDate.day}/${t.dueDate.month}/${t.dueDate.year}'),
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                            ),
                            if (t.dueTime != null) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.access_time, size: 12, color: AppColors.slate400),
                              const SizedBox(width: 3),
                              Text(t.dueTime!, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

