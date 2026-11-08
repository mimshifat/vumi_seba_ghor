import 'package:flutter_test/flutter_test.dart';
import 'package:bhumi_kajer_hisab/core/utils/bengali_digits.dart';

void main() {
  group('BengaliDigits Conversion Tests', () {
    test('English digits to Bengali digits', () {
      expect(BengaliDigits.toBengali('0123456789'), equals('০১২৩৪৫৬৭৮৯'));
      expect(BengaliDigits.toBengali(2026), equals('২০২৬'));
      expect(BengaliDigits.toBengali('SAV-8841'), equals('SAV-৮৮৪১'));
    });

    test('Bengali digits to English digits', () {
      expect(BengaliDigits.toEnglish('০১২৩৪৫৬৭৮৯'), equals('0123456789'));
      expect(BengaliDigits.toEnglish('৭০০০'), equals('7000'));
    });
  });
}

