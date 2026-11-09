import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';

/// কাজের ট্যাব ফিল্টার: 'today' (আজকের কাজ), 'ongoing' (চলমান), 'todo' (করতে হবে), 'completed' (সম্পন্ন), 'all' (সব)
final taskTabFilterProvider = StateProvider<String>((ref) => 'today');

/// ডেটাবেজ থেকে সকল কাজের রিয়েক্টিভ ওয়াচ
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasks();
});

/// নির্বাচিত ট্যাব অনুযায়ী কাজের ফিল্টার্ড তালিকা
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final asyncTasks = ref.watch(tasksStreamProvider);
  final currentTab = ref.watch(taskTabFilterProvider);

  return asyncTasks.when(
    data: (tasks) {
      final now = DateTime.now();
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch;

      switch (currentTab) {
        case 'today':
          // আজকের বা ওভারডিউ কাজ যা এখনো সম্পন্ন হয়নি
          return tasks.where((t) {
            return t.status != 'সম্পন্ন' && t.dueDate <= endOfToday;
          }).toList();

        case 'ongoing':
          return tasks.where((t) => t.status == 'চলমান').toList();

        case 'todo':
          return tasks.where((t) => t.status == 'করতে হবে').toList();

        case 'completed':
          return tasks.where((t) => t.status == 'সম্পন্ন').toList();

        case 'all':
        default:
          return tasks;
      }
    },
    loading: () => const [],
    error: (_, __) => const [],
  );
});

/// আজকের অথবা বকেয়া অবশিষ্ট অসমাপ্ত কাজের সংখ্যা (ড্যাশবোর্ড ব্যাজের জন্য)
final todayTasksCountProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getTodayTasksCount();
});

/// নির্দিষ্ট একক কাজের রিয়েক্টিভ ওয়াচ
final taskDetailProvider = StreamProvider.family<Task?, String>((ref, id) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTask(id);
});

/// কাজ মিউটেশন কন্ট্রোলার (সেফটি লক সহ)
class TaskController extends MutationController {
  final TaskRepository _repo;

  TaskController(this._repo);

  /// নতুন কাজ সংযোজন
  Future<Task?> createTask({
    String? id,
    required String title,
    String? description,
    required DateTime dueDate,
    String? dueTime,
    String priority = 'সাধারণ',
    String status = 'করতে হবে',
    String category = 'সাধারণ',
    String? applicationId,
  }) {
    return execute(() => _repo.createTask(
          id: id,
          title: title,
          description: description,
          dueDate: dueDate,
          dueTime: dueTime,
          priority: priority,
          status: status,
          category: category,
          applicationId: applicationId,
        ));
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
  }) {
    return execute(() => _repo.updateTask(
          id: id,
          title: title,
          description: description,
          dueDate: dueDate,
          dueTime: dueTime,
          priority: priority,
          status: status,
          category: category,
          applicationId: applicationId,
        ));
  }

  /// কাজ সম্পন্ন চিহ্নিতকরণ
  Future<void> markCompleted(String id, bool completed) {
    return execute(() => _repo.markCompleted(id, completed));
  }

  /// অপ্রয়োজনীয় বা বাতিল কাজ সরাসরি হার্ড ডিলিট (BACKEND_MASTER_PLAN.md §1.3)
  Future<void> deleteTask(String id) {
    return execute(() => _repo.deleteTask(id));
  }
}

/// কাজ কন্ট্রোলার প্রোভাইডার
final taskControllerProvider =
    StateNotifierProvider<TaskController, AsyncValue<void>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return TaskController(repo);
});

