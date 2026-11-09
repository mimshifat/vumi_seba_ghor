import 'package:drift/drift.dart';

/// ভূমি অফিস — সফট ডিলিট সাপোর্টেড।
class Offices extends Table {
  @override
  String get tableName => 'offices';

  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 160)();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// সফট ডিলিট টাইমস্ট্যাম্প। NULL মানে রেকর্ড সক্রিয়।
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (length(trim(name)) > 0)',
      ];
}
