import 'package:drift/drift.dart';

import 'applications_table.dart';

/// করণীয় কাজ ও শুনানি।
@TableIndex(name: 'idx_tasks_due_date', columns: {#dueDate})
@TableIndex(name: 'idx_tasks_status', columns: {#status})
@TableIndex(name: 'idx_tasks_application', columns: {#applicationId})
@TableIndex(name: 'idx_tasks_active', columns: {#deletedAt})
class Tasks extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();

  TextColumn get title => text().withLength(min: 1, max: 160)();

  TextColumn get description => text().nullable()();

  /// Unix epoch milliseconds।
  IntColumn get dueDate => integer()();

  /// প্রদর্শনের সময় (যেমন: সকাল ১০:০০)।
  TextColumn get dueTime => text().nullable()();

  /// 'জরুরি' বা 'সাধারণ'।
  TextColumn get priority =>
      text().withLength(min: 1, max: 20).withDefault(const Constant('সাধারণ'))();

  /// 'করতে হবে', 'চলমান', 'সম্পন্ন'।
  TextColumn get status =>
      text().withLength(min: 1, max: 20).withDefault(const Constant('করতে হবে'))();

  /// ৬টি ক্যাটাগরি।
  TextColumn get category =>
      text().withLength(min: 1, max: 40).withDefault(const Constant('সাধারণ'))();

  TextColumn get applicationId =>
      text().nullable().references(Applications, #id, onDelete: KeyAction.setNull)();

  /// Unix epoch milliseconds।
  IntColumn get completedAt => integer().nullable()();

  /// Unix epoch milliseconds।
  IntColumn get createdAt => integer()();

  /// Unix epoch milliseconds।
  IntColumn get updatedAt => integer()();

  /// সফট ডিলিট টাইমস্ট্যাম্প। NULL মানে রেকর্ড সক্রিয়।
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (priority IN ('জরুরি', 'সাধারণ'))",
        "CHECK (status IN ('করতে হবে', 'চলমান', 'সম্পন্ন'))",
        'CHECK (length(trim(title)) > 0)',
      ];
}
