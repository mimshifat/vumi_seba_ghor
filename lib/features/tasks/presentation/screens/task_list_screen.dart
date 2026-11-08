import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/demo/demo_data.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_floating_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../applications/presentation/screens/application_detail_screen.dart';
import 'task_create_edit_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
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

  List<DemoTask> _getTasksForTab(int tabIndex) {
    List<DemoTask> baseList;
    switch (tabIndex) {
      case 0:
        // শুধুমাত্র আজকের অপেক্ষমাণ/চলমান কাজ (সম্পন্ন হলে এখানে আর দেখাবে না)
        baseList = DemoStore.tasks.where((t) => t.isToday && t.status != 'সম্পন্ন').toList();
        break;
      case 1:
        baseList = DemoStore.tasks.where((t) => t.status == 'করতে হবে').toList();
        break;
      case 2:
        baseList = DemoStore.tasks.where((t) => t.status == 'চলমান').toList();
        break;
      case 3:
        baseList = DemoStore.tasks.where((t) => t.status == 'সম্পন্ন').toList();
        break;
      case 4:
      default:
        baseList = DemoStore.tasks;
        break;
    }

    if (_searchQuery.trim().isEmpty) {
      return baseList;
    }

    final query = _searchQuery.trim().toLowerCase();
    return baseList.where((t) {
      final titleMatch = t.title.toLowerCase().contains(query);
      final descMatch = t.description?.toLowerCase().contains(query) ?? false;
      final appMatch = t.relatedApplicantName?.toLowerCase().contains(query) ?? false;
      return titleMatch || descMatch || appMatch;
    }).toList();
  }

  void _toggleTask(DemoTask task) {
    final newStatus = task.status == 'সম্পন্ন' ? 'করতে হবে' : 'সম্পন্ন';
    final updated = task.copyWith(
      status: newStatus,
      completedAt: newStatus == 'সম্পন্ন' ? DateTime.now() : null,
    );
    final idx = DemoStore.tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      setState(() => DemoStore.tasks[idx] = updated);
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'সম্পন্ন'
              ? 'কাজটি সম্পন্ন চিহ্নিত করা হয়েছে।'
              : 'কাজটি পুনরায় সক্রিয় করা হয়েছে।',
        ),
        backgroundColor: newStatus == 'সম্পন্ন' ? AppColors.emerald : AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _changeTaskStatus(DemoTask task, String newStatus) {
    if (task.status == newStatus) return;
    final updated = task.copyWith(
      status: newStatus,
      completedAt: newStatus == 'সম্পন্ন' ? DateTime.now() : null,
    );
    final idx = DemoStore.tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      setState(() => DemoStore.tasks[idx] = updated);
    }
  }

  void _deleteTask(DemoTask task) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'কাজটি মুছে ফেলবেন?',
      message: 'এই টাস্কটি তালিকা থেকে স্থায়ীভাবে মুছে ফেলা হবে।',
      confirmText: 'মুছুন',
      isDestructive: true,
    );
    if (ok == true) {
      setState(() {
        DemoStore.tasks.removeWhere((t) => t.id == task.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = DemoStore.tasks.where((t) => t.isToday && t.status != 'সম্পন্ন').length;
    final pendingCount = DemoStore.tasks.where((t) => t.status == 'করতে হবে').length;
    final ongoingCount = DemoStore.tasks.where((t) => t.status == 'চলমান').length;
    final completedCount = DemoStore.tasks.where((t) => t.status == 'সম্পন্ন').length;
    final allCount = DemoStore.tasks.length;

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
                  hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
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
        icon: Icons.add_task,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const TaskCreateEditScreen()),
          ).then((_) => setState(() {}));
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (index) => _buildTaskList(index)),
      ),
    );
  }

  Widget _buildTaskList(int tabIndex) {
    final tasks = _getTasksForTab(tabIndex);

    if (tasks.isEmpty) {
      String emptyTitle;
      String emptyMsg;
      if (tabIndex == 0) {
        final allTodayCount = DemoStore.tasks.where((t) => t.isToday).length;
        if (allTodayCount > 0) {
          emptyTitle = 'আজকের সব কাজ সম্পন্ন! 🎉';
          emptyMsg = 'আজকের জন্য নির্ধারিত সব কাজ সম্পন্ন হয়েছে। সম্পন্ন কাজ দেখতে "সম্পন্ন" ট্যাবে যান।';
        } else {
          emptyTitle = 'আজকের কোনো কাজ নেই';
          emptyMsg = 'আজকের জন্য কোনো কাজ নির্ধারিত নেই। নতুন কাজ যোগ করতে নিচে বাটন চাপুন।';
        }
      } else if (tabIndex == 1) {
        emptyTitle = 'অপেক্ষমাণ কোনো কাজ নেই';
        emptyMsg = 'করতে হবে এমন কোনো টাস্ক বাকি নেই।';
      } else if (tabIndex == 2) {
        emptyTitle = 'চলমান কোনো কাজ নেই';
        emptyMsg = 'বর্তমানে কোনো কাজ চলমান অবস্থায় নেই।';
      } else if (tabIndex == 3) {
        emptyTitle = 'কোনো সম্পন্ন কাজ নেই';
        emptyMsg = 'এখনো কোনো টাস্ক সম্পন্ন হিসেবে চিহ্নিত করা হয়নি।';
      } else {
        emptyTitle = 'কোনো কাজ পাওয়া যায়নি';
        emptyMsg = 'নতুন টাস্ক বা রিমাইন্ডার যুক্ত করুন।';
      }

      return EmptyState(
        icon: tabIndex == 0 ? Icons.check_circle_outline : Icons.task_alt,
        title: emptyTitle,
        message: emptyMsg,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 80),
      itemCount: tasks.length + (tabIndex == 0 ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (tabIndex == 0 && i == 0) {
          return _buildTodayHeaderBanner(tasks);
        }
        final taskIndex = tabIndex == 0 ? i - 1 : i;
        final t = tasks[taskIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildTaskCard(t),
        );
      },
    );
  }

  Widget _buildTodayHeaderBanner(List<DemoTask> pendingTodayTasks) {
    final allToday = DemoStore.tasks.where((t) => t.isToday).toList();
    final totalToday = allToday.length;
    final doneToday = allToday.where((t) => t.isCompleted).length;
    final remainingToday = pendingTodayTasks.length;
    final now = DateTime.now();
    final dateStr = BengaliDigits.toBengali('${now.day}/${now.month}/${now.year}');

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
                  style: AppTypography.titleMedium.copyWith(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
                Text(
                  'মোট ${BengaliDigits.toBengali(totalToday)} টি কাজের মধ্যে ${BengaliDigits.toBengali(doneToday)} টি সম্পন্ন',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: remainingToday == 0 ? AppColors.emerald : AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              remainingToday == 0 ? 'সব শেষ ✓' : '${BengaliDigits.toBengali(remainingToday)} টি বাকি',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(DemoTask t) {
    final isDone = t.status == 'সম্পন্ন';
    final isUrgent = t.priority == 'জরুরি';
    final isToday = t.isToday;
    final isOverdue = t.isOverdue;

    // Status strip color
    Color statusColor;
    if (isDone) {
      statusColor = AppColors.emerald;
    } else if (isUrgent || isOverdue) {
      statusColor = AppColors.rose;
    } else if (t.status == 'চলমান') {
      statusColor = AppColors.primary;
    } else {
      statusColor = AppColors.amber;
    }

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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Accent Bar
                  Container(
                    width: 4.5,
                    color: statusColor,
                  ),

                  // Main Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tactile Checkbox
                          InkWell(
                            onTap: () => _toggleTask(t),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 2),
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
                                // Badges Row
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    // Today Tag
                                    if (isToday)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurface,
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                        ),
                                        child: Text(
                                          'আজকের কাজ',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                    // Overdue Tag
                                    if (isOverdue)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.roseSurface,
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                        ),
                                        child: Text(
                                          'মেয়াদোত্তীর্ণ',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.rose,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                    // Urgent Tag
                                    if (isUrgent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.roseSurface,
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                        ),
                                        child: Text(
                                          'জরুরি',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.rose,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                    // Status Badge (Interactive)
                                    PopupMenuButton<String>(
                                      onSelected: (newStatus) => _changeTaskStatus(t, newStatus),
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'করতে হবে', child: Text('করতে হবে')),
                                        const PopupMenuItem(value: 'চলমান', child: Text('চলমান')),
                                        const PopupMenuItem(value: 'সম্পন্ন', child: Text('সম্পন্ন')),
                                      ],
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? AppColors.emeraldSurface
                                              : (t.status == 'চলমান' ? AppColors.primarySurface : AppColors.amberSurface),
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              t.status,
                                              style: AppTypography.labelMedium.copyWith(
                                                color: isDone
                                                    ? AppColors.emeraldDark
                                                    : (t.status == 'চলমান' ? AppColors.primary : AppColors.amberDark),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              size: 13,
                                              color: isDone ? AppColors.emeraldDark : AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // Title
                                Text(
                                  t.title,
                                  style: AppTypography.headingSmall.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                                  ),
                                ),

                                // Description snippet
                                if (t.description != null && t.description!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    t.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],

                                // Linked Application Chip or Personal Task
                                if (t.relatedApplicantName != null) ...[
                                  const SizedBox(height: 5),
                                  InkWell(
                                    onTap: () {
                                      if (t.relatedApplicationId != null) {
                                        try {
                                          final app = DemoStore.applications.firstWhere((a) => a.id == t.relatedApplicationId);
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (ctx) => ApplicationDetailScreen(application: app)),
                                          );
                                        } catch (_) {}
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.link, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            t.relatedApplicantName!,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 12, color: AppColors.slate400),
                                      const SizedBox(width: 3),
                                      Text(
                                        'ব্যক্তিগত কাজ',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.slate500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 8),

                                // Date & Time Strip
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.slate400),
                                    const SizedBox(width: 4),
                                    Text(
                                      BengaliDigits.toBengali('${t.dueDate.day}/${t.dueDate.month}/${t.dueDate.year}'),
                                      style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.slate600),
                                    ),
                                    if (t.dueTime != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.slate400),
                                      const SizedBox(width: 3),
                                      Text(
                                        t.dueTime!,
                                        style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.slate600),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Context Menu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.slate400),
                            onSelected: (val) {
                              if (val == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (ctx) => TaskCreateEditScreen(task: t)),
                                ).then((_) => setState(() {}));
                              } else if (val == 'delete') {
                                _deleteTask(t);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text('সম্পাদনা করুন'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 16, color: AppColors.rose),
                                    SizedBox(width: 8),
                                    Text('মুছে ফেলুন', style: TextStyle(color: AppColors.rose)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
