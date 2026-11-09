import 'package:drift/drift.dart';

import 'applications_table.dart';

/// সংযুক্ত ফাইল — সফট ডিলিট সাপোর্টেড।
@TableIndex(name: 'idx_documents_application', columns: {#applicationId})
@TableIndex(name: 'idx_documents_active', columns: {#deletedAt})
class Documents extends Table {
  @override
  String get tableName => 'documents';

  TextColumn get id => text()();

  /// সংশ্লিষ্ট আবেদন — ফাইল সবসময় একটি ফাইলের সাথে যুক্ত।
  TextColumn get applicationId =>
      text().references(Applications, #id, onDelete: KeyAction.restrict)();

  TextColumn get fileName => text().withLength(min: 1, max: 255)();

  /// 'pdf' বা 'image'।
  TextColumn get fileType => text().withLength(min: 1, max: 20)();

  /// বাইনারি ডেটা।
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

  @override
  List<String> get customConstraints => [
        "CHECK (file_type IN ('pdf', 'image'))",
      ];
}
