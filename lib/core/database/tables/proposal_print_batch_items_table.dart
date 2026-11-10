import 'package:drift/drift.dart';

import 'applications_table.dart';
import 'proposal_print_batches_table.dart';
import 'status_history_table.dart';

/// প্রস্তাব প্রেরণ প্রিন্ট ব্যাচের প্রতিটি আবেদনের আইটেম ও স্ন্যাপশট।
///
/// `statusHistoryId` যুক্ত থাকায় কোনো আবেদন পরবর্তীতে অন্য অবস্থায় গিয়ে
/// আবার 'প্রস্তাব প্রেরণ'-এ এলে নতুন `StatusHistory` এন্ট্রির ভিত্তিতে সেটি
/// পুনরায় প্রিন্টের তালিকায় চলে আসে।
@DataClassName('ProposalPrintBatchItem')
@TableIndex(
  name: 'idx_proposal_batch_items_active',
  columns: {#deletedAt},
)
@TableIndex(
  name: 'idx_proposal_batch_items_batch',
  columns: {#batchId},
)
@TableIndex(
  name: 'idx_proposal_batch_items_app',
  columns: {#applicationId},
)
@TableIndex(
  name: 'idx_proposal_batch_items_status_history',
  columns: {#statusHistoryId},
)
class ProposalPrintBatchItems extends Table {
  @override
  String get tableName => 'proposal_print_batch_items';

  TextColumn get id => text()();

  TextColumn get batchId => text().references(
        ProposalPrintBatches,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get applicationId => text().references(
        Applications,
        #id,
        onDelete: KeyAction.restrict,
      )();

  TextColumn get statusHistoryId => text().nullable().references(
        StatusHistory,
        #id,
        onDelete: KeyAction.setNull,
      )();

  /// প্রিন্টের সময়কার আবেদনকারীর নামের স্ন্যাপশট।
  TextColumn get applicantNameSnapshot => text().withLength(min: 1, max: 120)();

  /// প্রিন্টের সময়কার কেস নম্বরের স্ন্যাপশট।
  TextColumn get caseNumberSnapshot => text().nullable()();

  /// প্রিন্টের সময়কার ভূমি অফিসের নামের স্ন্যাপশট।
  TextColumn get officeNameSnapshot => text().nullable()();

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
        'CHECK (length(trim(applicant_name_snapshot)) > 0)',
      ];
}

