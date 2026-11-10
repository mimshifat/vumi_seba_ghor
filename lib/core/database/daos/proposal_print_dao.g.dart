// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_print_dao.dart';

// ignore_for_file: type=lint
mixin _$ProposalPrintDaoMixin on DatabaseAccessor<AppDatabase> {
  $PersonsTable get persons => attachedDatabase.persons;
  $ReferencesTable get references => attachedDatabase.references;
  $OfficesTable get offices => attachedDatabase.offices;
  $ApplicationsTable get applications => attachedDatabase.applications;
  $StatusHistoryTable get statusHistory => attachedDatabase.statusHistory;
  $ProposalPrintBatchesTable get proposalPrintBatches =>
      attachedDatabase.proposalPrintBatches;
  $ProposalPrintBatchItemsTable get proposalPrintBatchItems =>
      attachedDatabase.proposalPrintBatchItems;
  ProposalPrintDaoManager get managers => ProposalPrintDaoManager(this);
}

class ProposalPrintDaoManager {
  final _$ProposalPrintDaoMixin _db;
  ProposalPrintDaoManager(this._db);
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
  $$ProposalPrintBatchesTableTableManager get proposalPrintBatches =>
      $$ProposalPrintBatchesTableTableManager(
        _db.attachedDatabase,
        _db.proposalPrintBatches,
      );
  $$ProposalPrintBatchItemsTableTableManager get proposalPrintBatchItems =>
      $$ProposalPrintBatchItemsTableTableManager(
        _db.attachedDatabase,
        _db.proposalPrintBatchItems,
      );
}
