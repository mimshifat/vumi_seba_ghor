import 'package:bhumi_kajer_hisab/core/theme/app_theme.dart';
import 'package:bhumi_kajer_hisab/core/utils/case_number_formatter.dart';
import 'package:bhumi_kajer_hisab/core/utils/validators.dart';
import 'package:bhumi_kajer_hisab/core/widgets/case_number_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseNumberFormatter - অর্থবছর গণনা (১ জুলাই – ৩০ জুন)', () {
    test('৩০ জুন ২০১৫ পর্যন্ত ২০১৪-২০১৫ অর্থবছর', () {
      expect(
        CaseNumberFormatter.fiscalYearForDate(DateTime(2015, 6, 30)),
        '২০১৪-২০১৫',
      );
      expect(
        CaseNumberFormatter.fiscalYearForDate(
          DateTime(2015, 6, 30),
          bengaliDigits: false,
        ),
        '2014-2015',
      );
    });

    test('১ জুলাই ২০১৫ থেকে ৩০ জুন ২০১৬ পর্যন্ত ২০১৫-২০১৬ অর্থবছর', () {
      expect(
        CaseNumberFormatter.fiscalYearForDate(DateTime(2015, 7, 1)),
        '২০১৫-২০১৬',
      );
      expect(
        CaseNumberFormatter.fiscalYearForDate(DateTime(2016, 6, 30)),
        '২০১৫-২০১৬',
      );
    });

    test('১ জুলাই ২০২৫ থেকে ৩০ জুন ২০২৬ পর্যন্ত ২০২৫-২০২৬ অর্থবছর', () {
      expect(
        CaseNumberFormatter.fiscalYearForDate(DateTime(2025, 7, 1)),
        '২০২৫-২০২৬',
      );
      expect(
        CaseNumberFormatter.fiscalYearForDate(DateTime(2026, 6, 30)),
        '২০২৫-২০২৬',
      );
    });

    test('১ জুলাই ২০২৬ থেকে ২০২৬-২০২৭ অর্থবছর', () {
      expect(
        CaseNumberFormatter.fiscalYearForDate(DateTime(2026, 7, 1)),
        '২০২৬-২০২৭',
      );
    });
  });

  group('CaseNumberFormatter - পার্সিং ও ফরম্যাটিং', () {
    test('ইংরেজি অঙ্ক ও ছোট হাতের রেজিস্টার কোডকে আদর্শ বাংলা রূপে সাজায়', () {
      expect(
        CaseNumberFormatter.format('7091/ix-i/2014-2015'),
        '৭০৯১/IX-I/২০১৪-২০১৫',
      );
      expect(
        CaseNumberFormatter.format(' 42 / IX-I / 2025-26 '),
        '৪২/IX-I/২০২৫-২০২৬',
      );
    });

    test('en-dash ও অতিরিক্ত প্রিফিক্স পরিষ্কার করে', () {
      expect(
        CaseNumberFormatter.format('কেস নং: ৭০৯১/IX-I/২০২৫–২০২৬'),
        '৭০৯১/IX-I/২০২৫-২০২৬',
      );
      expect(
        CaseNumberFormatter.format('Case No. 42/ix-1/2025-2026'),
        '৪২/IX-I/২০২৫-২০২৬',
      );
    });

    test('২-অংশের ইনপুটে স্বয়ংক্রিয়ভাবে IX-I রেজিস্টার কোড বসায়', () {
      expect(
        CaseNumberFormatter.format('7091/2025-2026'),
        '৭০৯১/IX-I/২০২৫-২০২৬',
      );
      expect(
        CaseNumberFormatter.format('১৫/২০২৫-২৬'),
        '১৫/IX-I/২০২৫-২০২৬',
      );
    });

    test('শুধু ক্রমিক দিলে referenceDate অনুযায়ী পূর্ণ ফরম্যাট তৈরি করে', () {
      expect(
        CaseNumberFormatter.format(
          '7091',
          referenceDate: DateTime(2026, 3, 15),
        ),
        '৭০৯১/IX-I/২০২৫-২০২৬',
      );
      expect(
        CaseNumberFormatter.format(
          '৭০৯১',
          referenceDate: DateTime(2026, 7, 1),
        ),
        '৭০৯১/IX-I/২০২৬-২০২৭',
      );
    });

    test('normalizeIfStructured লিগ্যাসি কোড বা শুধু সংখ্যা অপরিবর্তিত রাখে', () {
      expect(CaseNumberFormatter.normalizeIfStructured('CASE-777'), 'CASE-777');
      expect(CaseNumberFormatter.normalizeIfStructured('7091'), '7091');
      expect(
        CaseNumberFormatter.normalizeIfStructured('7091/ix-i/2025-2026'),
        '৭০৯১/IX-I/২০২৫-২০২৬',
      );
    });
  });

  group('CaseNumberFormatter & AppValidators - ভ্যালিডেশন', () {
    test('খালি বা null মান বৈধ (ঐচ্ছিক ফিল্ড)', () {
      expect(AppValidators.validateCaseNumber(null), isNull);
      expect(AppValidators.validateCaseNumber(''), isNull);
      expect(AppValidators.validateCaseNumber('   '), isNull);
    });

    test('বৈধ ৩-অংশ ও ২-অংশ কেস নম্বর গ্রহণ করে', () {
      expect(AppValidators.validateCaseNumber('৭০৯১/IX-I/২০২৫-২০২৬'), isNull);
      expect(AppValidators.validateCaseNumber('7091/IX-I/2025-2026'), isNull);
      expect(AppValidators.validateCaseNumber('7091/2025-2026'), isNull);
      expect(AppValidators.validateCaseNumber('৩/মিস/২০২৫-২০২৬'), isNull);
    });

    test('ভুল ফরম্যাট বা অধারাবাহিক অর্থবছর প্রত্যাখ্যান করে', () {
      expect(
        AppValidators.validateCaseNumber('7091'),
        CaseNumberFormatter.invalidFormatMessage,
      );
      expect(
        AppValidators.validateCaseNumber('42/2026'),
        CaseNumberFormatter.invalidFormatMessage,
      );
      expect(
        AppValidators.validateCaseNumber('7091/IX-I/2025-2027'),
        CaseNumberFormatter.invalidFormatMessage,
      );
      expect(
        AppValidators.validateCaseNumber('0/IX-I/2025-2026'),
        CaseNumberFormatter.invalidFormatMessage,
      );
      expect(
        AppValidators.validateCaseNumber('abc'),
        CaseNumberFormatter.invalidFormatMessage,
      );
    });

    test('compareCaseNumbers অর্থবছর ও ক্রমিক অনুযায়ী সংখ্যাগতভাবে সর্ট করে', () {
      final list = [
        '১০০/IX-I/২০২৫-২০২৬',
        '১/IX-I/২০২৬-২০২৭',
        '৯/IX-I/২০২৫-২০২৬',
        '১৫/IX-I/২০২৫-২০২৬',
      ];
      list.sort(CaseNumberFormatter.compareCaseNumbers);
      expect(list, [
        '৯/IX-I/২০২৫-২০২৬',
        '১৫/IX-I/২০২৫-২০২৬',
        '১০০/IX-I/২০২৫-২০২৬',
        '১/IX-I/২০২৬-২০২৭',
      ]);
    });
  });

  group('CaseNumberField উইজেট', () {
    testWidgets('সরাসরি ফরম্যাট দেখায় এবং ইংরেজি ক্রমিক লিখলে স্বয়ংক্রিয় বাংলা ও পূর্ণ ফরম্যাট তৈরি করে',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CaseNumberField(
                controller: controller,
                referenceDate: DateTime(2026, 5, 10),
              ),
            ),
          ),
        ),
      );

      expect(find.text('কেস নম্বর'), findsOneWidget);
      // ফিক্সড ফরম্যাট অনুসর্গ দৃশ্যমান
      expect(find.text('/IX-I/২০২৫-২০২৬'), findsOneWidget);

      // ইংরেজিতে '7091' লিখলে স্বয়ংক্রিয়ভাবে বাংলা '৭০৯১' হবে এবং কন্ট্রোলারে পূর্ণ ফরম্যাট যাবে
      await tester.enterText(find.byType(TextFormField), '7091');
      await tester.pump();

      expect(find.text('৭০৯১'), findsOneWidget);
      expect(controller.text, '৭০৯১/IX-I/২০২৫-২০২৬');

      // ক্রমিক মুছে দিলে কন্ট্রোলার ফাঁকা হবে
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      expect(controller.text, '');

      // পুরো কেস নম্বর পেস্ট করলেও স্বয়ংক্রিয়ভাবে শুধু ক্রমিকটুকু ফিল্টার করবে
      await tester.enterText(find.byType(TextFormField), '39/IX-I/2025-2026');
      await tester.pump();
      expect(find.text('৩৯'), findsOneWidget);
      expect(controller.text, '৩৯/IX-I/২০২৫-২০২৬');
    });
  });
}

