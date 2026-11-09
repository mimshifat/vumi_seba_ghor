import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/providers/application_providers.dart';
import '../../../applications/presentation/screens/application_detail_screen.dart';
import '../providers/task_providers.dart';
import 'task_create_edit_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Default select index 0 ("আজকের কাজ")
    _tabController = TabController(length: 5, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DemoTask _toDemoTask(
      Task t, List<dynamic> allApps) {
    String? appName;
    if (t.applicationId != null) {
      for (final item in allApps) {
        if (item.application.id == t.applicationId) {
          appName = item.application.applicantName;
          break;
        }
      }
    }
    return DemoTask(
      id: t.id,
      title: t.title,
      description: t.description,
      dueDate: DateTime.fromMillisecondsSinceEpoch(t.dueDate),
      dueTime: t.dueTime,
      priority: t.priority,
      status: t.status,
      category: t.category,
      relatedApplicationId: t.applicationId,
      relatedApplicantName: appName,
      completedAt: t.completedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(t.completedAt!)
          : null,
    );
  }

  List<DemoTask> _getTasksForTab(
      int tabIndex, List<DemoTask> allTasks) {
    List<DemoTask> baseList;
    switch (tabIndex) {
      case 0:
        baseList = allTasks.where((t) => t.isToday && t.status != 'সম্পন্ন').toList();
        break;
      case 1:
        baseList = allTasks.where((t) => t.status == 'করতে হবে').toList();
        break;
      case 2:
        baseList = allTasks.where((t) => t.status == 'চলমান').toList();
        break;
      case 3:
        baseList = allTasks.where((t) => t.status == 'সম্পন্ন').toList();
        break;
      case 4:
      default:
        baseList = allTasks;
        break;
    }

    if (_searchQuery.trim().isEmpty) {
      return baseList;
    }

    final query = _searchQuery.trim().toLowerCase();
    return baseList.where((t) {
      final titleMatch = t.title.toLowerCase().contains(query);
      final descMatch = t.description?.toLowerCase().contains(query) ?? false;
      final appMatch =
          t.relatedApplicantName?.toLowerCase().contains(query) ?? false;
      return titleMatch || descMatch || appMatch;
    }).toList();
  }

  Future<void> _toggleTask(DemoTask task) async {
    final newStatus = task.status == 'সম্পন্ন' ? 'করতে হবে' : 'সম্পন্ন';

    await ref
        .read(taskControllerProvider.notifier)
        .markCompleted(task.id, newStatus == 'সম্পন্ন');

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'সম্পন্ন'
              ? 'কাজটি সম্পন্ন চিহ্নিত করা হয়েছে।'
              : 'কাজটি পুনরায় সক্রিয় করা হয়েছে।',
        ),
        backgroundColor:
            newStatus == 'সম্পন্ন' ? AppColors.emerald : AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _changeTaskStatus(DemoTask task, String newStatus) async {
    if (task.status == newStatus) return;

    await ref.read(taskControllerProvider.notifier).updateTask(
          id: task.id,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate,
          dueTime: task.dueTime,
          priority: task.priority,
          status: newStatus,
          category: task.category,
          applicationId: task.relatedApplicationId,
        );
  }

  Future<void> _deleteTask(DemoTask task) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'কাজটি মুছে ফেলবেন?',
      message: 'এই টাস্কটি তালিকা থেকে স্থায়ীভাবে মুছে ফেলা হবে।',
      confirmText: 'মুছুন',
      isDestructive: true,
    );
    if (ok == true) {
      await ref.read(taskControllerProvider.notifier).deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawTasksAsync = ref.watch(tasksStreamProvider);
    final rawTasks = rawTasksAsync.valueOrNull ?? const [];

    final allAppsAsync = ref.watch(applicationsWithFinancialsStreamProvider);
    final allApps = allAppsAsync.valueOrNull ?? const [];

    final allTasks = rawTasks.map((t) => _toDemoTask(t, allApps)).toList();

    final todayCount =
        allTasks.where((t) => t.isToday && t.status != 'সম্পন্ন').length;
    final pendingCount = allTasks.where((t) => t.status == 'করতে হবে').length;
    final ongoingCount = allTasks.where((t) => t.status == 'চলমান').length;
    final completedCount = allTasks.where((t) => t.status == 'সম্পন্ন').length;
    final allCount = allTasks.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'কাজের নাম, ক্যাটাগরি বা গ্রাহক খুঁজুন...',
                  border: InputBorder.none,
                  hintStyle:
                      TextStyle(color: AppColors.slate400, fontSize: 14),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('করণীয় কাজ ও রিমাইন্ডার'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'অনুসন্ধান বন্ধ' : 'অনুসন্ধান করুন',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
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
              indicatorWeight: 3,
              labelStyle: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              unselectedLabelStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'আজকের কাজ (${BengaliDigits.toBengali(todayCount)})'),
                Tab(text: 'করতে হবে (${BengaliDigits.toBengali(pendingCount)})'),
                Tab(text: 'চলমান (${BengaliDigits.toBengali(ongoingCount)})'),
                Tab(text: 'সম্পন্ন (${BengaliDigits.toBengali(completedCount)})'),
                Tab(text: 'সব (${BengaliDigits.toBengali(allCount)})'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: AppFloatingButton(
        label: 'নতুন কাজ',
        icon: Icons.add,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (ctx) => const TaskCreateEditScreen()),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(0, allTasks),
          _buildTaskList(1, allTasks),
          _buildTaskList(2, allTasks),
          _buildTaskList(3, allTasks),
          _buildTaskList(4, allTasks),
        ],
      ),
    );
  }

  Widget _buildTaskList(int tabIndex, List<DemoTask> allTasks) {
    final tasks = _getTasksForTab(tabIndex, allTasks);

    if (tasks.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'কোনো কাজ পাওয়া যায়নি',
          message: '"$_searchQuery" অনুসন্ধানের সাথে মেলে এমন কোনো কাজ নেই।',
        );
      }
      return _buildEmptyStateForTab(tabIndex, allTasks);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.base, AppSpacing.base, 90),
      itemCount: tasks.length + (tabIndex == 0 ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (tabIndex == 0 && i == 0) {
          return _buildTodayHeaderBanner(tasks, allTasks);
        }
        final taskIndex = tabIndex == 0 ? i - 1 : i;
        final task = tasks[taskIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildTaskCard(task),
        );
      },
    );
  }

  Widget _buildTodayHeaderBanner(
      List<DemoTask> pendingTodayTasks, List<DemoTask> allTasks) {
    final allToday = allTasks.where((t) => t.isToday).toList();
    final totalToday = allToday.length;
    final doneToday = allToday.where((t) => t.isCompleted).length;
    final remainingToday = pendingTodayTasks.length;
    final now = DateTime.now();
    final dateStr =
        BengaliDigits.toBengali('${now.day}/${now.month}/${now.year}');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.today, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আজকের কাজের তালিকা ($dateStr)',
                  style: AppTypography.titleMedium.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark),
                ),
                Text(
                  'মোট ${BengaliDigits.toBengali(totalToday)} টি কাজের মধ্যে ${BengaliDigits.toBengali(doneToday)} টি সম্পন্ন',
                  style: AppTypography.bodySmall
                      .copyWith(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  remainingToday == 0 ? AppColors.emerald : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'বাকি ${BengaliDigits.toBengali(remainingToday)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateForTab(int tabIndex, List<DemoTask> allTasks) {
    String title;
    String message;
    IconData icon;

    switch (tabIndex) {
      case 0:
        final allTodayCount = allTasks.where((t) => t.isToday).length;
        if (allTodayCount > 0) {
          title = 'আজকের সব কাজ সম্পন্ন হয়েছে!';
          message =
              'অভিনন্দন! আজকের নির্ধারিত সকল কাজ আপনি সফলভাবে শেষ করেছেন।';
          icon = Icons.task_alt_rounded;
        } else {
          title = 'আজকের কোনো কাজ নির্ধারিত নেই';
          message =
              'আজকের জন্য কোনো শুনানির নোটিশ বা রিমাইন্ডার বাকি নেই। নতুন কাজ যোগ করতে নিচের বাটনে চাপ দিন।';
          icon = Icons.event_available;
        }
        break;
      case 1:
        title = 'করতে হবে এমন কোনো কাজ নেই';
        message = 'নতুন কোনো কাজ যুক্ত করতে "+" বাটনে চাপ দিন।';
        icon = Icons.assignment_turned_in_outlined;
        break;
      case 2:
        title = 'কোনো চলমান কাজ নেই';
        message = 'যে কাজগুলো বর্তমানে প্রসেস চলছে সেগুলো এখানে দেখাবে।';
        icon = Icons.sync_disabled_rounded;
        break;
      case 3:
        title = 'এখনো কোনো কাজ সম্পন্ন হয়নি';
        message = 'কাজ সম্পন্ন হলে চেকমার্কে টিক দিয়ে সম্পন্ন করুন।';
        icon = Icons.check_circle_outline;
        break;
      case 4:
      default:
        title = 'টাস্ক তালিকা খালি';
        message = 'আপনার গুরুত্বপূর্ণ কাজ ও শুনানির রিমাইন্ডার যোগ করুন।';
        icon = Icons.checklist_rtl_rounded;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              title,
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (tabIndex == 0) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: const Text('আজ সম্পন্ন হওয়া কাজগুলো দেখুন'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                onPressed: () {
                  _tabController.animateTo(3); // Go to completed tab
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(DemoTask task) {
    final allApps =
        ref.watch(applicationsWithFinancialsStreamProvider).valueOrNull ?? [];
    final isDone = task.status == 'সম্পন্ন';
    final isOverdue = task.isOverdue;
    final isToday = task.isToday;

    Color priorityColor;
    switch (task.priority) {
      case 'জরুরি':
        priorityColor = AppColors.rose;
        break;
      case 'মাঝারি':
        priorityColor = const Color(0xFFF59E0B);
        break;
      case 'সাধারণ':
      default:
        priorityColor = AppColors.primary;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => TaskDetailScreen(taskId: task.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isOverdue && !isDone
                  ? AppColors.rose.withValues(alpha: 0.5)
                  : (isDone ? AppColors.slate200 : AppColors.border),
              width: isOverdue && !isDone ? 1.5 : 1.0,
            ),
            boxShadow: isDone
                ? null
                : [
                    const BoxShadow(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox to toggle done
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: isDone,
                        activeColor: AppColors.emerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onChanged: (_) => _toggleTask(task),
                      ),
                    ),
                  ),

                  // Title and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? AppColors.slate400
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description!,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: isDone
                                  ? AppColors.slate400
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Menu popup
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: AppColors.slate400),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) =>
                                TaskCreateEditScreen(task: task),
                          ),
                        );
                      } else if (val == 'delete') {
                        _deleteTask(task);
                      } else if (val.startsWith('status:')) {
                        _changeTaskStatus(
                            task, val.replaceFirst('status:', ''));
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('সম্পাদনা করুন',
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text(
                          'অবস্থা পরিবর্তন:',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate400),
                        ),
                      ),
                      if (task.status != 'করতে হবে')
                        const PopupMenuItem(
                          value: 'status:করতে হবে',
                          child: Text('করতে হবে',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                      if (task.status != 'চলমান')
                        const PopupMenuItem(
                          value: 'status:চলমান',
                          child:
                              Text('চলমান', style: TextStyle(fontSize: 12.5)),
                        ),
                      if (task.status != 'সম্পন্ন')
                        const PopupMenuItem(
                          value: 'status:সম্পন্ন',
                          child:
                              Text('সম্পন্ন', style: TextStyle(fontSize: 12.5)),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 16, color: AppColors.rose),
                            SizedBox(width: 8),
                            Text('মুছে ফেলুন',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.rose)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Badges Row
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Due Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOverdue && !isDone
                          ? const Color(0xFFFFF1F2)
                          : (isToday && !isDone
                              ? const Color(0xFFFEF3C7)
                              : AppColors.slate100),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                      border: Border.all(
                        color: isOverdue && !isDone
                            ? const Color(0xFFFECDD3)
                            : (isToday && !isDone
                                ? const Color(0xFFFDE68A)
                                : Colors.transparent),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: isOverdue && !isDone
                              ? AppColors.rose
                              : (isToday && !isDone
                                  ? const Color(0xFFB45309)
                                  : AppColors.slate600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isToday
                              ? 'আজ (${BengaliDigits.toBengali('${task.dueDate.day}/${task.dueDate.month}')})'
                              : (isOverdue && !isDone
                                  ? 'সময় উত্তীর্ণ (${BengaliDigits.toBengali('${task.dueDate.day}/${task.dueDate.month}')})'
                                  : BengaliDigits.toBengali(
                                      '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}')),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOverdue && !isDone
                                ? AppColors.rose
                                : (isToday && !isDone
                                    ? const Color(0xFFB45309)
                                    : AppColors.slate600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Due Time badge if exists
                  if (task.dueTime != null &&
                      task.dueTime!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: AppColors.slate600),
                          const SizedBox(width: 3),
                          Text(
                            task.dueTime!,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.slate600),
                          ),
                        ],
                      ),
                    ),

                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Text(
                      task.category,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w500),
                    ),
                  ),

                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: priorityColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: task.status == 'সম্পন্ন'
                          ? AppColors.emeraldSurface
                          : (task.status == 'চলমান'
                              ? const Color(0xFFEEF2FF)
                              : AppColors.slate100),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: task.status == 'সম্পন্ন'
                            ? AppColors.emerald
                            : (task.status == 'চলমান'
                                ? const Color(0xFF4338CA)
                                : AppColors.textSecondary),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Linked Application Link if present
              if (task.relatedApplicationId != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    final appMatch = allApps
                        .where((a) =>
                            a.application.id == task.relatedApplicationId)
                        .firstOrNull;
                    if (appMatch != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => ApplicationDetailScreen(
                              application: appMatch.toDemoApplication()),
                        ),
                      );
                    }
                  },
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'আবেদন: ${task.relatedApplicantName ?? task.relatedApplicationId}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
