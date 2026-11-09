import 'package:drift/drift.dart';

import '../app_database.dart';

part 'office_dao.g.dart';

@DriftAccessor(tables: [Offices, Applications])
class OfficeDao extends DatabaseAccessor<AppDatabase> with _$OfficeDaoMixin {
  OfficeDao(super.db);

  /// সকল ভূমি অফিসের রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<Office>> watchOffices({bool includeDeleted = false}) {
    final query = select(offices);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// সকল ভূমি অফিসের তালিকা সংগ্রহ (Future)
  Future<List<Office>> getOffices({bool includeDeleted = false}) {
    final query = select(offices);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  /// নির্দিষ্ট আইডি অনুযায়ী ভূমি অফিস খোঁজা
  Future<Office?> getOfficeById(String id, {bool includeDeleted = false}) {
    final query = select(offices)..where((tbl) => tbl.id.equals(id));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// নতুন ভূমি অফিস তৈরি
  Future<int> insertOffice(OfficesCompanion companion) {
    return into(offices).insert(companion);
  }

  /// ভূমি অফিসের নাম আপডেট
  Future<bool> updateOffice(OfficesCompanion companion) {
    return update(offices).replace(companion);
  }

  /// অফিসের অধীনে থাকা সক্রিয় আবেদনের সংখ্যা
  Future<int> getApplicationCountForOffice(String officeId) async {
    final countCol = applications.id.count();
    final query = selectOnly(applications)
      ..addColumns([countCol])
      ..where(applications.officeId.equals(officeId) &
          applications.deletedAt.isNull());

    final row = await query.getSingle();
    return row.read(countCol) ?? 0;
  }

  /// স্মার্ট ডিলিট পলিসি (BACKEND_MASTER_PLAN.md §1.3):
  /// - যদি এই অফিসের অধীনে আবেদন থাকে: সফট ডিলিট (`deletedAt = now`)
  /// - যদি কোনো আবেদন না থাকে: হার্ড ডিলিট (SQL DELETE)
  /// - ইউনিভার্সাল স্ন্যাপশট নীতি অনুযায়ী পূর্ববর্তী আবেদনে `officeName` অক্ষত থাকবে
  Future<bool> deleteOffice(String id) async {
    final appCount = await getApplicationCountForOffice(id);

    if (appCount > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final affected =
          await (update(offices)..where((tbl) => tbl.id.equals(id))).write(
        OfficesCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return affected > 0;
    } else {
      final affected =
          await (delete(offices)..where((tbl) => tbl.id.equals(id))).go();
      return affected > 0;
    }
  }

  /// সফট ডিলিট ভূমি অফিস পুনরুদ্ধার
  Future<int> restoreOffice(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(offices)..where((tbl) => tbl.id.equals(id))).write(
      OfficesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }
}

