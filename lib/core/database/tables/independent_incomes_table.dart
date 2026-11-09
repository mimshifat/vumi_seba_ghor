import 'package:drift/drift.dart';

/// স্বতন্ত্র দোকান আয় — কখনো আবেদনের সাথে মিশ্রণ হবে না।
@TableIndex(name: 'idx_independent_incomes_date', columns: {#date})
@TableIndex(name: 'idx_independent_incomes_category', columns: {#category})
@TableIndex(name: 'idx_independent_incomes_active', columns: {#deletedAt})
class IndependentIncomes extends Table {
  @override
  String get tableName => 'independent_incomes';

  TextColumn get id => text()();

  TextColumn get category => text().withLength(min: 1, max: 80)();

  /// টাকার পরিমাণ (পয়সায়)।
  IntColumn get amount => integer()();

  /// Unix epoch milliseconds।
  IntColumn get date => integer()();

  TextColumn get paymentMethod => text().withLength(min: 1, max: 40)();

  TextColumn get customerName => text().nullable()();

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
        'CHECK (amount > 0)',
      ];
}
