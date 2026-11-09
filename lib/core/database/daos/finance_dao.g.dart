// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_dao.dart';

// ignore_for_file: type=lint
mixin _$FinanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $PersonsTable get persons => attachedDatabase.persons;
  $ReferencesTable get references => attachedDatabase.references;
  $OfficesTable get offices => attachedDatabase.offices;
  $ApplicationsTable get applications => attachedDatabase.applications;
  $StatusHistoryTable get statusHistory => attachedDatabase.statusHistory;
  $PaymentsTable get payments => attachedDatabase.payments;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  $IndependentIncomesTable get independentIncomes =>
      attachedDatabase.independentIncomes;
  FinanceDaoManager get managers => FinanceDaoManager(this);
}

class FinanceDaoManager {
  final _$FinanceDaoMixin _db;
  FinanceDaoManager(this._db);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$ReferencesTableTableManager get references =>
      $$ReferencesTableTableManager(_db.attachedDatabase, _db.references);
  $$OfficesTableTableManager get offices =>
      $$OfficesTableTableManager(_db.attachedDatabase, _db.offices);
  $$ApplicationsTableTableManager get applications =>
      $$ApplicationsTableTableManager(_db.attachedDatabase, _db.applications);
  $$StatusHistoryTableTableManager get statusHistory =>
      $$StatusHistoryTableTableManager(_db.attachedDatabase, _db.statusHistory);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
  $$IndependentIncomesTableTableManager get independentIncomes =>
      $$IndependentIncomesTableTableManager(
        _db.attachedDatabase,
        _db.independentIncomes,
      );
}
