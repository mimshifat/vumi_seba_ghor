import 'dart:io';

import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/database/database_seeder.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// ফাইল-ভিত্তিক ইন-মেমোরি SQLite ডেটাবেজ তৈরি করে।
AppDatabase createTestDatabase() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

/// পরীক্ষার জন্য একটি বৈধ আবেদন তৈরির সহায়ক।
ApplicationsCompanion buildApplication({
  required String id,
  String applicantName = 'টেস্ট আবেদনকারী',
  String applicantPhone = '01711223344',
  int agreedAmount = 100000,
  String status = 'আবেদন',
  String? applicantId,
  String? referenceId,
  String? officeId,
  int? deletedAt,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return ApplicationsCompanion.insert(
    id: id,
    applicantId: Value(applicantId),
    applicantName: applicantName,
    applicantPhone: applicantPhone,
    referenceId: Value(referenceId),
    officeName: 'উপজেলা ভূমি অফিস, সাভার',
    workType: 'নামজারি',
    applicationDate: now,
    status: status,
    agreedAmount: agreedAmount,
    isMarkedAsPaid: const Value(0),
    createdAt: now,
    updatedAt: now,
    deletedAt: Value(deletedAt),
  );
}

void main() {
  group('স্কিমা — ১৪টি টেবিল', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('সব ১৪টি টেবিল তৈরি হয়েছে', () async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();

      expect(
        names,
        containsAll([
          'persons',
          'references',
          'offices',
          'applications',
          'payments',
          'expenses',
          'independent_incomes',
          'status_history',
          'documents',
          'tasks',
          'work_types',
          'expense_categories',
          'income_categories',
          'shop_settings',
          'proposal_print_batches',
          'proposal_print_batch_items',
        ]),
      );
    });

    test('প্রতিটি টেবিলে deleted_at কলাম আছে', () async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();

      for (final table in names) {
        final columns = await db
            .customSelect('PRAGMA table_info("$table")')
            .get();
        final columnNames =
            columns.map((row) => row.read<String>('name')).toSet();
        expect(
          columnNames,
          contains('deleted_at'),
          reason: '$table টেবিলে deleted_at কলাম নেই',
        );
      }
    });

    test('প্রতিটি টেবিলে created_at ও updated_at টাইমস্ট্যাম্প আছে', () async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();

      for (final table in names) {
        final columns =
            await db.customSelect('PRAGMA table_info("$table")').get();
        final columnNames =
            columns.map((row) => row.read<String>('name')).toSet();
        expect(columnNames, contains('created_at'), reason: table);
        expect(columnNames, contains('updated_at'), reason: table);
      }
    });
  });

  group('PRAGMA', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('foreign_keys = 1 (প্রয়োগ করা)', () async {
      final result =
          await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.data['foreign_keys'], 1);
    });
  });

  group('PRAGMA — ফাইল-ভিত্তিক WAL', () {
    test('journal_mode = wal', () async {
      // WAL শুধু ফাইল-ভিত্তিক ডেটাবেজে কাজ করে — ইন-মেমোরি ডেটাবেজে
      // 'memory' ফেরত দেয়। তাই অস্থায়ী ফাইল ব্যবহার করা হচ্ছে।
      final file = File(
        '${Directory.systemTemp.path}/rojob_wal_test_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      final walDb = AppDatabase(
        NativeDatabase(
          file,
          setup: (raw) {
            raw.execute('PRAGMA foreign_keys = ON');
            raw.execute('PRAGMA journal_mode = WAL');
          },
        ),
      );
      addTearDown(() async {
        await walDb.close();
        if (file.existsSync()) file.deleteSync();
      });

      final result =
          await walDb.customSelect('PRAGMA journal_mode').getSingle();
      expect(result.data['journal_mode'], 'wal');
    });
  });

  group('unified_transactions_view', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('ভিউ তৈরি হয়েছে এবং ১৪টি কলাম আছে', () async {
      final result = await db
          .customSelect('PRAGMA table_info(unified_transactions_view)')
          .get();
      expect(result.length, 14);
    });

    test('৬টি উৎস সঠিকভাবে ক্লাসিফাই হয়', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.applications).insert(buildApplication(id: 'app-1'));
      await db.into(db.payments).insert(
            PaymentsCompanion.insert(
              id: 'pay-1',
              applicationId: 'app-1',
              amount: 50000,
              date: now,
              method: 'নগদ',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.independentIncomes).insert(
            IndependentIncomesCompanion.insert(
              id: 'inc-1',
              category: 'ফটোকপি',
              amount: 2000,
              date: now,
              paymentMethod: 'নগদ',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              id: 'exp-1',
              applicationId: const Value('app-1'),
              amount: 3000,
              category: 'সরকারি ফি',
              date: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              id: 'gexp-1',
              amount: 1500,
              category: 'বিদ্যুৎ বিল',
              date: now,
              isGeneral: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final rows = await db
          .customSelect('SELECT source FROM unified_transactions_view')
          .get();
      final sources = rows.map((row) => row.read<String>('source')).toSet();

      expect(sources, contains('applicationPayment'));
      expect(sources, contains('independentIncome'));
      expect(sources, contains('applicationExpense'));
      expect(sources, contains('generalExpense'));
    });

    test('বিড ৪ ও ৬ — ডাবল কাউন্টিং বন্ধ (is_general ও is_status_exp একই রোকে)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.applications).insert(buildApplication(id: 'app-1'));
      // দোকানের সাধারণ খরচ যেটি স্ট্যাটাস পরিবর্তনের সাথে যুক্ত:
      // আবেদন ছাড়া, কিন্তু is_status_exp = 1।
      await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              id: 'exp-both',
              amount: 7000,
              category: 'সরকারি ফি',
              date: now,
              isGeneral: const Value(1),
              isStatusExp: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final rows = await db
          .customSelect(
            "SELECT id FROM unified_transactions_view WHERE id='exp-both'",
          )
          .get();

      // একটি রোক একবারই গণনা হতে হবে — ডাবল গণনা হলে ২টি রো আসত।
      expect(rows.length, 1);
    });

    test('সফট-ডিলিট আবেদনের লেনদেন সক্রিয় ভিউ থেকে বাদ পড়ে', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.applications).insert(
            buildApplication(id: 'app-deleted', deletedAt: now),
          );
      await db.into(db.payments).insert(
            PaymentsCompanion.insert(
              id: 'pay-deleted',
              applicationId: 'app-deleted',
              amount: 1000,
              date: now,
              method: 'নগদ',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final rows = await db
          .customSelect(
            "SELECT id FROM unified_transactions_view WHERE id='pay-deleted'",
          )
          .get();
      expect(rows, isEmpty);
    });
  });

  group('বিদেশী কী (Foreign Key) অখণ্ডতা', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('অস্তিত্ব নেই এমন আবেদনের পেমেন্ট ঢোকানো যায় না', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      expect(
        () => db.into(db.payments).insert(
              PaymentsCompanion.insert(
                id: 'pay-orphan',
                applicationId: 'missing-app',
                amount: 1000,
                date: now,
                method: 'নগদ',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(anything),
      );
    });

    test('গ্রাহক মুছে ফেললে আবেদনের স্ন্যাপশট অক্ষত থাকে', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.persons).insert(
            PersonsCompanion.insert(
              id: 'p-1',
              name: 'রহিম উদ্দিন',
              phone: '01711223344',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.applications).insert(
            buildApplication(
              id: 'app-1',
              applicantName: 'রহিম উদ্দিন',
              applicantPhone: '01711223344',
              applicantId: 'p-1',
            ),
          );

      // সফট ডিলিট।
      await (db.update(db.persons)..where((t) => t.id.equals('p-1')))
          .write(const PersonsCompanion(deletedAt: Value(0)));

      final app = await (db.select(db.applications)
            ..where((t) => t.id.equals('app-1')))
          .getSingle();

      expect(app.applicantName, 'রহিম উদ্দিন');
      expect(app.applicantPhone, '01711223344');
    });
  });

  group('CHECK সীমাবদ্ধতা', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('পেমেন্টের পরিমাণ শূন্য বা নেতিবাচক হতে পারে না', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));

      expect(
        () => db.into(db.payments).insert(
              PaymentsCompanion.insert(
                id: 'pay-zero',
                applicationId: 'app-1',
                amount: 0,
                date: now,
                method: 'নগদ',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(anything),
      );
    });

    test('খরচের পরিমাণ শূন্য বা নেতিবাচক হতে পারে না', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      expect(
        () => db.into(db.expenses).insert(
              ExpensesCompanion.insert(
                id: 'exp-zero',
                amount: -100,
                category: 'সরকারি ফি',
                date: now,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(anything),
      );
    });

    test('সাধারণ দোকান খরচের সাথে আবেদন যুক্ত থাকতে পারে না', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));

      expect(
        () => db.into(db.expenses).insert(
              ExpensesCompanion.insert(
                id: 'exp-invalid',
                applicationId: const Value('app-1'),
                amount: 100,
                category: 'বিদ্যুৎ বিল',
                date: now,
                isGeneral: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(anything),
      );
    });

    test('অজানা আবেদনের অবস্থা গ্রহণ করা হয় না', () async {
      expect(
        () => db.into(db.applications).insert(
              buildApplication(id: 'app-bad', status: 'অজানা অবস্থা'),
            ),
        throwsA(anything),
      );
    });

    test('ফাইলের খরচে আবেদনের রেফারেন্স ছাড়া রাখা যায় না', () async {
      // `is_general = 0` হলে খরচটি অবশ্যই কোনো আবেদনের সাথে যুক্ত —
      // নয়তো সেই রোকটি ভিউ ও ফাইল-ভিত্তিক হিসাবে কোথাও ধরা পড়ে না
      // (BACKEND_MASTER_PLAN.md §1.2)।
      final now = DateTime.now().millisecondsSinceEpoch;

      expect(
        () => db.into(db.expenses).insert(
              ExpensesCompanion.insert(
                id: 'exp-orphan',
                amount: 100,
                category: 'সরকারি ফি',
                date: now,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(anything),
      );
    });

    test('সাধারণ দোকান খরচে আবেদনের রেফারেন্স রাখা যায় না', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));

      expect(
        () => db.into(db.expenses).insert(
              ExpensesCompanion.insert(
                id: 'exp-general-linked',
                applicationId: const Value('app-1'),
                amount: 100,
                category: 'দোকান ভাড়া',
                date: now,
                isGeneral: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(anything),
      );
    });

    test('is_marked_as_paid শুধু ০ বা ১ হতে পারে', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      expect(
        () => db.into(db.applications).insert(
              ApplicationsCompanion.insert(
                id: 'app-flag',
                applicantName: 'পরীক্ষা',
                applicantPhone: '01711223344',
                officeName: 'অফিস',
                workType: 'নামজারি',
                applicationDate: now,
                status: 'আবেদন',
                agreedAmount: 1000,
                isMarkedAsPaid: const Value(2),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(anything),
      );
    });
  });


  group('সফট ডিলিট', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('deleted_at NULL মানে সক্রিয় রেকর্ড', () async {
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));

      final active = await (db.select(db.applications)
            ..where((t) => t.deletedAt.isNull()))
          .get();
      expect(active.length, 1);
    });

    test('সফট ডিলিটের পর রেকর্ড সক্রিয় তালিকা থেকে বাদ যায় কিন্তু ডেটাবেজে থাকে', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));

      await (db.update(db.applications)..where((t) => t.id.equals('app-1')))
          .write(ApplicationsCompanion(deletedAt: Value(now)));

      final active = await (db.select(db.applications)
            ..where((t) => t.deletedAt.isNull()))
          .get();
      expect(active, isEmpty);

      // রেকর্ড ডেটাবেজে অডিট ট্রেইল হিসেবে রয়ে গেছে।
      final all = await db.select(db.applications).get();
      expect(all.length, 1);
      expect(all.first.deletedAt, now);
    });
  });

  group('মাইগ্রেশন', () {
    test('schemaVersion ২', () async {
      final db = createTestDatabase();
      expect(db.schemaVersion, AppDatabase.currentSchemaVersion);
      expect(db.schemaVersion, 2);
      await db.close();
    });

    test('ডেটাবেজ খোলার পর সব টেবিল ও ভিউ প্রস্তুত থাকে', () async {
      final db = createTestDatabase();

      final view = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='view' "
            "AND name='unified_transactions_view'",
          )
          .get();
      expect(view.length, 1);

      await db.close();
    });
  });

  group('সিড ডেটা', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('সিড সফল হয় এবং কোনো ভাসমান বিদেশী কী থাকে না', () async {
      await DatabaseSeeder.seed(db);

      // প্রতিটি সম্পর্কের জন্য বিস্তারিত অখণ্ডতা যাচাই।
      const orphanChecks = <String, String>{
        'applications.applicant_id → persons':
            'SELECT a.id FROM applications a LEFT JOIN persons p '
                'ON a.applicant_id = p.id '
                'WHERE a.applicant_id IS NOT NULL AND p.id IS NULL',
        'applications.reference_id → references':
            'SELECT a.id FROM applications a LEFT JOIN "references" r '
                'ON a.reference_id = r.id '
                'WHERE a.reference_id IS NOT NULL AND r.id IS NULL',
        'applications.office_id → offices':
            'SELECT a.id FROM applications a LEFT JOIN offices o '
                'ON a.office_id = o.id '
                'WHERE a.office_id IS NOT NULL AND o.id IS NULL',
        'payments.application_id → applications':
            'SELECT p.id FROM payments p LEFT JOIN applications a '
                'ON p.application_id = a.id WHERE a.id IS NULL',
        'payments.status_history_id → status_history':
            'SELECT p.id FROM payments p LEFT JOIN status_history s '
                'ON p.status_history_id = s.id '
                'WHERE p.status_history_id IS NOT NULL AND s.id IS NULL',
        'expenses.application_id → applications':
            'SELECT e.id FROM expenses e LEFT JOIN applications a '
                'ON e.application_id = a.id '
                'WHERE e.application_id IS NOT NULL AND a.id IS NULL',
        'expenses.status_history_id → status_history':
            'SELECT e.id FROM expenses e LEFT JOIN status_history s '
                'ON e.status_history_id = s.id '
                'WHERE e.status_history_id IS NOT NULL AND s.id IS NULL',
        'status_history.application_id → applications':
            'SELECT s.id FROM status_history s LEFT JOIN applications a '
                'ON s.application_id = a.id WHERE a.id IS NULL',
        'tasks.application_id → applications':
            'SELECT t.id FROM tasks t LEFT JOIN applications a '
                'ON t.application_id = a.id '
                'WHERE t.application_id IS NOT NULL AND a.id IS NULL',
      };

      for (final entry in orphanChecks.entries) {
        final orphans = await db.customSelect(entry.value).get();
        expect(orphans, isEmpty, reason: 'ভাসমান বিদেশী কী: ${entry.key}');
      }
    });

    test('প্রতিটি প্রাইমারি কী UUID v4 ফরম্যাটের', () async {
      await DatabaseSeeder.seed(db);

      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      for (final table in [
        'persons',
        'references',
        'offices',
        'applications',
        'payments',
        'expenses',
        'independent_incomes',
        'status_history',
        'tasks',
        'work_types',
        'expense_categories',
        'income_categories',
      ]) {
        final rows = await db.customSelect('SELECT id FROM "$table"').get();
        for (final row in rows) {
          final id = row.read<String>('id');
          expect(
            uuidPattern.hasMatch(id),
            isTrue,
            reason: '$table টেবিলের প্রাইমারি কী UUID v4 নয়: $id',
          );
        }
      }
    });

    test('প্রতিটি আবেদনের আর্থিক সূত্র মেলে (BACKEND_MASTER_PLAN.md §1.2)', () async {
      await DatabaseSeeder.seed(db);

      // প্রতিটি আবেদনের জন্য আদায় ও খরচ যোগ করে তুলনা করা হচ্ছে।
      final rows = await db
          .customSelect(
            'SELECT a.id AS id, a.agreed_amount AS agreed, '
            'a.is_marked_as_paid AS marked, '
            'COALESCE((SELECT SUM(p.amount) FROM payments p '
            '  WHERE p.application_id = a.id AND p.deleted_at IS NULL), 0) '
            '  AS received, '
            'COALESCE((SELECT SUM(e.amount) FROM expenses e '
            '  WHERE e.application_id = a.id AND e.is_general = 0 '
            '  AND e.deleted_at IS NULL), 0) AS spent '
            'FROM applications a WHERE a.deleted_at IS NULL',
          )
          .get();

      expect(rows, isNotEmpty);

      for (final row in rows) {
        final id = row.read<String>('id');
        final agreed = row.read<int>('agreed');
        final marked = row.read<int>('marked');
        final received = row.read<int>('received');
        final spent = row.read<int>('spent');

        // আদায় করা টাকা চুক্তিকৃত ফির বেশি হতে পারে না।
        expect(received, lessThanOrEqualTo(agreed),
            reason: '$id: আদায় ($received) চুক্তির ফি ($agreed) বেশি');

        // কার্যকর বকেয়া = চুক্তি − আদায়; মওকুফ হলে শূন্য।
        final rawDue = agreed - received;
        final effectiveDue = marked == 1 ? 0 : rawDue;
        expect(effectiveDue, greaterThanOrEqualTo(0), reason: id);

        // প্রকৃত আয় = আদায় − ফাইলের খরচ।
        final realized = received - spent;
        expect(realized, greaterThanOrEqualTo(0), reason: id);
      }
    });

    test('সিডে আবেদন, পেমেন্ট ও খরচ বসে এবং হিসাব মেলে', () async {
      await DatabaseSeeder.seed(db);

      final appCount = await db.applications.count().getSingle();
      final payCount = await db.payments.count().getSingle();
      final expCount = await db.expenses.count().getSingle();

      expect(appCount, greaterThan(0));
      expect(payCount, greaterThan(0));
      expect(expCount, greaterThan(0));

      // প্রতিটি আবেদনের স্ন্যাপশট নাম ও ফোন খালি নয়।
      final apps = await db.select(db.applications).get();
      for (final app in apps) {
        expect(app.applicantName, isNotEmpty);
        expect(app.applicantPhone, isNotEmpty);
      }
    });

    test('isEmpty ফাঁকা ডেটাবেজে true, ভরা ডেটাবেজে false', () async {
      expect(await DatabaseSeeder.isEmpty(db), isTrue);

      await DatabaseSeeder.seed(db);

      expect(await DatabaseSeeder.isEmpty(db), isFalse);
    });
  });

  group('অখণ্ডতা বাধা (Triggers)', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('আবেদনের স্ন্যাপশট কলাম অপরিবর্তনীয়', () async {
      await db.into(db.applications).insert(
            buildApplication(id: 'app-1', applicantName: 'রহিম উদ্দিন'),
          );

      // নাম বদলানোর চেষ্টা ব্যর্থ হবে।
      expect(
        () => (db.update(db.applications)
              ..where((t) => t.id.equals('app-1')))
            .write(const ApplicationsCompanion(
          applicantName: Value('পরিবর্তিত নাম'),
        )),
        throwsA(anything),
      );

      // স্ন্যাপশট অক্ষত আছে।
      final app = await (db.select(db.applications)
            ..where((t) => t.id.equals('app-1')))
          .getSingle();
      expect(app.applicantName, 'রহিম উদ্দিন');
    });

    test('আবেদনের অফিসের নাম অপরিবর্তনীয়', () async {
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));

      expect(
        () => (db.update(db.applications)
              ..where((t) => t.id.equals('app-1')))
            .write(const ApplicationsCompanion(
          officeName: Value('অন্য অফিস'),
        )),
        throwsA(anything),
      );
    });

    test('স্ন্যাপশট কলাম বাদ দিয়ে অন্য কলাম আপডেট করা যায়', () async {
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));

      // অনুমোদিত পরিবর্তন — ব্যর্থ হওয়ার কথা নয়।
      await (db.update(db.applications)..where((t) => t.id.equals('app-1')))
          .write(const ApplicationsCompanion(
        isMarkedAsPaid: Value(1),
        updatedAt: Value(999),
      ));

      final app = await (db.select(db.applications)
            ..where((t) => t.id.equals('app-1')))
          .getSingle();
      expect(app.isMarkedAsPaid, 1);
    });

    test('পেমেন্টের অঙ্ক অপরিবর্তনীয়', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));
      await db.into(db.payments).insert(
            PaymentsCompanion.insert(
              id: 'pay-1',
              applicationId: 'app-1',
              amount: 50000,
              date: now,
              method: 'নগদ',
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(
        () => (db.update(db.payments)..where((t) => t.id.equals('pay-1')))
            .write(const PaymentsCompanion(amount: Value(1))),
        throwsA(anything),
      );

      // অঙ্ক অপরিবর্তিত।
      final payment = await (db.select(db.payments)
            ..where((t) => t.id.equals('pay-1')))
          .getSingle();
      expect(payment.amount, 50000);
    });

    test('খরচের অঙ্ক ও খাত অপরিবর্তনীয়', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // ফাইলের খরচে আবেদনের রেফারেন্স আবশ্যক (CHECK সীমাবদ্ধতা)।
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));
      await db.into(db.expenses).insert(
            ExpensesCompanion.insert(
              id: 'exp-1',
              applicationId: const Value('app-1'),
              amount: 3000,
              category: 'সরকারি ফি',
              date: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(
        () => (db.update(db.expenses)..where((t) => t.id.equals('exp-1')))
            .write(const ExpensesCompanion(amount: Value(1))),
        throwsA(anything),
      );

      expect(
        () => (db.update(db.expenses)..where((t) => t.id.equals('exp-1')))
            .write(const ExpensesCompanion(category: Value('অন্য খাত'))),
        throwsA(anything),
      );
    });

    test('পেমেন্ট সফট ডিলিট করা যায় (শুধু deleted_at বদলায়)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.applications).insert(buildApplication(id: 'app-1'));
      await db.into(db.payments).insert(
            PaymentsCompanion.insert(
              id: 'pay-1',
              applicationId: 'app-1',
              amount: 50000,
              date: now,
              method: 'নগদ',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // সফট ডিলিট অনুমোদিত — এটিই ভুল এন্ট্রি শোধরানোর নিয়ম।
      await (db.update(db.payments)..where((t) => t.id.equals('pay-1')))
          .write(PaymentsCompanion(deletedAt: Value(now)));

      final payment = await (db.select(db.payments)
            ..where((t) => t.id.equals('pay-1')))
          .getSingle();
      expect(payment.deletedAt, now);
      expect(payment.amount, 50000);
    });
  });

  group('ট্রানজ্যাকশন', () {
    late AppDatabase db;

    setUp(() => db = createTestDatabase());
    tearDown(() => db.close());

    test('ব্যর্থ হলে পুরো ট্রানজ্যাকশন রোলব্যাক হয়', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      expect(
        () => db.transaction(() async {
          await db.into(db.applications).insert(buildApplication(id: 'app-1'));
          // ইচ্ছাকৃতভাবে ব্যর্থ — টাকার পরিমাণ শূন্য।
          await db.into(db.payments).insert(
                PaymentsCompanion.insert(
                  id: 'pay-bad',
                  applicationId: 'app-1',
                  amount: 0,
                  date: now,
                  method: 'নগদ',
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }),
        throwsA(anything),
      );

      // রোলব্যাক — আবেদনও বসেনি।
      final apps = await db.select(db.applications).get();
      expect(apps, isEmpty);
    });
  });
}
