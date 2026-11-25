import 'package:drift/drift.dart';

import 'tasks_table.dart';

/// কাজের সাথে সংযুক্ত ছবি (Task Attachments) — সফট ডিলিট সাপোর্টেড।
@TableIndex(name: 'idx_task_attachments_task', columns: {#taskId})
@TableIndex(name: 'idx_task_attachments_active', columns: {#deletedAt})
class TaskAttachments extends Table {
  @override
  String get tableName => 'task_attachments';

  TextColumn get id => text()();

  /// সংশ্লিষ্ট কাজ — টাস্কের সাথে যুক্ত।
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();

  TextColumn get fileName => text().withLength(min: 1, max: 255)();

  /// 'image'
  TextColumn get fileType =>
      text().withLength(min: 1, max: 20).withDefault(const Constant('image'))();

  /// ছবির বাইনারি ডেটা।
  BlobColumn get fileData => blob()();

  TextColumn get fileSize => text().withLength(min: 1, max: 32)();

  /// Unix epoch milliseconds।
  IntColumn get createdAt => integer()();

  /// Unix epoch milliseconds।
  IntColumn get updatedAt => integer()();

  /// সফট ডিলিট টাইমস্ট্যাম্প। NULL মানে রেকর্ড সক্রিয়।
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
