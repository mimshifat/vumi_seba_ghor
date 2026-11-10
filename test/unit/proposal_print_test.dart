import 'dart:io';

import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/errors/app_failure.dart';
import 'package:bhumi_kajer_hisab/features/applications/data/repositories/application_repository.dart';
import 'package:bhumi_kajer_hisab/features/applications/data/repositories/proposal_print_repository.dart';
import 'package:bhumi_kajer_hisab/features/applications/data/services/proposal_pdf_service.dart';
import 'package:bhumi_kajer_hisab/features/applications/domain/models/proposal_print_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw_sqlite;

AppDatabase _createMemoryDb() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProposalPrintRepository & ProposalPrintDao', () {
    late AppDatabase db;
    late ApplicationRepository appRepo;
    late ProposalPrintRepository printRepo;

    setUp(() {
      db = _createMemoryDb();
      appRepo = ApplicationRepository(db);
      printRepo = ProposalPrintRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<Application> createInProposalStatus({
      required String name,
      String? caseNumber,
      String officeName = 'উপজেলা ভূমি অফিস, সাভার',
    }) async {
      final app = await appRepo.createApplication(
        applicantName: name,
        applicantPhone: '01711223344',
        officeName: officeName,
        workType: 'নামজারি',
        agreedAmountPaisa: 100000,
        status: 'আবেদন',
        caseNumber: caseNumber,
      );
      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'প্রস্তাব প্রেরণ',
      );
      return (await appRepo.getApplication(app.id))!;
    }

    test('আগের ব্যাচ প্রিন্ট করার পর নতুন প্রস্তাব প্রেরণ এলে শুধু নতুনগুলোই দেখায়',
        () async {
      for (var i = 1; i <= 10; i++) {
        await createInProposalStatus(
          name: 'আবেদনকারী $i',
          caseNumber: 'CASE-10$i',
        );
      }

      final initialPending = await printRepo.getPendingProposals();
      expect(initialPending.length, 10);

      final batchId = await printRepo.createPrintBatch(
        candidates: initialPending,
      );
      expect(batchId, isNotEmpty);
      expect(await printRepo.getPendingProposals(), isEmpty);

      final newAppIds = <String>{};
      for (var i = 11; i <= 13; i++) {
        final app = await createInProposalStatus(
          name: 'নতুন আবেদনকারী $i',
          caseNumber: 'CASE-20$i',
        );
        newAppIds.add(app.id);
      }

      final newPending = await printRepo.getPendingProposals();
      expect(newPending.length, 3);
      expect(
        newPending.map((c) => c.application.id).toSet(),
        equals(newAppIds),
      );

      final batches = await printRepo.getPrintedBatches();
      expect(batches.length, 1);
      expect(batches.first.items.length, 10);
    });

    test('আগে প্রিন্ট হওয়া আবেদন অন্য অবস্থায় গিয়ে আবার প্রস্তাব প্রেরণে এলে পুনরায় তালিকায় আসে',
        () async {
      final app = await createInProposalStatus(
        name: 'রহিম উদ্দিন',
        caseNumber: 'CASE-901',
      );

      final firstPending = await printRepo.getPendingProposals();
      expect(firstPending.length, 1);

      await printRepo.createPrintBatch(candidates: firstPending);
      expect(await printRepo.getPendingProposals(), isEmpty);

      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'সংশোধন প্রয়োজন',
      );
      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'প্রস্তাব প্রেরণ',
      );

      final reopenedPending = await printRepo.getPendingProposals();
      expect(reopenedPending.length, 1);
      expect(reopenedPending.first.application.id, app.id);
    });

    test('প্রস্তাব প্রেরণ থেকে একই অবস্থায় (প্রস্তাব প্রেরণ) নোট/ফি লগ করলে পুরোনো কেস পুনরায় পেন্ডিং হয় না',
        () async {
      final app = await createInProposalStatus(
        name: 'সেলিম মিয়া',
        caseNumber: 'CASE-555',
      );

      final pending = await printRepo.getPendingProposals();
      await printRepo.createPrintBatch(candidates: pending);
      expect(await printRepo.getPendingProposals(), isEmpty);

      // একই অবস্থায় নোট যোগ করার জন্য ট্রানজিশন
      await appRepo.transitionStatus(
        applicationId: app.id,
        newStatus: 'প্রস্তাব প্রেরণ',
        note: 'কাগজপত্র যাচাই হয়েছে',
      );

      expect(await printRepo.getPendingProposals(), isEmpty);
    });

    test('কেস নম্বর ছাড়া প্রিন্ট হওয়ার পর কেস নম্বর আপডেট করলে আবেদনটি পুনরায় প্রিন্ট বাকি তালিকায় আসে',
        () async {
      final app = await createInProposalStatus(
        name: 'নাসরিন আক্তার',
        caseNumber: null,
      );

      final pending = await printRepo.getPendingProposals();
      await printRepo.createPrintBatch(candidates: pending);
      expect(await printRepo.getPendingProposals(), isEmpty);

      // পরে কেস নম্বর যোগ করা হলো
      await appRepo.updateApplication(
        id: app.id,
        caseNumber: 'CASE-777',
      );

      final reopened = await printRepo.getPendingProposals();
      expect(reopened.length, 1);
      expect(reopened.first.application.id, app.id);
      expect(reopened.first.application.caseNumber, 'CASE-777');
    });

    test('ডাবল-ট্যাপ বা স্ট্যাটাস বদলে যাওয়া অবস্থায় createPrintBatch ডুপ্লিকেট বা ইনভ্যালিড কেস বাদ দেয়',
        () async {
      final app1 = await createInProposalStatus(
        name: 'করিম',
        caseNumber: 'C-101',
      );
      final app2 = await createInProposalStatus(
        name: 'রফিক',
        caseNumber: 'C-102',
      );

      final pending = await printRepo.getPendingProposals();
      expect(pending.length, 2);

      // প্রিভিউ খোলার পর app1-এর স্ট্যাটাস বদলে 'শুনানি' হয়ে গেল
      await appRepo.transitionStatus(
        applicationId: app1.id,
        newStatus: 'শুনানি',
      );

      // ডুপ্লিকেট ক্যান্ডিডেট পাস করলেও শুধু বৈধ app2-ই একবার সংরক্ষিত হবে
      await printRepo.createPrintBatch(
        candidates: [...pending, ...pending],
      );

      final batches = await printRepo.getPrintedBatches();
      expect(batches.length, 1);
      expect(batches.first.items.length, 1);
      expect(batches.first.items.first.applicationId, app2.id);

      // আবার একই লিস্ট দিয়ে কল করলে AppFailure ছুঁড়বে, ডুপ্লিকেট ঢুকবে না
      await expectLater(
        () => printRepo.createPrintBatch(candidates: pending),
        throwsA(isA<AppFailure>()),
      );
    });

    test('ব্যাচের একটি আইটেম বা সম্পূর্ণ ব্যাচ আনমার্ক করলে পুনরায় প্রিন্ট বাকি তালিকায় ফিরে আসে',
        () async {
      await createInProposalStatus(name: 'কামাল', caseNumber: 'C-1');
      await createInProposalStatus(name: 'জামাল', caseNumber: 'C-2');

      final pending = await printRepo.getPendingProposals();
      await printRepo.createPrintBatch(candidates: pending);
      expect(await printRepo.getPendingProposals(), isEmpty);

      final batches = await printRepo.getPrintedBatches();
      expect(batches.first.items.length, 2);

      await printRepo.unmarkItem(batches.first.items.first.id);
      final afterSingleUnmark = await printRepo.getPendingProposals();
      expect(afterSingleUnmark.length, 1);

      await printRepo.unmarkBatch(batches.first.batch.id);
      final afterBatchUnmark = await printRepo.getPendingProposals();
      expect(afterBatchUnmark.length, 2);
      expect(await printRepo.getPrintedBatches(), isEmpty);
    });

    test('সফট-ডিলিট করা আবেদন প্রিন্ট বাকি তালিকায় আসে না', () async {
      final app = await createInProposalStatus(
        name: 'ডিলিট টেস্ট',
        caseNumber: 'DEL-1',
      );
      await appRepo.deleteApplication(app.id);

      expect(await printRepo.getPendingProposals(), isEmpty);
    });
  });

  group('স্কিমা মাইগ্রেশন (v1 -> v2)', () {
    test('পুরনো v1 ডেটাবেজ খুললে v2 টেবিল ও ইউনিক ইনডেক্স অক্ষতভাবে তৈরি হয়', () async {
      final tempDir = Directory.systemTemp.createTempSync('rojob_mig_v2_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final dbFile = File('${tempDir.path}/legacy_v1.sqlite');

      final raw = raw_sqlite.sqlite3.open(dbFile.path);
      raw.execute('''
        CREATE TABLE applications (
          id TEXT PRIMARY KEY,
          applicant_id TEXT,
          applicant_name TEXT NOT NULL,
          applicant_phone TEXT NOT NULL,
          applicant_address TEXT,
          reference_id TEXT,
          reference_name TEXT,
          office_id TEXT,
          office_name TEXT NOT NULL,
          mouza TEXT,
          app_number TEXT,
          case_number TEXT,
          work_type TEXT NOT NULL,
          application_date INTEGER NOT NULL,
          status TEXT NOT NULL,
          agreed_amount INTEGER NOT NULL,
          is_marked_as_paid INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        CREATE TABLE status_history (
          id TEXT PRIMARY KEY,
          application_id TEXT NOT NULL,
          prev_status TEXT,
          new_status TEXT NOT NULL,
          changed_at INTEGER NOT NULL,
          note TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        );
        PRAGMA user_version = 1;
      ''');
      raw.close();

      final upgradedDb = AppDatabase(NativeDatabase(dbFile));
      try {
        final tables = await upgradedDb
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' "
              "AND name IN ('proposal_print_batches', 'proposal_print_batch_items')",
            )
            .get();
        expect(tables.length, 2);

        final uniqueIdx = await upgradedDb
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='index' "
              "AND name = 'idx_proposal_batch_items_unique_active'",
            )
            .get();
        expect(uniqueIdx.length, 1);

        final versionRow =
            await upgradedDb.customSelect('PRAGMA user_version;').getSingle();
        expect(
          versionRow.read<int>('user_version'),
          AppDatabase.currentSchemaVersion,
        );
      } finally {
        await upgradedDb.close();
      }
    });
  });

  group('ProposalPdfService (Canvas বাংলা শেপিং)', () {
    testWidgets('মাল্টি-পেজ বাংলা তালিকার বৈধ PDF বাইট তৈরি করে', (tester) async {
      await tester.runAsync(() async {
        final rows = List.generate(
          45,
          (i) => ProposalPrintRow(
            applicantName: 'আব্দুল করিম ও ফাতেমা খাতুন (${i + 1})',
            caseNumber: 'নামজারি-${100 + i}/২০২৬',
          ),
        );

        final pdfBytes = await ProposalPdfService.buildProposalListPdf(
          rows: rows,
          officeLabel: 'উপজেলা ভূমি অফিস, সাভার',
        );

        expect(pdfBytes, isNotEmpty);
        expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
      });
    });
  });
}
