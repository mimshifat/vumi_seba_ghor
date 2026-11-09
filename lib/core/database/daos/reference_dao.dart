import 'package:drift/drift.dart';

import '../../utils/bengali_digits.dart';
import '../../utils/money.dart';
import '../app_database.dart';

part 'reference_dao.g.dart';

/// রেফারেন্স খাতা পরিসংখ্যান
class ReferenceLedgerStats {
  final int applicationCount;
  final int totalAgreedPaisa;
  final int totalReceivedPaisa;
  final int totalDuePaisa;

  const ReferenceLedgerStats({
    required this.applicationCount,
    required this.totalAgreedPaisa,
    required this.totalReceivedPaisa,
    required this.totalDuePaisa,
  });

  Money get totalAgreed => Money.fromPaisa(totalAgreedPaisa);
  Money get totalReceived => Money.fromPaisa(totalReceivedPaisa);
  Money get totalDue => Money.fromPaisa(totalDuePaisa);
}

@DriftAccessor(tables: [References, Applications, Payments])
class ReferenceDao extends DatabaseAccessor<AppDatabase>
    with _$ReferenceDaoMixin {
  ReferenceDao(super.db);

  /// রেফারেন্স ব্যক্তিদের রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<Reference>> watchReferences({
    String? search,
    bool includeDeleted = false,
  }) {
    return _buildReferencesQuery(
      search: search,
      includeDeleted: includeDeleted,
    ).watch();
  }

  /// রেফারেন্স ব্যক্তিদের তালিকা সংগ্রহ (Future)
  Future<List<Reference>> getReferences({
    String? search,
    bool includeDeleted = false,
  }) {
    return _buildReferencesQuery(
      search: search,
      includeDeleted: includeDeleted,
    ).get();
  }

  SimpleSelectStatement<$ReferencesTable, Reference> _buildReferencesQuery({
    String? search,
    bool includeDeleted = false,
  }) {
    final query = select(references);

    query.where((tbl) {
      final predicates = <Expression<bool>>[];

      if (!includeDeleted) {
        predicates.add(tbl.deletedAt.isNull());
      }

      if (search != null && search.trim().isNotEmpty) {
        final rawTerm = search.trim();
        final enTerm = BengaliDigits.toEnglish(rawTerm);
        final bnTerm = BengaliDigits.toBengali(rawTerm);

        final searchPredicates = <Expression<bool>>[
          tbl.name.contains(rawTerm),
          tbl.phone.contains(enTerm),
          tbl.phone.contains(bnTerm),
          tbl.phone.contains(rawTerm),
        ];

        searchPredicates.add(tbl.address.contains(rawTerm));

        Expression<bool>? combined;
        for (final p in searchPredicates) {
          combined = combined == null ? p : (combined | p);
        }
        if (combined != null) {
          predicates.add(combined);
        }
      }

      return predicates.isEmpty
          ? const Constant(true)
          : Expression.and(predicates);
    });

    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query;
  }

  /// নির্দিষ্ট আইডি অনুযায়ী রেফারেন্স ব্যক্তি খোঁজা
  Future<Reference?> getReferenceById(String id,
      {bool includeDeleted = false}) {
    final query = select(references)..where((tbl) => tbl.id.equals(id));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// নির্দিষ্ট আইডি অনুযায়ী রেফারেন্স ব্যক্তির স্ট্রিম
  Stream<Reference?> watchReferenceById(String id) {
    final query = select(references)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// নতুন রেফারেন্স ব্যক্তি সংযোজন
  Future<int> insertReference(ReferencesCompanion companion) {
    return into(references).insert(companion);
  }

  /// রেফারেন্স ব্যক্তির তথ্য আপডেট
  Future<bool> updateReference(ReferencesCompanion companion) {
    return update(references).replace(companion);
  }

  /// রেফারেন্স ব্যক্তির অধীনে সক্রিয় আবেদনের সংখ্যা
  Future<int> getApplicationCountForReference(String referenceId) async {
    final countCol = applications.id.count();
    final query = selectOnly(applications)
      ..addColumns([countCol])
      ..where(applications.referenceId.equals(referenceId) &
          applications.deletedAt.isNull());

    final row = await query.getSingle();
    return row.read(countCol) ?? 0;
  }

  /// রেফারেন্স ব্যক্তি খাতা হিসাব (BACKEND_MASTER_PLAN.md §1.2 নিয়ম ৬)
  Future<ReferenceLedgerStats> getReferenceStats(String referenceId) async {
    final apps = await (select(applications)
          ..where((tbl) =>
              tbl.referenceId.equals(referenceId) & tbl.deletedAt.isNull()))
        .get();

    int totalAgreed = 0;
    int totalReceived = 0;
    int totalDue = 0;

    for (final app in apps) {
      totalAgreed += app.agreedAmount;

      // আবেদনের মোট আদায়
      final payCol = payments.amount.sum();
      final payQuery = selectOnly(payments)
        ..addColumns([payCol])
        ..where(payments.applicationId.equals(app.id) &
            payments.deletedAt.isNull());
      final appReceived = (await payQuery.getSingle()).read(payCol) ?? 0;
      totalReceived += appReceived;

      if (app.isMarkedAsPaid == 0) {
        final due = app.agreedAmount - appReceived;
        if (due > 0) {
          totalDue += due;
        }
      }
    }

    return ReferenceLedgerStats(
      applicationCount: apps.length,
      totalAgreedPaisa: totalAgreed,
      totalReceivedPaisa: totalReceived,
      totalDuePaisa: totalDue,
    );
  }

  /// স্মার্ট ডিলিট পলিসি (BACKEND_MASTER_PLAN.md §1.3):
  /// - যদি রেফারেন্স ব্যক্তির অধীনে আবেদন থাকে: সফট ডিলিট (`deletedAt = now`)
  /// - যদি কোনো আবেদন না থাকে: হার্ড ডিলিট (SQL DELETE)
  Future<bool> deleteReference(String id) async {
    final appCount = await getApplicationCountForReference(id);

    if (appCount > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final affected =
          await (update(references)..where((tbl) => tbl.id.equals(id))).write(
        ReferencesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return affected > 0;
    } else {
      final affected =
          await (delete(references)..where((tbl) => tbl.id.equals(id))).go();
      return affected > 0;
    }
  }

  /// সফট ডিলিট রেফারেন্স ব্যক্তি পুনরুদ্ধার
  Future<int> restoreReference(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(references)..where((tbl) => tbl.id.equals(id))).write(
      ReferencesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }
}

