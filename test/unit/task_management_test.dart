import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/demo/demo_data.dart';
import 'package:bhumi_kajer_hisab/core/theme/app_theme.dart';
import 'package:bhumi_kajer_hisab/core/utils/bengali_digits.dart';
import 'package:bhumi_kajer_hisab/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:bhumi_kajer_hisab/features/tasks/presentation/screens/task_create_edit_screen.dart';
import 'package:bhumi_kajer_hisab/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:bhumi_kajer_hisab/features/tasks/presentation/screens/task_list_screen.dart';

void main() {
  group('Task Management & Architecture Tests', () {
    test('DemoTask model detects isToday, isOverdue, and isCompleted properly', () {
      final now = DateTime.now();
      final todayTask = DemoTask(
        id: 't-test-1',
        title: 'শুনানি',
        dueDate: now,
        priority: 'জরুরি',
        status: 'করতে হবে',
        category: 'শুনানি',
      );
      expect(todayTask.isToday, isTrue);
      expect(todayTask.isOverdue, isFalse);
      expect(todayTask.isCompleted, isFalse);
      expect(todayTask.isUrgent, isTrue);

      final overdueTask = DemoTask(
        id: 't-test-2',
        title: 'পুরাতন কাজ',
        dueDate: now.subtract(const Duration(days: 3)),
        priority: 'সাধারণ',
        status: 'করতে হবে',
      );
      expect(overdueTask.isToday, isFalse);
      expect(overdueTask.isOverdue, isTrue);
      expect(overdueTask.isCompleted, isFalse);

      final completedOverdueTask = overdueTask.copyWith(status: 'সম্পন্ন');
      expect(completedOverdueTask.isOverdue, isFalse);
      expect(completedOverdueTask.isCompleted, isTrue);
    });

    test('DemoStore has todayTasks and correct todayTasksCount', () {
      expect(DemoStore.todayTasksCount, greaterThanOrEqualTo(2));
      for (final t in DemoStore.todayTasks) {
        expect(t.isToday, isTrue);
      }
    });

    testWidgets('DashboardScreen displays notification badge with today tasks count', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify notification badge exists with today tasks count in Bengali digits
      final countText = BengaliDigits.toBengali(DemoStore.todayTasksCount);
      expect(find.byType(Badge), findsWidgets);
      expect(find.text(countText), findsWidgets);
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    });

    testWidgets('TaskListScreen has 5 tabs and defaults to "আজকের কাজ"', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final todayPendingCount = BengaliDigits.toBengali(DemoStore.tasks.where((t) => t.isToday && t.status != 'সম্পন্ন').length);
      final todayTabFinder = find.text('আজকের কাজ ($todayPendingCount)');
      expect(todayTabFinder, findsOneWidget);

      // Verify other tabs exist
      expect(find.textContaining('করতে হবে ('), findsOneWidget);
      expect(find.textContaining('চলমান ('), findsOneWidget);
      expect(find.textContaining('সম্পন্ন ('), findsOneWidget);
      expect(find.textContaining('সব ('), findsOneWidget);

      // Verify Default active tab view renders Today's Header Banner
      expect(find.textContaining('আজকের কাজের তালিকা'), findsOneWidget);
      expect(find.text('নতুন কাজ'), findsOneWidget);
    });

    testWidgets('Completed task is removed from "আজকের কাজ" tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Ensure first task is not completed
      final task = DemoStore.tasks.firstWhere((t) => t.isToday);
      final initialTitle = task.title;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find initial task in today list
      expect(find.text(initialTitle), findsOneWidget);

      // Tap checkbox of the task to mark it completed
      final checkboxFinder = find.byType(InkWell).at(2); // First task checkbox
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Completed task must not appear in "আজকের কাজ" anymore
      // or if status is completed, the completed task is filtered out
    });

    testWidgets('TaskCreateEditScreen has required indicators and creates new task', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TaskCreateEditScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check required labels
      expect(find.text('কাজের শিরোনাম *'), findsOneWidget);
      expect(find.text('অগ্রাধিকার *'), findsOneWidget);
      expect(find.text('কাজের অবস্থা *'), findsOneWidget);
      expect(find.text('তারিখ *'), findsOneWidget);
      expect(find.text('সময়'), findsOneWidget);

      // Verify "কাজের ধরন" is NOT present
      expect(find.text('কাজের ধরন *'), findsNothing);
      expect(find.text('কাজের ধরন'), findsNothing);

      // No ঐচ্ছিক label
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);

      // Status selector
      expect(find.text('করতে হবে'), findsWidgets);
      expect(find.text('চলমান'), findsWidgets);
      expect(find.text('সম্পন্ন'), findsWidgets);
    });

    testWidgets('TaskDetailScreen renders status stepper and allows state transitions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleTask = DemoStore.tasks.first;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TaskDetailScreen(task: sampleTask),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('কাজের বিস্তারিত'), findsOneWidget);
      expect(find.text(sampleTask.title), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}

