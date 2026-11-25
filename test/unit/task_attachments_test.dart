import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/database/repository_providers.dart';
import 'package:bhumi_kajer_hisab/core/widgets/full_screen_image_viewer.dart';
import 'package:bhumi_kajer_hisab/features/tasks/presentation/providers/task_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Task Attachments Database & Repository Tests', () {
    test('Can create task and add image attachments, query and delete them', () async {
      final taskRepo = TaskRepository(db);

      // Create a task
      final task = await taskRepo.createTask(
        title: 'রেকর্ড সংশোধন শুনানি',
        description: 'কাগজপত্রের ছবি যুক্ত',
        dueDate: DateTime.now(),
        priority: 'জরুরি',
        status: 'করতে হবে',
      );

      expect(task.id, isNotEmpty);

      // Add image attachment
      final fakeBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final attachment = await taskRepo.addTaskAttachment(
        taskId: task.id,
        fileName: 'khatian_scan.jpg',
        fileData: fakeBytes,
        fileSize: '150 KB',
      );

      expect(attachment.id, isNotEmpty);
      expect(attachment.taskId, equals(task.id));
      expect(attachment.fileName, equals('khatian_scan.jpg'));
      expect(attachment.fileType, equals('image'));
      expect(attachment.fileData, equals(fakeBytes));

      // Get attachments
      final list = await taskRepo.getTaskAttachments(task.id);
      expect(list.length, equals(1));
      expect(list.first.fileName, equals('khatian_scan.jpg'));

      // Delete attachment
      await taskRepo.deleteTaskAttachment(attachment.id);
      final emptyList = await taskRepo.getTaskAttachments(task.id);
      expect(emptyList.isEmpty, isTrue);
    });

    test('TaskController integrates with TaskRepository for attachments', () async {
      final taskRepo = TaskRepository(db);
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskRepo),
        ],
      );

      final task = await taskRepo.createTask(
        title: 'ভূমি অফিসে যাওয়া',
        dueDate: DateTime.now(),
      );

      final controller = container.read(taskControllerProvider.notifier);
      final fakeBytes = Uint8List.fromList([10, 20, 30]);

      final att = await controller.addTaskAttachment(
        taskId: task.id,
        fileName: 'slip.png',
        fileData: fakeBytes,
        fileSize: '50 KB',
      );

      expect(att, isNotNull);
      expect(att!.fileName, equals('slip.png'));

      final list = await taskRepo.getTaskAttachments(task.id);
      expect(list.length, equals(1));

      await controller.deleteTaskAttachment(id: att.id, taskId: task.id);
      final afterDelete = await taskRepo.getTaskAttachments(task.id);
      expect(afterDelete.isEmpty, isTrue);

      container.dispose();
    });
  });

  group('FullScreenImageViewer Widget Tests', () {
    testWidgets('Renders interactive viewer with zoom controls and pinch guide',
        (tester) async {
      // Create a 1x1 transparent PNG byte array
      final dummyBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            imageBytes: dummyBytes,
            title: 'দলিল_পৃষ্ঠা_১.jpg',
            subtitle: '২.৫ MB',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('দলিল_পৃষ্ঠা_১.jpg'), findsOneWidget);
      expect(find.text('২.৫ MB'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('জুম করতে দুটি আঙুল দিয়ে টানুন বা ডাবল ট্যাপ করুন'), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
    });
  });
}
