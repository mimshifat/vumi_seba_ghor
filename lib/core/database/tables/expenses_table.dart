import 'package:drift/drift.dart';

import 'applications_table.dart';
import 'status_history_table.dart';

/// খরচ — অডিট ট্রেইল।
@TableIndex(name: 'idx_expenses_application', columns: {#applicationId})
@TableIndex(name: 'idx_expenses_date', columns: {#date})
@TableIndex(name: 'idx_expenses_category', columns: {#category})
@TableIndex(name: 'idx_expenses_active', columns: {#deletedAt})
@TableIndex(name: 'idx_expenses_status_history', columns: {#statusHistoryId})
class Expenses extends Table {
  @override
  String get tableName => 'expenses';

  TextColumn get id => text()();

  /// আবেদন খরচ হলে আইডি; সাধারণ দোকান খরচ হলে NULL।
  TextColumn get applicationId =>
      text().nullable().references(Applications, #id, onDelete: KeyAction.setNull)();

  /// টাকার পরিমাণ (পয়সায়)।
  IntColumn get amount => integer()();

  TextColumn get category => text().withLength(min: 1, max: 80)();

  /// Unix epoch milliseconds।
  IntColumn get date => integer()();

  /// ০ = ফাইলের খরচ; ১ = দোকানের খরচ।
  IntColumn get isGeneral => integer().withDefault(const Constant(0))();

  TextColumn get note => text().nullable()();

  /// স্ট্যাটাস রূপান্তর লিংক।
  TextColumn get statusHistoryId =>
      text().nullable().references(StatusHistory, #id, onDelete: KeyAction.setNull)();

  /// যে ধাপে খরচ হয়েছিল।
  TextColumn get statusName => text().nullable()();

  /// ১ = স্ট্যাটাস পরিবর্তন ডায়ালগ থেকে তৈরি।
  IntColumn get isStatusExp => integer().withDefault(const Constant(0))();

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
        'CHECK (is_general IN (0, 1))',
        'CHECK (is_status_exp IN (0, 1))',
        // সাধারণ দোকান খরচ কখনো আবেদনের সাথে যুক্ত থাকতে পারে না।
        'CHECK (is_general = 0 OR application_id IS NULL)',
        // আবেদনের খরচের জন্য আবেদনের রেফারেন্স আবশ্যক — অন্যথায় সেই
        // রোকটি ভিউ ও ফাইল-ভিত্তিক হিসাবে কোথাও ধরা পড়ে না।
        'CHECK (is_general = 1 OR application_id IS NOT NULL)',
      ];
}
