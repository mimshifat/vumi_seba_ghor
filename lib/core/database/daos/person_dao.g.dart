// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_dao.dart';

// ignore_for_file: type=lint
mixin _$PersonDaoMixin on DatabaseAccessor<AppDatabase> {
  $PersonsTable get persons => attachedDatabase.persons;
  $ReferencesTable get references => attachedDatabase.references;
  $OfficesTable get offices => attachedDatabase.offices;
  $ApplicationsTable get applications => attachedDatabase.applications;
  PersonDaoManager get managers => PersonDaoManager(this);
}

class PersonDaoManager {
  final _$PersonDaoMixin _db;
  PersonDaoManager(this._db);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$ReferencesTableTableManager get references =>
      $$ReferencesTableTableManager(_db.attachedDatabase, _db.references);
  $$OfficesTableTableManager get offices =>
      $$OfficesTableTableManager(_db.attachedDatabase, _db.offices);
  $$ApplicationsTableTableManager get applications =>
      $$ApplicationsTableTableManager(_db.attachedDatabase, _db.applications);
}
