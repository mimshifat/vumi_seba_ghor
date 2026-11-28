import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/database/app_database.dart';
import 'package:bhumi_kajer_hisab/core/database/database_seeder.dart';
import 'package:bhumi_kajer_hisab/core/demo/demo_data.dart';
import 'package:bhumi_kajer_hisab/features/offices/data/repositories/office_repository.dart';
import 'package:bhumi_kajer_hisab/features/offices/domain/models/office_mouza_data.dart';
import 'package:bhumi_kajer_hisab/features/offices/presentation/widgets/office_mouza_selector.dart';

void main() {
  group('OfficeMouzaData Tests', () {
    test('চাঁপাইনবাবগঞ্জ সদর উপজেলার সকল ইউনিয়ন ও পৌর ভূমি অফিসের জন্য মৌজা ম্যাপিং বিদ্যমান', () {
      expect(OfficeMouzaData.officeMouzaMap.isNotEmpty, true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('পৌর ভূমি অফিস, চাঁপাইনবাবগঞ্জ'), true);
      expect(OfficeMouzaData.officeMouzaMap['পৌর ভূমি অফিস, চাঁপাইনবাবগঞ্জ']!.length, greaterThanOrEqualTo(30));

      // সদর উপজেলার ১৪টি ইউনিয়ন ভূমি অফিস
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, আলাতূলী'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, ইসলামপুর'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, গোবরাতলা'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, চর অনুপনগর'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, চরবাগডাঙ্গা'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, ঝিলিম'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, দেবীনগর'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, নারায়ণপুর'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, বারঘরিয়া'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, বালিয়াডাঙ্গা'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, মহারাজপুর'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, রানীহাটি'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, শাহজাহানপুর'), true);
      expect(OfficeMouzaData.officeMouzaMap.containsKey('ইউনিয়ন ভূমি অফিস, সুন্দরপুর'), true);

      // বালিয়াডাঙ্গার পূর্ণাঙ্গ মৌজা তালিকা যাচাই
      final baliadangaMouzas = OfficeMouzaData.officeMouzaMap['ইউনিয়ন ভূমি অফিস, বালিয়াডাঙ্গা']!;
      expect(baliadangaMouzas.length, greaterThanOrEqualTo(30));
      expect(baliadangaMouzas.contains('বালিয়াডাঙ্গা'), true);
      expect(baliadangaMouzas.contains('রামজীবনপুর'), true);
      expect(baliadangaMouzas.contains('শ্রীরামপুর'), true);
      expect(baliadangaMouzas.contains('পাহানপুর'), true);
      expect(baliadangaMouzas.contains('পালশা'), true);
      expect(baliadangaMouzas.contains('দিননাথপুর'), true);
      expect(baliadangaMouzas.contains('দিলালপুর'), true);
      expect(baliadangaMouzas.contains('মানপুর'), true);
      expect(baliadangaMouzas.contains('রান্দরা'), true);
      expect(baliadangaMouzas.contains('গোবর্নাথপুর'), true);
      expect(baliadangaMouzas.contains('চকঝগড়ু'), true);
      expect(baliadangaMouzas.contains('বাঁশবাড়িয়া'), true);
    });

    test('নির্দিষ্ট অফিসের অধীনস্থ মৌজা সঠিকভাবে লোড হয়', () {
      final barghariaMouzas = OfficeMouzaData.getMouzasForOffice('ইউনিয়ন ভূমি অফিস, বারঘরিয়া');
      expect(barghariaMouzas.contains('বারঘরিয়া'), true);
      expect(barghariaMouzas.contains('লাহারপুর'), true);
      expect(barghariaMouzas.contains('চামাগ্রাম'), true);

      final pourashavaMouzas = OfficeMouzaData.getMouzasForOffice('পৌর ভূমি অফিস, চাঁপাইনবাবগঞ্জ');
      expect(pourashavaMouzas.contains('হুজরাপুর'), true);
      expect(pourashavaMouzas.contains('দাউদপুর'), true);
      expect(pourashavaMouzas.contains('নিমগাছী'), true);
    });

    test('উপজেলা বা জেলা পর্যায়ের অফিসের জন্য উপজেলার সকল মৌজা উন্মুক্ত থাকে', () {
      final sadarMouzas = OfficeMouzaData.getMouzasForOffice('উপজেলা ভূমি অফিস, চাঁপাইনবাবগঞ্জ সদর');
      expect(sadarMouzas.length, greaterThanOrEqualTo(100));
      expect(sadarMouzas.contains('হুজরাপুর'), true);
      expect(sadarMouzas.contains('বারঘরিয়া'), true);
      expect(sadarMouzas.contains('মহারাজপুর'), true);
      expect(sadarMouzas.contains('বালিয়াডাঙ্গা'), true);
      expect(sadarMouzas.contains('রামজীবনপুর'), true);
      expect(sadarMouzas.contains('ঝিলিম (জে.এল নং ৬৭)'), true);
    });

    test('কাস্টম মৌজা যোগ করলে তালিকার সাথে সমন্বিত হয়', () {
      final custom = ['নতুন কাস্টম মৌজা'];
      final res = OfficeMouzaData.getMouzasForOffice(
        'ইউনিয়ন ভূমি অফিস, বারঘরিয়া',
        customMouzas: custom,
      );
      expect(res.contains('নতুন কাস্টম মৌজা'), true);
      expect(res.contains('বারঘরিয়া'), true);
    });

    test('যেকোনো (প্রমিত বা ডিফল্ট) মৌজা ডিলিট বা এক্সক্লুড করা যায়', () {
      final beforeDelete = OfficeMouzaData.getMouzasForOffice('ইউনিয়ন ভূমি অফিস, বারঘরিয়া');
      expect(beforeDelete.contains('বারঘরিয়া'), true);

      // 'বারঘরিয়া' ডিলিট তালিকায় যোগ করলে তা রিটার্নকৃত তালিকায় আর থাকবে না
      final afterDelete = OfficeMouzaData.getMouzasForOffice(
        'ইউনিয়ন ভূমি অফিস, বারঘরিয়া',
        deletedMouzas: ['বারঘরিয়া'],
      );
      expect(afterDelete.contains('বারঘরিয়া'), false);
      expect(afterDelete.contains('লাহারপুর'), true);
    });

    test('আলাতুলী এবং আলাতূলী বানানভেদে সঠিক ১৯টি মৌজা লোড হয়, কোনোভাবেই ৫২৯টি নয়', () {
      final mouzasHraswa = OfficeMouzaData.getMouzasForOffice('ইউনিয়ন ভূমি অফিস, আলাতুলী');
      final mouzasDirgha = OfficeMouzaData.getMouzasForOffice('ইউনিয়ন ভূমি অফিস, আলাতূলী');

      expect(mouzasHraswa.length, 19);
      expect(mouzasDirgha.length, 19);
      expect(mouzasHraswa.length, isNot(529));
    });

    test('অপরিচিত বা কাস্টম ইউনিয়ন অফিসে ৫২৯টি সদর মৌজা ওভারফ্লো করে না', () {
      final res = OfficeMouzaData.getMouzasForOffice('ইউনিয়ন ভূমি অফিস, অজানা কোনো ইউনিয়ন');
      expect(res.isEmpty, true);
    });

    test('DemoStore.offices শুধুমাত্র চাঁপাইনবাবগঞ্জ সদরের ১৯টি অফিস রয়েছে', () {
      expect(DemoStore.offices.length, 19);
      for (final office in DemoStore.offices) {
        expect(office.mouzas.isNotEmpty, true, reason: '${office.name}-এ কোনো মৌজা নেই');
      }
    });
  });

  group('OfficeMouzaSelector Widget Flow Tests', () {
    testWidgets('অফিস নির্বাচন ও তার অধীনস্থ মৌজা প্রদর্শন করে', (tester) async {
      String? selectedOffice = 'ইউনিয়ন ভূমি অফিস, বারঘরিয়া';
      final mouzaController = TextEditingController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return OfficeMouzaSelector(
                      selectedOffice: selectedOffice,
                      onOfficeChanged: (val) {
                        setState(() => selectedOffice = val);
                      },
                      mouzaController: mouzaController,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // অফিসের নাম ও মৌজার নাম প্রদর্শিত হচ্ছে
      expect(find.textContaining('অফিসের নাম'), findsOneWidget);
      expect(find.textContaining('মৌজার নাম'), findsOneWidget);
      expect(find.text('মৌজা নির্বাচন করুন...'), findsOneWidget);

      // মৌজা ড্রপডাউনে ট্যাপ করলে সার্চ শিট খোলে
      await tester.tap(find.text('মৌজা নির্বাচন করুন...'));
      await tester.pumpAndSettle();

      // সার্চ বক্সে 'চামাগ্রাম' লিখে সহজে মৌজা ফিল্টার ও নির্বাচন করা
      final searchFieldFinder = find.widgetWithText(TextField, 'মৌজার নাম দিয়ে সার্চ করুন...');
      expect(searchFieldFinder, findsOneWidget);
      await tester.enterText(searchFieldFinder, 'চামাগ্রাম');
      await tester.pumpAndSettle();

      // সার্চকৃত মৌজা পাওয়া যাচ্ছে
      expect(find.text('চামাগ্রাম'), findsWidgets);

      // কাঙ্ক্ষিত মৌজায় ট্যাপ করলে কন্ট্রোলারে টেক্সট সেট হয় এবং শিট বন্ধ হয়
      final mouzaTileFinder = find.widgetWithText(ListTile, 'চামাগ্রাম');
      expect(mouzaTileFinder, findsOneWidget);
      await tester.tap(mouzaTileFinder);
      await tester.pumpAndSettle();

      expect(mouzaController.text, 'চামাগ্রাম');

      // অফিস ড্রপডাউনে ট্যাপ করলে অফিস সার্চ শিট খোলে
      await tester.tap(find.text('ইউনিয়ন ভূমি অফিস, বারঘরিয়া'));
      await tester.pumpAndSettle();

      final officeSearchFinder = find.widgetWithText(TextField, 'অফিসের নাম দিয়ে সার্চ করুন...');
      expect(officeSearchFinder, findsOneWidget);
      await tester.enterText(officeSearchFinder, 'মহারাজপুর');
      await tester.pumpAndSettle();

      final officeTileFinder = find.widgetWithText(ListTile, 'ইউনিয়ন ভূমি অফিস, মহারাজপুর');
      expect(officeTileFinder, findsOneWidget);
      await tester.tap(officeTileFinder);
      await tester.pumpAndSettle();

      expect(selectedOffice, 'ইউনিয়ন ভূমি অফিস, মহারাজপুর');
    });
  });

  group('DatabaseSeeder Lifecycle & Data Safety Tests', () {
    test('নতুন ইনস্টলে (খালি ডাটাবেজ) ১৯টি অফিস সঠিকভাবে তৈরি হয়', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        await DatabaseSeeder.seedEssentialDefaults(db);
        final offices = await db.select(db.offices).get();
        expect(offices.length, 19);
        for (final off in offices) {
          expect(off.name.isNotEmpty, true);
        }
      } finally {
        await db.close();
      }
    });

    test('আগের ডেটা থাকলে পুনরায় সিডিংয়ে কোনো ডেটা নষ্ট হয় না বা ডুপ্লিকেট হয় না', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        // ১. প্রথমবার সিড (অ্যাপ চালুর মতো)
        await DatabaseSeeder.seedEssentialDefaults(db);
        final initialCount = (await db.select(db.offices).get()).length;
        expect(initialCount, 19);

        // ২. ব্যবহারকারী কোনো কাস্টম অফিস যুক্ত করলেন
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.into(db.offices).insert(
              OfficesCompanion.insert(
                id: 'custom-off-1',
                name: 'আমার নিজস্ব বিশেষ ভূমি অফিস',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // ৩. দ্বিতীয়বার সিড রান হলো (অ্যাপ রিস্টার্টের মতো)
        await DatabaseSeeder.seedEssentialDefaults(db);

        // ৪. যাচাই: কাস্টম অফিস অক্ষত আছে, এবং ডুপ্লিকেট হয়নি
        final afterOffices = await db.select(db.offices).get();
        expect(afterOffices.any((o) => o.name == 'আমার নিজস্ব বিশেষ ভূমি অফিস'), true);
        expect(afterOffices.where((o) => o.name == 'ইউনিয়ন ভূমি অফিস, বালিয়াডাঙ্গা').length, 1);
      } finally {
        await db.close();
      }
    });

    test('অফিস তৈরি, সম্পাদনা এবং স্মার্ট ডিলিট (Create, Edit, Delete) নির্ভুলভাবে কাজ করে', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repo = OfficeRepository(db);

        // ১. Create
        final created = await repo.createOffice(name: 'পরীক্ষামূলক ভূমি অফিস');
        expect(created.name, 'পরীক্ষামূলক ভূমি অফিস');

        // ২. Edit / Update
        await repo.updateOffice(id: created.id, name: 'আপডেটকৃত ভূমি অফিস');
        final updated = await repo.getOffice(created.id);
        expect(updated?.name, 'আপডেটকৃত ভূমি অফিস');

        // ৩. Delete (কোনো আবেদন না থাকলে সম্পূর্ণ হার্ড ডিলিট)
        final deleted = await repo.deleteOffice(created.id);
        expect(deleted, true);
        final afterDelete = await repo.getOffice(created.id);
        expect(afterDelete, isNull);
      } finally {
        await db.close();
      }
    });
  });
}
