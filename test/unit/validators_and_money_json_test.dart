import 'package:bhumi_kajer_hisab/core/utils/money.dart';
import 'package:bhumi_kajer_hisab/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money JSON সিরিয়ালাইজেশন', () {
    test('toJson সবসময় পয়সা (integer) ফেরত দেয়', () {
      expect(Money.fromTaka(7000).toJson(), 700000);
      expect(Money.fromTaka(0).toJson(), 0);
      expect(Money.fromTaka(12.5).toJson(), 1250);
      expect(Money.zero.toJson(), 0);
    });

    test('toJson-এর ফলাফল int টাইপের', () {
      expect(Money.fromTaka(1234.56).toJson(), isA<int>());
    });

    test('fromJson পয়সা থেকে সঠিক Money তৈরি করে', () {
      expect(Money.fromJson(700000), Money.fromTaka(7000));
      expect(Money.fromJson(0), Money.zero);
      expect(Money.fromJson(1250), Money.fromTaka(12.5));
    });

    test('round-trip — toJson তারপর fromJson একই মান ফেরত দেয়', () {
      for (final amount in [0, 1, 99, 100, 1234, 700000, 999999]) {
        final money = Money.fromPaisa(amount);
        expect(Money.fromJson(money.toJson()), money);
      }
    });

    test('fromJson স্ট্রিং গ্রহণ করে', () {
      expect(Money.fromJson('7000'), Money.fromTaka(7000));
    });

    test('fromJson অবৈধ মানের জন্য zero ফেরত দেয় না — বরং ছুঁড়ে দেয়', () {
      // চুপচাপ শূন্য হিসেবে গণনা করলে আর্থিক হিসাব ভুল হতো।
      expect(() => Money.fromJson(null), throwsA(anything));
      expect(() => Money.fromJson(<String, dynamic>{}), throwsA(anything));
    });

    test('fromJson ভাসমান অংশযুক্ত মান গ্রহণ করে না', () {
      expect(() => Money.fromJson(12.5), throwsA(anything));
    });

    test('fromJson পূর্ণসংখ্যা num কে পয়সা হিসেবে ধরে', () {
      expect(Money.fromJson(700000), Money.fromTaka(7000));
      expect(Money.fromJson(700000.0), Money.fromTaka(7000));
    });

    test('fromJson — অবৈধ লেখা চুপচাপ zero হয় না, বরং ত্রুটি দেয়', () {
      // আগের আচরণে `fromJson('garbage')` চুপচাপ Money.zero ফেরত দিত,
      // যা আর্থিক হিসাবে ভুল ফল দেয় (BACKEND_MASTER_PLAN.md)।
      expect(() => Money.fromJson(''), throwsA(isA<FormatException>()));
      expect(() => Money.fromJson('garbage'), throwsA(isA<FormatException>()));
      expect(() => Money.fromJson('12.345'), throwsA(isA<FormatException>()));
      expect(() => Money.fromJson('123abc'), throwsA(isA<FormatException>()));
    });

    test('fromJson — দশমিক লেখা সঠিকভাবে পয়সায় রূপান্তর হয়', () {
      expect(Money.fromJson('12.50'), Money.fromPaisa(1250));
      expect(Money.fromJson('12.5'), Money.fromPaisa(1250));
      expect(Money.fromJson('12.05'), Money.fromPaisa(1205));
      expect(Money.fromJson('0.99'), Money.fromPaisa(99));
    });

    test('fromJson — বাংলা অঙ্ক ও টাকা চিহ্ন সমর্থন করে', () {
      expect(Money.fromJson('৭০০০'), Money.fromPaisa(700000));
      expect(Money.fromJson('৳7,000'), Money.fromPaisa(700000));
    });

    test('fromJson — নেতিবাচক মান ঠিকভাবে রক্ষণ করে', () {
      expect(Money.fromJson('-500'), Money.fromPaisa(-50000));
      expect(Money.fromJson(-500), Money.fromPaisa(-500));
    });
  });

  group('Money পূর্ণসংখ্যা-নিরাপত্তা (BACKEND_MASTER_PLAN.md)', () {
    test('fromTaka — পূর্ণসংখ্যা ইনপুটে কোনো ভাসমান মাধ্যমিক নেই', () {
      expect(Money.fromTaka(7000).paisa, 700000);
      expect(Money.fromTaka(0).paisa, 0);
    });

    test('operator* — পূর্ণসংখ্যা গুণকে নিখুঁত গুণন', () {
      expect((Money.fromTaka(1000) * 3).paisa, 300000);
    });

    test('operator+ ও operator- — পয়সা হিসাব সঠিক', () {
      expect((Money.fromTaka(1000) + Money.fromTaka(500)).paisa, 150000);
      expect((Money.fromTaka(1000) - Money.fromTaka(500)).paisa, 50000);
    });
  });

  group('মোবাইল নম্বর যাচাই', () {
    test('১১ ডিজিটের বাংলাদেশি নম্বর গ্রহণ করে', () {
      expect(AppValidators.isValidPhone('01711223344'), isTrue);
      expect(AppValidators.isValidPhone('01819876543'), isTrue);
      expect(AppValidators.isValidPhone('01912345678'), isTrue);
    });

    test('বাংলা অঙ্কেও একইভাবে কাজ করে', () {
      expect(AppValidators.isValidPhone('০১৭১১২২৩৩৪৪'), isTrue);
      expect(AppValidators.isValidPhone('০১৮১৯৮৭৬৫৪৩'), isTrue);
    });

    test('মিশ্র অঙ্ক গ্রহণ করে', () {
      expect(AppValidators.isValidPhone('০১৭১১2২৩৩৪৪'), isTrue);
    });

    test('স্পেস ও ড্যাশ থাকলেও গ্রহণ করে', () {
      expect(AppValidators.isValidPhone('01711-223344'), isTrue);
      expect(AppValidators.isValidPhone('017 11 223344'), isTrue);
      expect(AppValidators.isValidPhone('+8801711223344'), isTrue);
      expect(AppValidators.isValidPhone('008801711223344'), isTrue);
      expect(AppValidators.isValidPhone('8801711223344'), isTrue);
    });

    test('ভুল দৈর্ঘ্য বা ভুল প্রিফিক্স গ্রহণ করে না', () {
      expect(AppValidators.isValidPhone('0171122334'), isFalse); // ১০ অঙ্ক
      expect(AppValidators.isValidPhone('017112233445'), isFalse); // ১২ অঙ্ক
      expect(AppValidators.isValidPhone('02711223344'), isFalse); // ০ দিয়ে শুরু
      expect(AppValidators.isValidPhone('abcdefghijk'), isFalse);
      expect(AppValidators.isValidPhone(''), isFalse);
      expect(AppValidators.isValidPhone(null), isFalse);
    });
  });

  group('আবশ্যক-বার্তা (BACKEND_MASTER_PLAN.md)', () {
    test('আবেদনকারীর নাম আবশ্যক', () {
      expect(
        AppValidators.validateApplicantName(''),
        'আবেদনকারীর নাম আবশ্যক',
      );
      expect(
        AppValidators.validateApplicantName(null),
        'আবেদনকারীর নাম আবশ্যক',
      );
      expect(AppValidators.validateApplicantName('রহিম'), isNull);
    });

    test('মোবাইল নম্বর আবশ্যক', () {
      expect(AppValidators.validatePhone(''), 'মোবাইল নম্বর আবশ্যক');
      expect(AppValidators.validatePhone(null), 'মোবাইল নম্বর আবশ্যক');
    });

    test('সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন', () {
      expect(
        AppValidators.validatePhone('12345'),
        'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন',
      );
    });

    test('ভূমি অফিস নির্বাচন আবশ্যক', () {
      expect(AppValidators.validateOffice(''), 'ভূমি অফিস নির্বাচন আবশ্যক');
      expect(AppValidators.validateOffice(null), 'ভূমি অফিস নির্বাচন আবশ্যক');
      expect(AppValidators.validateOffice('অফিস'), isNull);
    });

    test('কাজের ধরন নির্বাচন আবশ্যক', () {
      expect(
        AppValidators.validateWorkType(''),
        'কাজের ধরন নির্বাচন আবশ্যক',
      );
      expect(AppValidators.validateWorkType(null), 'কাজের ধরন নির্বাচন আবশ্যক');
      expect(AppValidators.validateWorkType('নামজারি'), isNull);
    });

    test('চুক্তির সার্ভিস ফি উল্লেখ করুন', () {
      expect(
        AppValidators.validateAgreedAmount(''),
        'চুক্তির সার্ভিস ফি উল্লেখ করুন',
      );
      expect(
        AppValidators.validateAgreedAmount('0'),
        'চুক্তির সার্ভিস ফি উল্লেখ করুন',
      );
      expect(
        AppValidators.validateAgreedAmount('-100'),
        'চুক্তির সার্ভিস ফি উল্লেখ করুন',
      );
      expect(AppValidators.validateAgreedAmount('7000'), isNull);
    });

    test('আয়ের পরিমাণ উল্লেখ করুন', () {
      expect(AppValidators.validateIncomeAmount(''), 'আয়ের পরিমাণ উল্লেখ করুন');
      expect(
        AppValidators.validateIncomeAmount('0'),
        'আয়ের পরিমাণ উল্লেখ করুন',
      );
      expect(AppValidators.validateIncomeAmount('1200'), isNull);
    });

    test('খরচের পরিমাণ উল্লেখ করুন', () {
      expect(
        AppValidators.validateExpenseAmount(''),
        'খরচের পরিমাণ উল্লেখ করুন',
      );
      expect(
        AppValidators.validateExpenseAmount('0'),
        'খরচের পরিমাণ উল্লেখ করুন',
      );
      expect(AppValidators.validateExpenseAmount('850'), isNull);
    });

    test('খরচের খাত নির্বাচন করুন', () {
      expect(
        AppValidators.validateExpenseCategory(''),
        'খরচের খাত নির্বাচন করুন',
      );
      expect(AppValidators.validateExpenseCategory(null), 'খরচের খাত নির্বাচন করুন');
      expect(AppValidators.validateExpenseCategory('সরকারি ফি'), isNull);
    });
  });

  group('পয়সা পার্সিং', () {
    test('পূর্ণ টাকা', () {
      expect(AppValidators.parsePaisa('7000'), 700000);
      expect(AppValidators.parsePaisa('৭০০০'), 700000);
    });

    test('দশমিক টাকা', () {
      expect(AppValidators.parsePaisa('12.5'), 1250);
      expect(AppValidators.parsePaisa('12.05'), 1205);
      expect(AppValidators.parsePaisa('12.50'), 1250);
    });

    test('৳ চিহ্ন ও কমা সরানো হয়', () {
      expect(AppValidators.parsePaisa('৳7,000'), 700000);
    });

    test('অবৈধ ইনপুটে null', () {
      expect(AppValidators.parsePaisa(''), isNull);
      expect(AppValidators.parsePaisa('abc'), isNull);
      expect(AppValidators.parsePaisa(null), isNull);
      expect(AppValidators.parsePaisa('1.234'), isNull);
    });
  });
}
