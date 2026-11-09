import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/applications_table.dart';
import '../tables/tasks_table.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks, Applications])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// ফিল্টারসহ কাজের রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<Task>> watchTasks({
    String? status,
    String? priority,
    String? category,
    int? startDueDate,
    int? endDueDate,
    String? applicationId,
    bool includeDeleted = false,
  }) {
    return _buildTasksQuery(
      status: status,
      priority: priority,
      category: category,
      startDueDate: startDueDate,
      endDueDate: endDueDate,
      applicationId: applicationId,
      includeDeleted: includeDeleted,
    ).watch();
  }

  /// কাজের তালিকা সংগ্রহ (Future)
  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    String? category,
    int? startDueDate,
    int? endDueDate,
    String? applicationId,
    bool includeDeleted = false,
  }) {
    return _buildTasksQuery(
      status: status,
      priority: priority,
      category: category,
      startDueDate: startDueDate,
      endDueDate: endDueDate,
      applicationId: applicationId,
      includeDeleted: includeDeleted,
    ).get();
  }

  SimpleSelectStatement<$TasksTable, Task> _buildTasksQuery({
    String? status,
    String? priority,
    String? category,
    int? startDueDate,
    int? endDueDate,
    String? applicationId,
    bool includeDeleted = false,
  }) {
    final query = select(tasks);

    query.where((tbl) {
      final predicates = <Expression<bool>>[];

      if (!includeDeleted) {
        predicates.add(tbl.deletedAt.isNull());
      }

      if (status != null && status.isNotEmpty) {
        predicates.add(tbl.status.equals(status));
      }

      if (priority != null && priority.isNotEmpty) {
        predicates.add(tbl.priority.equals(priority));
      }

      if (category != null && category.isNotEmpty) {
        predicates.add(tbl.category.equals(category));
      }

      if (startDueDate != null) {
        predicates.add(tbl.dueDate.isBiggerOrEqualValue(startDueDate));
      }

      if (endDueDate != null) {
        predicates.add(tbl.dueDate.isSmallerOrEqualValue(endDueDate));
      }

      if (applicationId != null && applicationId.isNotEmpty) {
        predicates.add(tbl.applicationId.equals(applicationId));
      }

      return predicates.isEmpty
          ? const Constant(true)
          : Expression.and(predicates);
    });

    query.orderBy([
      (t) => OrderingTerm.asc(t.dueDate),
      (t) => OrderingTerm.desc(t.priority),
    ]);

    return query;
  }

  /// নির্দিষ্ট আইডি অনুযায়ী কাজ খোঁজা
  Future<Task?> getTaskById(String id, {bool includeDeleted = false}) {
    final query = select(tasks)..where((tbl) => tbl.id.equals(id));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// নির্দিষ্ট কাজের রিয়েক্টিভ ওয়াচ
  Stream<Task?> watchTaskById(String id) {
    final query = select(tasks)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// নতুন কাজ সংযোজন
  Future<int> insertTask(TasksCompanion companion) {
    return into(tasks).insert(companion);
  }

  /// কাজ আপডেট
  Future<bool> updateTask(TasksCompanion companion) {
    return update(tasks).replace(companion);
  }

  /// কাজ সম্পন্ন চিহ্নিতকরণ বা পুনরায় সক্রিয়করণ
  Future<int> markTaskCompleted(String id, bool completed) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        status: Value(completed ? 'সম্পন্ন' : 'করতে হবে'),
        completedAt: Value(completed ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  /// অপ্রয়োজনীয় বা বাতিল কাজ সরাসরি হার্ড ডিলিট (BACKEND_MASTER_PLAN.md §1.3)
  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// সফট ডিলিট (যদি অডিট রাখতে হয়)
  Future<int> softDeleteTask(String id, {int? timestamp}) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    return (update(tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// আজকের অথবা বকেয়া অবশিষ্ট অসমাপ্ত কাজের সংখ্যা (ড্যাশবোর্ড ব্যাজের জন্য)
  Future<int> getTodayTasksCount() async {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    final countCol = tasks.id.count();
    final query = selectOnly(tasks)
      ..addColumns([countCol])
      ..where(tasks.deletedAt.isNull() &
          tasks.status.isNotValue('সম্পন্ন') &
          tasks.dueDate.isSmallerOrEqualValue(endOfToday));

    final row = await query.getSingle();
    return row.read(countCol) ?? 0;
  }
}

