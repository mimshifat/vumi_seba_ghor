// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExpenseCategoriesTable get expenseCategories =>
      attachedDatabase.expenseCategories;
  $IncomeCategoriesTable get incomeCategories =>
      attachedDatabase.incomeCategories;
  $WorkTypesTable get workTypes => attachedDatabase.workTypes;
  CategoryDaoManager get managers => CategoryDaoManager(this);
}

class CategoryDaoManager {
  final _$CategoryDaoMixin _db;
  CategoryDaoManager(this._db);
  $$ExpenseCategoriesTableTableManager get expenseCategories =>
      $$ExpenseCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.expenseCategories,
      );
  $$IncomeCategoriesTableTableManager get incomeCategories =>
      $$IncomeCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.incomeCategories,
      );
  $$WorkTypesTableTableManager get workTypes =>
      $$WorkTypesTableTableManager(_db.attachedDatabase, _db.workTypes);
}
