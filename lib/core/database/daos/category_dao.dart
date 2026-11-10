import 'package:drift/drift.dart';

import '../app_database.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [
  ExpenseCategories,
  IncomeCategories,
  WorkTypes,
])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  // -------------------------------------------------------------
  // ১. খরচের খাত (Expense Categories)
  // -------------------------------------------------------------

  Stream<List<ExpenseCategory>> watchExpenseCategories({
    bool? isGeneral,
    bool includeDeleted = false,
  }) {
    final query = select(expenseCategories);
    query.where((tbl) {
      var expr = includeDeleted ? const Constant(true) : tbl.deletedAt.isNull();
      if (isGeneral != null) {
        expr = expr & tbl.isGeneral.equals(isGeneral ? 1 : 0);
      }
      return expr;
    });
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  Future<List<ExpenseCategory>> getExpenseCategories({
    bool? isGeneral,
    bool includeDeleted = false,
  }) {
    final query = select(expenseCategories);
    query.where((tbl) {
      var expr = includeDeleted ? const Constant(true) : tbl.deletedAt.isNull();
      if (isGeneral != null) {
        expr = expr & tbl.isGeneral.equals(isGeneral ? 1 : 0);
      }
      return expr;
    });
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  Future<ExpenseCategory?> getExpenseCategoryById(String id) {
    return (select(expenseCategories)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertExpenseCategory(ExpenseCategoriesCompanion companion) {
    return into(expenseCategories).insert(companion);
  }

  Future<bool> updateExpenseCategory(ExpenseCategoriesCompanion companion) {
    return update(expenseCategories).replace(companion);
  }

  /// খরচের খাত সফট ডিলিট — পুরনো খরচের স্ন্যাপশট অক্ষত রেখে তালিকা থেকে বাদ দেয়
  Future<bool> deleteExpenseCategory(String id) async {
    final cat = await getExpenseCategoryById(id);
    if (cat == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final affected = await (update(expenseCategories)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      ExpenseCategoriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return affected > 0;
  }

  // -------------------------------------------------------------
  // ২. স্বতন্ত্র আয়ের খাত (Income Categories)
  // -------------------------------------------------------------

  Stream<List<IncomeCategory>> watchIncomeCategories({
    bool includeDeleted = false,
  }) {
    final query = select(incomeCategories);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  Future<List<IncomeCategory>> getIncomeCategories({
    bool includeDeleted = false,
  }) {
    final query = select(incomeCategories);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  Future<IncomeCategory?> getIncomeCategoryById(String id) {
    return (select(incomeCategories)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertIncomeCategory(IncomeCategoriesCompanion companion) {
    return into(incomeCategories).insert(companion);
  }

  Future<bool> updateIncomeCategory(IncomeCategoriesCompanion companion) {
    return update(incomeCategories).replace(companion);
  }

  /// স্বতন্ত্র আয়ের খাত সফট ডিলিট — পুরনো আয়ের স্ন্যাপশট অক্ষত রেখে তালিকা থেকে বাদ দেয়
  Future<bool> deleteIncomeCategory(String id) async {
    final cat = await getIncomeCategoryById(id);
    if (cat == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final affected = await (update(incomeCategories)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      IncomeCategoriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return affected > 0;
  }

  // -------------------------------------------------------------
  // ৩. কাজের ধরন (Work Types)
  // -------------------------------------------------------------

  Stream<List<WorkType>> watchWorkTypes({
    bool includeDeleted = false,
  }) {
    final query = select(workTypes);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  Future<List<WorkType>> getWorkTypes({
    bool includeDeleted = false,
  }) {
    final query = select(workTypes);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    query.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.get();
  }

  Future<WorkType?> getWorkTypeById(String id) {
    return (select(workTypes)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertWorkType(WorkTypesCompanion companion) {
    return into(workTypes).insert(companion);
  }

  Future<bool> updateWorkType(WorkTypesCompanion companion) {
    return update(workTypes).replace(companion);
  }

  /// কাজের ধরন সফট ডিলিট — পুরনো আবেদনের স্ন্যাপশট অক্ষত রেখে তালিকা থেকে বাদ দেয়
  Future<bool> deleteWorkType(String id) async {
    final wt = await getWorkTypeById(id);
    if (wt == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final affected =
        await (update(workTypes)..where((tbl) => tbl.id.equals(id))).write(
      WorkTypesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return affected > 0;
  }
}

