import 'package:drift/drift.dart';

import '../../utils/bengali_digits.dart';
import '../app_database.dart';

part 'person_dao.g.dart';

@DriftAccessor(tables: [Persons, Applications])
class PersonDao extends DatabaseAccessor<AppDatabase> with _$PersonDaoMixin {
  PersonDao(super.db);

  /// গ্রাহকদের রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<Person>> watchPersons({
    String? search,
    bool includeDeleted = false,
  }) {
    return _buildPersonsQuery(search: search, includeDeleted: includeDeleted)
        .watch();
  }

  /// গ্রাহকদের তালিকা সংগ্রহ (Future)
  Future<List<Person>> getPersons({
    String? search,
    bool includeDeleted = false,
  }) {
    return _buildPersonsQuery(search: search, includeDeleted: includeDeleted)
        .get();
  }

  SimpleSelectStatement<$PersonsTable, Person> _buildPersonsQuery({
    String? search,
    bool includeDeleted = false,
  }) {
    final query = select(persons);

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

  /// নির্দিষ্ট আইডি অনুযায়ী গ্রাহক খোঁজা
  Future<Person?> getPersonById(String id, {bool includeDeleted = false}) {
    final query = select(persons)..where((tbl) => tbl.id.equals(id));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  /// নির্দিষ্ট আইডি অনুযায়ী গ্রাহক রিয়েক্টিভ ওয়াচ
  Stream<Person?> watchPersonById(String id) {
    final query = select(persons)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// নতুন গ্রাহক সংযোজন
  Future<int> insertPerson(PersonsCompanion companion) {
    return into(persons).insert(companion);
  }

  /// গ্রাহকের তথ্য আপডেট
  Future<bool> updatePerson(PersonsCompanion companion) {
    return update(persons).replace(companion);
  }

  /// গ্রাহকের অধীনে থাকা সক্রিয় আবেদনের সংখ্যা
  Future<int> getApplicationCountForPerson(String personId) async {
    final countCol = applications.id.count();
    final query = selectOnly(applications)
      ..addColumns([countCol])
      ..where(applications.applicantId.equals(personId) &
          applications.deletedAt.isNull());

    final row = await query.getSingle();
    return row.read(countCol) ?? 0;
  }

  /// স্মার্ট ডিলিট পলিসি (BACKEND_MASTER_PLAN.md §1.3):
  /// - যদি গ্রাহকের অধীনে কোনো আবেদন থাকে: সফট ডিলিট (`deletedAt = now`)
  /// - যদি কোনো আবেদন না থাকে: হার্ড ডিলিট (SQL DELETE)
  Future<bool> deletePerson(String id) async {
    final appCount = await getApplicationCountForPerson(id);

    if (appCount > 0) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final affected =
          await (update(persons)..where((tbl) => tbl.id.equals(id))).write(
        PersonsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return affected > 0;
    } else {
      final affected =
          await (delete(persons)..where((tbl) => tbl.id.equals(id))).go();
      return affected > 0;
    }
  }

  /// সফট ডিলিট গ্রাহক পুনরুদ্ধার
  Future<int> restorePerson(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(persons)..where((tbl) => tbl.id.equals(id))).write(
      PersonsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }
}

