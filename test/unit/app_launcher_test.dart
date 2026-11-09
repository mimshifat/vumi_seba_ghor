import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/utils/app_launcher.dart';

void main() {
  group('AppLauncher Phone Sanitization & Formatting Tests', () {
    test('বাংলা ডিজিট ফোন নম্বরকে ইংরেজি আন্তর্জাতিক ফরম্যাটে রূপান্তর করে', () {
      expect(
        AppLauncher.cleanPhoneNumber('০১৭১২৩৪৫৬৭৮'),
        '01712345678',
      );
    });

    test('স্পেস, ড্যাশ ও প্রথম বন্ধনী পরিষ্কার করে', () {
      expect(
        AppLauncher.cleanPhoneNumber('০১৮১৯-৫৫ ৬৬ ৭৭'),
        '01819556677',
      );
      expect(
        AppLauncher.cleanPhoneNumber('(019) 11-22-33-44'),
        '01911223344',
      );
    });

    test('আন্তর্জাতিক কান্ট্রি কোড (+880) এবং প্লাস চিহ্ন অক্ষত রাখে', () {
      expect(
        AppLauncher.cleanPhoneNumber('+৮৮০ ১৮১৯-০০০০০০'),
        '+8801819000000',
      );
      expect(
        AppLauncher.cleanPhoneNumber('+880 1711-223344'),
        '+8801711223344',
      );
    });

    test('মিশ্র বাংলা ও ইংরেজি ডিজিট সঠিকভাবে পরিষ্কার করে', () {
      expect(
        AppLauncher.cleanPhoneNumber('01819-৫৫৬৬৭৭'),
        '01819556677',
      );
    });

    test('খালি বা অপ্রয়োজনীয় অক্ষরের ক্ষেত্রে নিরাপদ আচরণ করে', () {
      expect(AppLauncher.cleanPhoneNumber(''), '');
      expect(AppLauncher.cleanPhoneNumber('   '), '');
      expect(AppLauncher.cleanPhoneNumber('abc'), '');
    });
  });
}

