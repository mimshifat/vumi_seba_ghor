import 'package:drift/drift.dart';

import 'applications_table.dart';
import 'status_history_table.dart';

/// জমা ও কিস্তি — আর্থিক অডিট ট্রেইল।
@TableIndex(name: 'idx_payments_application', columns: {#applicationId})
@TableIndex(name: 'idx_payments_date', columns: {#date})
@TableIndex(name: 'idx_payments_active', columns: {#deletedAt})
@TableIndex(name: 'idx_payments_status_history', columns: {#statusHistoryId})
class Payments extends Table {
  @override
  String get tableName => 'payments';

  TextColumn get id => text()();

  /// সংশ্লিষ্ট আবেদন — আবেদন আয় সবসময় একটি ফাইলের সাথে যুক্ত।
  ///
  /// আবেদন কখনো হার্ড ডিলিট হয় না (শুধু সফট ডিলিট), তাই `RESTRICT`
  /// ব্যবহার করা হয়েছে — কখনোই ক্যাশবই অডিট ট্রেইল ভেঙে যাবে না।
  TextColumn get applicationId =>
      text().references(Applications, #id, onDelete: KeyAction.restrict)();

  /// টাকার পরিমাণ (পয়সায়)।
  IntColumn get amount => integer()();

  /// Unix epoch milliseconds।
  IntColumn get date => integer()();

  /// নগদ, বিকাশ, ব্যাংক।
  TextColumn get method => text().withLength(min: 1, max: 40)();

  TextColumn get note => text().nullable()();

  /// স্ট্যাটাস রূপান্তর লিংক।
  TextColumn get statusHistoryId =>
      text().nullable().references(StatusHistory, #id, onDelete: KeyAction.setNull)();

  /// যে ধাপে টাকা গৃহীত হয়েছিল।
  TextColumn get statusName => text().nullable()();

  /// ১ = স্ট্যাটাস ডায়ালগের মাধ্যমে আদায়।
  IntColumn get isStatusFee => integer().withDefault(const Constant(0))();

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
        'CHECK (amount > 0)',
        'CHECK (is_status_fee IN (0, 1))',
      ];
}
