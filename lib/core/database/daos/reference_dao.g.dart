// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_dao.dart';

// ignore_for_file: type=lint
mixin _$ReferenceDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReferencesTable get references => attachedDatabase.references;
  $PersonsTable get persons => attachedDatabase.persons;
  $OfficesTable get offices => attachedDatabase.offices;
  $ApplicationsTable get applications => attachedDatabase.applications;
  $StatusHistoryTable get statusHistory => attachedDatabase.statusHistory;
  $PaymentsTable get payments => attachedDatabase.payments;
  ReferenceDaoManager get managers => ReferenceDaoManager(this);
}

class ReferenceDaoManager {
  final _$ReferenceDaoMixin _db;
  ReferenceDaoManager(this._db);
  $$ReferencesTableTableManager get references =>
      $$ReferencesTableTableManager(_db.attachedDatabase, _db.references);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$OfficesTableTableManager get offices =>
      $$OfficesTableTableManager(_db.attachedDatabase, _db.offices);
  $$ApplicationsTableTableManager get applications =>
      $$ApplicationsTableTableManager(_db.attachedDatabase, _db.applications);
  $$StatusHistoryTableTableManager get statusHistory =>
      $$StatusHistoryTableTableManager(_db.attachedDatabase, _db.statusHistory);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
}
