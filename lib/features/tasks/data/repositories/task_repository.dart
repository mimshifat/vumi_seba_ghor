import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';

/// করণীয় কাজ ও শুনানি রিপোজিটরি (BACKEND_MASTER_PLAN.md §1.3, §5)
class TaskRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  TaskRepository(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

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
    return _db.taskDao.watchTasks(
      status: status,
      priority: priority,
      category: category,
      startDueDate: startDueDate,
      endDueDate: endDueDate,
      applicationId: applicationId,
      includeDeleted: includeDeleted,
    );
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
  }) async {
    try {
      return await _db.taskDao.getTasks(
        status: status,
        priority: priority,
        category: category,
        startDueDate: startDueDate,
        endDueDate: endDueDate,
        applicationId: applicationId,
        includeDeleted: includeDeleted,
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট কাজ সংগ্রহ
  Future<Task?> getTask(String id, {bool includeDeleted = false}) async {
    try {
      return await _db.taskDao.getTaskById(id, includeDeleted: includeDeleted);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট কাজের রিয়েক্টিভ ওয়াচ
  Stream<Task?> watchTask(String id) {
    return _db.taskDao.watchTaskById(id);
  }

  /// নতুন কাজ তৈরি
  Future<Task> createTask({
    String? id,
    required String title,
    String? description,
    required DateTime dueDate,
    String? dueTime,
    String priority = 'সাধারণ',
    String status = 'করতে হবে',
    String category = 'সাধারণ',
    String? applicationId,
  }) async {
    try {
      final cleanTitle = title.trim();
      if (cleanTitle.isEmpty) {
        throw AppFailure.requiredField('কাজের শিরোনাম');
      }

      final taskId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final dueMs = dueDate.millisecondsSinceEpoch;

      await _db.taskDao.insertTask(
        TasksCompanion.insert(
          id: taskId,
          title: cleanTitle,
          description: Value(description?.trim()),
          dueDate: dueMs,
          dueTime: Value(dueTime?.trim()),
          priority: Value(priority),
          status: Value(status),
          category: Value(category),
          applicationId: Value(applicationId),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final created = await _db.taskDao.getTaskById(taskId);
      return created!;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// কাজ আপডেট
  Future<void> updateTask({
    required String id,
    required String title,
    String? description,
    required DateTime dueDate,
    String? dueTime,
    required String priority,
    required String status,
    required String category,
    String? applicationId,
  }) async {
    try {
      final cleanTitle = title.trim();
      if (cleanTitle.isEmpty) {
        throw AppFailure.requiredField('কাজের শিরোনাম');
      }

      final existing = await _db.taskDao.getTaskById(id);
      if (existing == null) {
        throw AppFailure.custom('কাজটি খুঁজে পাওয়া যায়নি।');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final dueMs = dueDate.millisecondsSinceEpoch;

      await _db.taskDao.updateTask(
        TasksCompanion(
          id: Value(id),
          title: Value(cleanTitle),
          description: Value(description?.trim()),
          dueDate: Value(dueMs),
          dueTime: Value(dueTime?.trim()),
          priority: Value(priority),
          status: Value(status),
          category: Value(category),
          applicationId: Value(applicationId),
          completedAt: Value(status == 'সম্পন্ন' ? (existing.completedAt ?? now) : null),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
          deletedAt: Value(existing.deletedAt),
        ),
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// কাজ সম্পন্ন চিহ্নিতকরণ বা পুনরায় খুলুন
  Future<void> markCompleted(String id, bool completed) async {
    try {
      await _db.taskDao.markTaskCompleted(id, completed);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// কাজ সরাসরি হার্ড ডিলিট (BACKEND_MASTER_PLAN.md §1.3)
  Future<void> deleteTask(String id) async {
    try {
      await _db.taskDao.deleteTask(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// আজকের বা বকেয়া অবশিষ্ট অসমাপ্ত কাজের সংখ্যা
  Future<int> getTodayTasksCount() async {
    try {
      return await _db.taskDao.getTodayTasksCount();
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// আজকের বা বকেয়া অবশিষ্ট অসমাপ্ত কাজের লাইভ স্ট্রিম
  Stream<int> watchTodayTasksCount() {
    return _db.taskDao.watchTodayTasksCount();
  }
}

