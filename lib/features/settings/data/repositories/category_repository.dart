import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';

/// খাত ও ক্যাটাগরি রিপোজিটরি (BACKEND_MASTER_PLAN.md §1.3, §5)
class CategoryRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  CategoryRepository(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  // -------------------------------------------------------------
  // ১. খরচের খাত (Expense Categories)
  // -------------------------------------------------------------

  Stream<List<ExpenseCategory>> watchExpenseCategories({
    bool? isGeneral,
    bool includeDeleted = false,
  }) {
    return _db.categoryDao.watchExpenseCategories(
      isGeneral: isGeneral,
      includeDeleted: includeDeleted,
    );
  }

  Future<List<ExpenseCategory>> getExpenseCategories({
    bool? isGeneral,
    bool includeDeleted = false,
  }) async {
    try {
      return await _db.categoryDao.getExpenseCategories(
        isGeneral: isGeneral,
        includeDeleted: includeDeleted,
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<ExpenseCategory> createExpenseCategory({
    String? id,
    required String name,
    required bool isGeneral,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('খাতের নাম');
      }

      final catId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.categoryDao.insertExpenseCategory(
        ExpenseCategoriesCompanion.insert(
          id: catId,
          name: cleanName,
          isGeneral: Value(isGeneral ? 1 : 0),
          isDefault: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final created = await _db.categoryDao.getExpenseCategoryById(catId);
      return created!;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<void> updateExpenseCategory({
    required String id,
    required String name,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('খাতের নাম');
      }

      final existing = await _db.categoryDao.getExpenseCategoryById(id);
      if (existing == null) {
        throw AppFailure.custom('খরচের খাত খুঁজে পাওয়া যায়নি।');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.categoryDao.updateExpenseCategory(
        ExpenseCategoriesCompanion(
          id: Value(id),
          name: Value(cleanName),
          isGeneral: Value(existing.isGeneral),
          isDefault: Value(existing.isDefault),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
          deletedAt: Value(existing.deletedAt),
        ),
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<bool> deleteExpenseCategory(String id) async {
    try {
      return await _db.categoryDao.deleteExpenseCategory(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  // -------------------------------------------------------------
  // ২. স্বতন্ত্র আয়ের খাত (Income Categories)
  // -------------------------------------------------------------

  Stream<List<IncomeCategory>> watchIncomeCategories({
    bool includeDeleted = false,
  }) {
    return _db.categoryDao.watchIncomeCategories(includeDeleted: includeDeleted);
  }

  Future<List<IncomeCategory>> getIncomeCategories({
    bool includeDeleted = false,
  }) async {
    try {
      return await _db.categoryDao.getIncomeCategories(
        includeDeleted: includeDeleted,
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<IncomeCategory> createIncomeCategory({
    String? id,
    required String name,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('খাতের নাম');
      }

      final catId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.categoryDao.insertIncomeCategory(
        IncomeCategoriesCompanion.insert(
          id: catId,
          name: cleanName,
          isDefault: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final created = await _db.categoryDao.getIncomeCategoryById(catId);
      return created!;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<void> updateIncomeCategory({
    required String id,
    required String name,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('খাতের নাম');
      }

      final existing = await _db.categoryDao.getIncomeCategoryById(id);
      if (existing == null) {
        throw AppFailure.custom('আয়ের খাত খুঁজে পাওয়া যায়নি।');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.categoryDao.updateIncomeCategory(
        IncomeCategoriesCompanion(
          id: Value(id),
          name: Value(cleanName),
          isDefault: Value(existing.isDefault),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
          deletedAt: Value(existing.deletedAt),
        ),
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<bool> deleteIncomeCategory(String id) async {
    try {
      return await _db.categoryDao.deleteIncomeCategory(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  // -------------------------------------------------------------
  // ৩. কাজের ধরন (Work Types)
  // -------------------------------------------------------------

  Stream<List<WorkType>> watchWorkTypes({
    bool includeDeleted = false,
  }) {
    return _db.categoryDao.watchWorkTypes(includeDeleted: includeDeleted);
  }

  Future<List<WorkType>> getWorkTypes({
    bool includeDeleted = false,
  }) async {
    try {
      return await _db.categoryDao.getWorkTypes(includeDeleted: includeDeleted);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<WorkType> createWorkType({
    String? id,
    required String name,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('কাজের ধরনের নাম');
      }

      final wtId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.categoryDao.insertWorkType(
        WorkTypesCompanion.insert(
          id: wtId,
          name: cleanName,
          isDefault: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final created = await _db.categoryDao.getWorkTypeById(wtId);
      return created!;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<void> updateWorkType({
    required String id,
    required String name,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('কাজের ধরনের নাম');
      }

      final existing = await _db.categoryDao.getWorkTypeById(id);
      if (existing == null) {
        throw AppFailure.custom('কাজের ধরন খুঁজে পাওয়া যায়নি।');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.categoryDao.updateWorkType(
        WorkTypesCompanion(
          id: Value(id),
          name: Value(cleanName),
          isDefault: Value(existing.isDefault),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
          deletedAt: Value(existing.deletedAt),
        ),
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  Future<bool> deleteWorkType(String id) async {
    try {
      return await _db.categoryDao.deleteWorkType(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }
}

