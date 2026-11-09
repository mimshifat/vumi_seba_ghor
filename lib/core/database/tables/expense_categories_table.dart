import 'package:drift/drift.dart';

/// খরচের খাত — কাস্টমাইজযোগ্য ক্যাটাগরি।
class ExpenseCategories extends Table {
  @override
  String get tableName => 'expense_categories';

  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// ১ = দোকানের সাধারণ খরচের খাত।
  IntColumn get isGeneral => integer().withDefault(const Constant(0))();

  /// ১ = অ্যাপের সাথে আসা ডিফল্ট ক্যাটাগরি।
  IntColumn get isDefault => integer().withDefault(const Constant(0))();

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
        'CHECK (length(trim(name)) > 0)',
        'CHECK (is_general IN (0, 1))',
        'CHECK (is_default IN (0, 1))',
      ];
}
