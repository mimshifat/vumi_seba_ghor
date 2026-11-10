import 'package:drift/drift.dart';

/// প্রস্তাব প্রেরণ PDF প্রিন্ট / জমা ব্যাচ লগ।
///
/// একবারে যে কেসগুলো PDF করে প্রিন্ট বা অফিসে জমা দেওয়া হয়, তার একটি ব্যাচ রেকর্ড।
@DataClassName('ProposalPrintBatch')
@TableIndex(
  name: 'idx_proposal_print_batches_active',
  columns: {#deletedAt},
)
@TableIndex(
  name: 'idx_proposal_print_batches_printed_at',
  columns: {#printedAt},
)
class ProposalPrintBatches extends Table {
  @override
  String get tableName => 'proposal_print_batches';

  TextColumn get id => text()();

  TextColumn get title => text().nullable()();

  /// অফিস ফিল্টার প্রয়োগ করে প্রিন্ট করা হলে অফিসের নাম।
  TextColumn get officeFilter => text().nullable()();

  /// প্রিন্ট / জমা সম্পন্ন হওয়ার Unix epoch milliseconds।
  IntColumn get printedAt => integer()();

  /// ব্যাচে মোট অন্তর্ভুক্ত কেস সংখ্যা।
  IntColumn get itemCount => integer()();

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
        'CHECK (item_count > 0)',
      ];
}

