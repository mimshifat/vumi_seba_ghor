import 'package:drift/drift.dart';

/// গ্রাহক খাতা (Customer ledger) — সফট ডিলিট সাপোর্টেড।
class Persons extends Table {
  @override
  String get tableName => 'persons';

  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get phone => text().withLength(min: 1, max: 20)();

  TextColumn get address => text().nullable()();

  BlobColumn get photo => blob().nullable()();

  TextColumn get notes => text().nullable()();

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
