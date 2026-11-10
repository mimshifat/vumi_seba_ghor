import 'package:drift/drift.dart';

import 'application_statuses.dart';
import 'offices_table.dart';
import 'persons_table.dart';
import 'references_table.dart';

/// মূল আবেদন তালিকা — স্ন্যাপশট সমন্বিত।
@TableIndex(
  name: 'idx_applications_active',
  columns: {#deletedAt},
)
@TableIndex(name: 'idx_applications_applicant', columns: {#applicantId})
@TableIndex(name: 'idx_applications_reference', columns: {#referenceId})
@TableIndex(name: 'idx_applications_office', columns: {#officeId})
@TableIndex(name: 'idx_applications_status', columns: {#status})
@TableIndex(name: 'idx_applications_work_type', columns: {#workType})
@TableIndex(name: 'idx_applications_date', columns: {#applicationDate})
@TableIndex(name: 'idx_applications_app_number', columns: {#appNumber})
class Applications extends Table {
  @override
  String get tableName => 'applications';

  TextColumn get id => text()();

  /// গ্রাহক ব্যক্তির সাথে লিংক। মুছে ফেললে NULL হবে, স্ন্যাপশট অক্ষত থাকবে।
  TextColumn get applicantId =>
      text().nullable().references(Persons, #id, onDelete: KeyAction.setNull)();

  /// **স্ন্যাপশট:** আবেদনকারীর নাম — রেকর্ড লেখার পর আর পরিবর্তন হবে না।
  TextColumn get applicantName => text().withLength(min: 1, max: 120)();

  /// **স্ন্যাপশট:** আবেদনকারীর মোবাইল নম্বর।
  TextColumn get applicantPhone => text().withLength(min: 1, max: 20)();

  /// **স্ন্যাপশট:** আবেদনকারীর ঠিকানা।
  TextColumn get applicantAddress => text().nullable()();

  /// রেফারেন্স ব্যক্তির সাথে লিংক।
  TextColumn get referenceId =>
      text().nullable().references(References, #id, onDelete: KeyAction.setNull)();

  /// **স্ন্যাপশট:** রেফারেন্স ব্যক্তির নাম।
  TextColumn get referenceName => text().nullable()();

  /// ভূমি অফিসের সাথে লিংক।
  TextColumn get officeId =>
      text().nullable().references(Offices, #id, onDelete: KeyAction.setNull)();

  /// **স্ন্যাপশট:** ভূমি অফিসের নাম।
  TextColumn get officeName => text().withLength(min: 1, max: 160)();

  TextColumn get mouza => text().nullable()();

  /// অনলাইন আবেদন নম্বর — ডুপ্লিকেট হলে শুধু সতর্কতা, ব্লক নয়।
  TextColumn get appNumber => text().nullable()();

  TextColumn get caseNumber => text().nullable()();

  TextColumn get workType => text().withLength(min: 1, max: 80)();

  /// Unix epoch milliseconds।
  IntColumn get applicationDate => integer()();

  TextColumn get status => text().withLength(min: 1, max: 40)();

  /// চুক্তিকৃত সার্ভিস ফি (পয়সায়)।
  IntColumn get agreedAmount => integer()();

  /// ১ = বকেয়া মওকুফ/পরিশোধিত চিহ্নিত, ০ = স্বাভাবিক।
  IntColumn get isMarkedAsPaid => integer().withDefault(const Constant(0))();

  /// ভূমি পোর্টাল (LSG) লগইন মোবাইল নম্বর — আবেদনকারীর নম্বরের চেয়ে আলাদা হতে পারে।
  TextColumn get portalPhone => text().nullable()();

  /// ভূমি পোর্টাল (LSG) লগইন পাসওয়ার্ড।
  TextColumn get portalPassword => text().nullable()();

  TextColumn get notes => text().nullable()();

  /// Unix epoch milliseconds।
  IntColumn get createdAt => integer()();

  /// Unix epoch milliseconds।
  IntColumn get updatedAt => integer()();

  /// সফট ডিলিট টাইমস্ট্যাম্প। NULL মানে রেকর্ড সক্রিয়।
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (agreed_amount > 0)',
        'CHECK (is_marked_as_paid IN (0, 1))',
        'CHECK (length(trim(applicant_name)) > 0)',
        'CHECK (length(trim(office_name)) > 0)',
        'CHECK (status IN (${ApplicationStatuses.sqlList}))',
      ];
}
