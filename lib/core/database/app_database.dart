import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';

import 'tables/applications_table.dart';
import 'tables/documents_table.dart';
import 'tables/expense_categories_table.dart';
import 'tables/expenses_table.dart';
import 'tables/income_categories_table.dart';
import 'tables/independent_incomes_table.dart';
import 'tables/offices_table.dart';
import 'tables/payments_table.dart';
import 'tables/persons_table.dart';
import 'tables/references_table.dart';
import 'tables/shop_settings_table.dart';
import 'tables/status_history_table.dart';
import 'tables/tasks_table.dart';
import 'tables/work_types_table.dart';

import 'daos/application_dao.dart';
import 'daos/category_dao.dart';
import 'daos/finance_dao.dart';
import 'daos/office_dao.dart';
import 'daos/person_dao.dart';
import 'daos/reference_dao.dart';
import 'daos/shop_settings_dao.dart';
import 'daos/task_dao.dart';

export 'daos/application_dao.dart';
export 'daos/category_dao.dart';
export 'daos/finance_dao.dart';
export 'daos/office_dao.dart';
export 'daos/person_dao.dart';
export 'daos/reference_dao.dart';
export 'daos/shop_settings_dao.dart';
export 'daos/task_dao.dart';

export 'tables/applications_table.dart';
export 'tables/documents_table.dart';
export 'tables/expense_categories_table.dart';
export 'tables/expenses_table.dart';
export 'tables/income_categories_table.dart';
export 'tables/independent_incomes_table.dart';
export 'tables/offices_table.dart';
export 'tables/payments_table.dart';
export 'tables/persons_table.dart';
export 'tables/references_table.dart';
export 'tables/shop_settings_table.dart';
export 'tables/status_history_table.dart';
export 'tables/tasks_table.dart';
export 'tables/work_types_table.dart';

part 'app_database.g.dart';

/// অ্যাপের সম্পূর্ণ ডেটাবেজ স্কিমা ও কানেকশন।
@DriftDatabase(
  tables: [
    Persons,
    References,
    Offices,
    Applications,
    Payments,
    Expenses,
    IndependentIncomes,
    StatusHistory,
    Documents,
    Tasks,
    WorkTypes,
    ExpenseCategories,
    IncomeCategories,
    ShopSettings,
  ],
  daos: [
    ApplicationDao,
    FinanceDao,
    PersonDao,
    ReferenceDao,
    TaskDao,
    OfficeDao,
    CategoryDao,
    ShopSettingsDao,
  ],
  include: {
    'unified_transactions_view.drift',
    'integrity_guards.drift',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// অ্যান্ড্রয়েড প্রোডাকশন ডেটাবেজ।
  ///
  /// SQLite ফাইল অ্যাপের ডকুমেন্টস ডিরেক্টরিতে `rojob_bhumi.sqlite` নামে
  /// সংরক্ষিত হয়।
  AppDatabase.open()
      : super(
          driftDatabase(
            name: 'rojob_bhumi',
            native: const DriftNativeOptions(
              setup: _applyPragmas,
            ),
          ),
        );

  /// অ্যাপের প্রোডাকশন SQLite ডাটাবেজ ফাইল অবজেক্ট।
  static Future<File> getDatabaseFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, 'rojob_bhumi.sqlite'));
  }

  /// লাইভ ডেটাবেজ ও সংশ্লিষ্ট WAL এবং SHM ফাইলসমূহ।
  static Future<List<File>> getAllDatabaseFiles() async {
    final file = await getDatabaseFile();
    return [
      file,
      File('${file.path}-wal'),
      File('${file.path}-shm'),
    ];
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await _createSchema(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Phase 1 হলো প্রথম স্কিমা সংস্করণ — তাই এখনো কোনো আপগ্রেড
          // পথ নেই। স্কিমা সংস্করণ বাড়লে এখানে সংস্করণ-ভিত্তিক ধাপ যোগ
          // করতে হবে (`if (from < 2) { ... }`)।
          //
          // ⚠️ ইচ্ছাকৃতভাবে কিছুই করা হচ্ছে না: `m.createAll()`-এর মতো
          // অকৃত অপশন পুরো স্কিমা পুনরায় তৈরির চেষ্টা করলে ইনডেক্স ও
          // ট্রিগার ইতিমধ্যে থাকায় "already exists" ত্রুটি হয়। সঠিক
          // পদ্ধতি হলো প্রতিটি সংস্করণের জন্য আলাদা ধাপ লেখা, যেখানে
          // প্রয়োজন হলে `m.addColumn()` / `m.alterTable()` / `m.create()`।
          //
          // কখনোই ব্যবহারকারীর ডেটা ধ্বংস করা হবে না।
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  /// স্কিমা তৈরি করে — নির্ভরতার ক্রম অনুযায়ী সাজিয়ে।
  ///
  /// drift-এর জেনারেটর `allSchemaEntities` তালিকায় ট্রিগার ও ভিউকে
  /// টেবিলের **আগে** রাখে, তাই `m.createAll()` সরাসরি ব্যবহার করলে
  /// `CREATE TRIGGER ... ON applications` ব্যর্থ হয় ("no such table:
  /// main.applications")।
  ///
  /// তাই স্কিমা তৈরির ক্রম স্পষ্টভাবে নিয়ন্ত্রণ করা হয়:
  ///   ১. টেবিল,
  ///   ২. ইনডেক্স,
  ///   ৩. ভিউ (যে টেবিলগুলো পড়ে তারা তৈরি হয়ে গেছে),
  ///   ৪. ট্রিগার (যে টেবিলগুলোর উপর প্রয়োগ হয় তারা তৈরি হয়ে গেছে)।
  ///
  /// একই ক্রম `onCreate` ও `onUpgrade` — দুটোতেই ব্যবহৃত হয়, যাতে
  /// ভবিষ্যতের স্কিমা আপগ্রেডও নিরাপদ থাকে।
  Future<void> _createSchema(Migrator m) async {
    final entities = allSchemaEntities.toList();

    // ১. টেবিল — জেনারেটরের ক্রমেই (রেফারেন্স ছাড়া আগে), কারণ SQLite
    // বিদেশী কী রেফারেন্সের জন্য টেবিলের অস্তিত্ব চায় না — শুধু লেখার
    // সময় বাধা দেয়। তাই টেবিলগুলোর মধ্যে ক্রম সমস্যা তৈরি করে না।
    final tables = entities.whereType<TableInfo<Table, Object?>>().toList();

    // ২. ইনডেক্স — টেবিল তৈরি হওয়ার পরেই তৈরি হয়, নইলে "no such table"।
    final indexes = entities.whereType<Index>().toList();

    // ৩. ভিউ — যে টেবিলগুলো পড়ে তারা তৈরি হয়ে গেছে।
    final views = entities.whereType<ViewInfo>().toList();

    // ৪. ট্রিগার — সবশেষে, কারণ ট্রিগার টেবিলের উপর প্রয়োগ হয়।
    final triggers = entities.whereType<Trigger>().toList();

    for (final entity in [
      ...tables,
      ...indexes,
      ...views,
      ...triggers,
    ]) {
      await m.create(entity);
    }
  }

  /// SQLite সংযোগ খোলার সময়ে PRAGMA প্রয়োগ করে।
  ///
  /// `foreign_keys` এবং `journal_mode` প্রতিটি কানেকশনে প্রয়োগ করতে হয়,
  /// তাই এগুলো কানেকশন সেটআপ হুকে চালানো হয়।
  static void _applyPragmas(CommonDatabase db) {
    db.execute('PRAGMA foreign_keys = ON');
    db.execute('PRAGMA journal_mode = WAL');
  }
}
