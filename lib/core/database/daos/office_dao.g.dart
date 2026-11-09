// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'office_dao.dart';

// ignore_for_file: type=lint
mixin _$OfficeDaoMixin on DatabaseAccessor<AppDatabase> {
  $OfficesTable get offices => attachedDatabase.offices;
  $PersonsTable get persons => attachedDatabase.persons;
  $ReferencesTable get references => attachedDatabase.references;
  $ApplicationsTable get applications => attachedDatabase.applications;
  OfficeDaoManager get managers => OfficeDaoManager(this);
}

class OfficeDaoManager {
  final _$OfficeDaoMixin _db;
  OfficeDaoManager(this._db);
  $$OfficesTableTableManager get offices =>
      $$OfficesTableTableManager(_db.attachedDatabase, _db.offices);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$ReferencesTableTableManager get references =>
      $$ReferencesTableTableManager(_db.attachedDatabase, _db.references);
  $$ApplicationsTableTableManager get applications =>
      $$ApplicationsTableTableManager(_db.attachedDatabase, _db.applications);
}
