import 'package:drift/drift.dart';

import 'application_statuses.dart';
import 'applications_table.dart';

/// অবস্থা পরিবর্তন লগ — অ্যাপেন্ড-অনলি অডিট ট্রেইল।
@TableIndex(name: 'idx_status_history_application', columns: {#applicationId})
@TableIndex(name: 'idx_status_history_changed_at', columns: {#changedAt})
class StatusHistory extends Table {
  @override
  String get tableName => 'status_history';

  TextColumn get id => text()();

  /// সংশ্লিষ্ট আবেদন — স্ট্যাটাস লগ সবসময় একটি ফাইলের সাথে যুক্ত।
  TextColumn get applicationId =>
      text().references(Applications, #id, onDelete: KeyAction.restrict)();

  /// পূর্বের অবস্থা — প্রথম এন্ট্রিতে (নতুন আবেদন) কোনো পূর্বের অবস্থা
  /// থাকে না, তাই NULL গ্রহণযোগ্য।
  TextColumn get prevStatus => text().nullable()();

  TextColumn get newStatus => text().withLength(min: 1, max: 40)();

  /// Unix epoch milliseconds।
  IntColumn get changedAt => integer()();

  TextColumn get note => text().nullable()();

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
        // পূর্বের অবস্থা NULL হতে পারে (প্রথম এন্ট্রি), তবে বৈধ তালিকার
        // বাইরে কোনো অবস্থা লেখা যাবে না।
        'CHECK (prev_status IS NULL OR prev_status IN '
            '(${ApplicationStatuses.sqlList}))',
        'CHECK (new_status IN (${ApplicationStatuses.sqlList}))',
      ];
}
