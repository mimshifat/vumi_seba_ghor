import 'package:drift/drift.dart';

import '../../../features/applications/domain/models/proposal_print_models.dart';
import '../app_database.dart';

part 'proposal_print_dao.g.dart';

@DriftAccessor(tables: [
  Applications,
  StatusHistory,
  ProposalPrintBatches,
  ProposalPrintBatchItems,
])
class ProposalPrintDao extends DatabaseAccessor<AppDatabase>
    with _$ProposalPrintDaoMixin {
  ProposalPrintDao(super.db);

  static const String _pendingSql = '''
    SELECT
      a.*,
      sh.id AS latest_status_history_id,
      COALESCE(sh.changed_at, a.updated_at) AS status_entered_at
    FROM applications a
    LEFT JOIN status_history sh ON sh.id = (
      SELECT sh2.id
      FROM status_history sh2
      WHERE sh2.application_id = a.id
        AND sh2.new_status = 'প্রস্তাব প্রেরণ'
        AND (sh2.prev_status IS NULL OR sh2.prev_status != 'প্রস্তাব প্রেরণ')
        AND sh2.deleted_at IS NULL
      ORDER BY sh2.changed_at DESC, sh2.created_at DESC
      LIMIT 1
    )
    WHERE a.deleted_at IS NULL
      AND a.status = 'প্রস্তাব প্রেরণ'
      AND NOT EXISTS (
        SELECT 1
        FROM proposal_print_batch_items pbi
        INNER JOIN proposal_print_batches pb ON pb.id = pbi.batch_id
        WHERE pbi.application_id = a.id
          AND pbi.deleted_at IS NULL
          AND pb.deleted_at IS NULL
          AND (
            (sh.id IS NOT NULL AND pbi.status_history_id = sh.id)
            OR (sh.id IS NULL AND pbi.status_history_id IS NULL)
          )
      )
    ORDER BY COALESCE(sh.changed_at, a.updated_at) DESC, a.created_at DESC;
  ''';

  /// এখনো প্রিন্ট/জমা হয়নি এমন 'প্রস্তাব প্রেরণ' আবেদনসমূহের রিয়েক্টিভ স্ট্রিম।
  Stream<List<PendingProposalCandidate>> watchPendingProposals() {
    return customSelect(
      _pendingSql,
      readsFrom: {
        applications,
        statusHistory,
        proposalPrintBatches,
        proposalPrintBatchItems,
      },
    ).watch().map(_mapPendingRows);
  }

  /// এখনো প্রিন্ট/জমা হয়নি এমন 'প্রস্তাব প্রেরণ' আবেদনসমূহের তালিকা।
  Future<List<PendingProposalCandidate>> getPendingProposals() async {
    final rows = await customSelect(
      _pendingSql,
      readsFrom: {
        applications,
        statusHistory,
        proposalPrintBatches,
        proposalPrintBatchItems,
      },
    ).get();
    return _mapPendingRows(rows);
  }

  List<PendingProposalCandidate> _mapPendingRows(List<QueryRow> rows) {
    return rows.map((row) {
      final app = applications.map(row.data);
      final shId = row.readNullable<String>('latest_status_history_id');
      final enteredAt = row.read<int>('status_entered_at');
      return PendingProposalCandidate(
        application: app,
        statusHistoryId: shId,
        statusEnteredAt: enteredAt,
      );
    }).toList();
  }

  /// নির্দিষ্ট আবেদনের সর্বশেষ 'প্রস্তাব প্রেরণ' প্রবেশের `StatusHistory` আইডি।
  Future<String?> getLatestProposalEntryHistoryId(String applicationId) async {
    final rows = await customSelect(
      '''
      SELECT id
      FROM status_history
      WHERE application_id = ?
        AND new_status = 'প্রস্তাব প্রেরণ'
        AND (prev_status IS NULL OR prev_status != 'প্রস্তাব প্রেরণ')
        AND deleted_at IS NULL
      ORDER BY changed_at DESC, created_at DESC
      LIMIT 1;
      ''',
      variables: [Variable.withString(applicationId)],
      readsFrom: {statusHistory},
    ).get();

    if (rows.isEmpty) return null;
    return rows.first.read<String>('id');
  }

  /// নির্দিষ্ট `(applicationId, statusHistoryId)` ইতিমধ্যে সক্রিয়ভাবে প্রিন্ট হয়েছে কিনা।
  Future<bool> isAlreadyPrintedForEntry(
    String applicationId,
    String? statusHistoryId,
  ) async {
    final rows = await customSelect(
      '''
      SELECT 1 AS found
      FROM proposal_print_batch_items pbi
      INNER JOIN proposal_print_batches pb ON pb.id = pbi.batch_id
      WHERE pbi.application_id = ?
        AND pbi.deleted_at IS NULL
        AND pb.deleted_at IS NULL
        AND (
          (? IS NOT NULL AND pbi.status_history_id = ?)
          OR (? IS NULL AND pbi.status_history_id IS NULL)
        )
      LIMIT 1;
      ''',
      variables: [
        Variable.withString(applicationId),
        Variable(statusHistoryId),
        Variable(statusHistoryId),
        Variable(statusHistoryId),
      ],
      readsFrom: {proposalPrintBatches, proposalPrintBatchItems},
    ).get();

    return rows.isNotEmpty;
  }

  /// কেস নম্বর ছাড়া প্রিন্ট হয়ে যাওয়া কোনো আবেদনে পরে কেস নম্বর যোগ হলে
  /// সেটিকে পুনরায় 'প্রিন্ট বাকি' তালিকায় ফিরিয়ে আনা।
  Future<void> requeueIfPrintedWithoutCaseNumber(String applicationId) async {
    final items = await (select(proposalPrintBatchItems)
          ..where(
            (t) =>
                t.applicationId.equals(applicationId) &
                t.caseNumberSnapshot.isNull() &
                t.deletedAt.isNull(),
          ))
        .get();

    for (final item in items) {
      await softDeleteBatchItem(item.id);
    }
  }

  /// পূর্বে প্রিন্ট/জমা হওয়া ব্যাচগুলোর রিয়েক্টিভ স্ট্রিম (সর্বশেষ আগে)।
  Stream<List<ProposalBatchWithItems>> watchPrintedBatches() {
    final batchesQuery = select(proposalPrintBatches)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.printedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

    return batchesQuery.watch().asyncMap((batches) async {
      if (batches.isEmpty) return const [];
      final batchIds = batches.map((b) => b.id).toList();
      final items = await (select(proposalPrintBatchItems)
            ..where((i) => i.batchId.isIn(batchIds) & i.deletedAt.isNull())
            ..orderBy([
              (i) => OrderingTerm(
                    expression: i.createdAt,
                    mode: OrderingMode.asc,
                  ),
            ]))
          .get();

      final itemsByBatch = <String, List<ProposalPrintBatchItem>>{};
      for (final item in items) {
        itemsByBatch.putIfAbsent(item.batchId, () => []).add(item);
      }

      return batches
          .where((b) => (itemsByBatch[b.id] ?? const []).isNotEmpty)
          .map(
            (b) => ProposalBatchWithItems(
              batch: b,
              items: itemsByBatch[b.id] ?? const [],
            ),
          )
          .toList();
    });
  }

  /// পূর্বে প্রিন্ট/জমা হওয়া ব্যাচগুলোর তালিকা।
  Future<List<ProposalBatchWithItems>> getPrintedBatches() async {
    final batches = await (select(proposalPrintBatches)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.printedAt, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();

    if (batches.isEmpty) return const [];
    final batchIds = batches.map((b) => b.id).toList();
    final items = await (select(proposalPrintBatchItems)
          ..where((i) => i.batchId.isIn(batchIds) & i.deletedAt.isNull())
          ..orderBy([
            (i) =>
                OrderingTerm(expression: i.createdAt, mode: OrderingMode.asc),
          ]))
        .get();

    final itemsByBatch = <String, List<ProposalPrintBatchItem>>{};
    for (final item in items) {
      itemsByBatch.putIfAbsent(item.batchId, () => []).add(item);
    }

    return batches
        .where((b) => (itemsByBatch[b.id] ?? const []).isNotEmpty)
        .map(
          (b) => ProposalBatchWithItems(
            batch: b,
            items: itemsByBatch[b.id] ?? const [],
          ),
        )
        .toList();
  }

  /// নতুন প্রিন্ট ব্যাচ এবং তার আইটেমসমূহ সংরক্ষণ।
  Future<void> insertBatchWithItems({
    required ProposalPrintBatchesCompanion batch,
    required List<ProposalPrintBatchItemsCompanion> items,
  }) async {
    await transaction(() async {
      await into(proposalPrintBatches).insert(batch);
      for (final item in items) {
        await into(proposalPrintBatchItems).insert(item);
      }
    });
  }

  /// একটি ব্যাচ থেকে নির্দিষ্ট একটি আইটেম আনমার্ক করা (যাতে আবেদনটি আবার
  /// 'প্রিন্ট বাকি' তালিকায় ফিরে আসে)।
  Future<void> softDeleteBatchItem(String itemId, {int? timestamp}) async {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      final item = await (select(proposalPrintBatchItems)
            ..where((t) => t.id.equals(itemId) & t.deletedAt.isNull()))
          .getSingleOrNull();
      if (item == null) return;

      await (update(proposalPrintBatchItems)
            ..where((t) => t.id.equals(itemId)))
          .write(
        ProposalPrintBatchItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final remaining = await (select(proposalPrintBatchItems)
            ..where((t) => t.batchId.equals(item.batchId) & t.deletedAt.isNull()))
          .get();

      if (remaining.isEmpty) {
        await (update(proposalPrintBatches)
              ..where((t) => t.id.equals(item.batchId)))
            .write(
          ProposalPrintBatchesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      } else {
        await (update(proposalPrintBatches)
              ..where((t) => t.id.equals(item.batchId)))
            .write(
          ProposalPrintBatchesCompanion(
            itemCount: Value(remaining.length),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// সম্পূর্ণ একটি ব্যাচ আনমার্ক/বাতিল করা (সব আইটেম আবার 'প্রিন্ট বাকি' তালিকায় ফিরবে)।
  Future<void> softDeleteBatch(String batchId, {int? timestamp}) async {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    await transaction(() async {
      await (update(proposalPrintBatchItems)
            ..where((t) => t.batchId.equals(batchId) & t.deletedAt.isNull()))
          .write(
        ProposalPrintBatchItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await (update(proposalPrintBatches)..where((t) => t.id.equals(batchId)))
          .write(
        ProposalPrintBatchesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }
}
