import 'package:bhumi_kajer_hisab/core/utils/phone_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final formatter = BdPhoneInputFormatter();

  TextEditingValue apply(String oldText, String newText, {int? cursor}) {
    final oldVal = TextEditingValue(
      text: oldText,
      selection: TextSelection.collapsed(offset: oldText.length),
    );
    final newVal = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor ?? newText.length),
    );
    return formatter.formatEditUpdate(oldVal, newVal);
  }

  group('BdPhoneInputFormatter', () {
    test('allows up to 11 English digits and blocks 12th typed digit', () {
      final eleven = apply('0171122334', '01711223344');
      expect(eleven.text, '01711223344');

      final blocked = apply('01711223344', '017112233445');
      expect(blocked.text, '01711223344');
    });

    test('supports Bengali digits up to 11 digits and blocks 12th digit', () {
      final elevenBn = apply('০১৭১১২২৩৩৪', '০১৭১১২২৩৩৪৪');
      expect(elevenBn.text, '০১৭১১২২৩৩৪৪');

      final blockedBn = apply('০১৭১১২২৩৩৪৪', '০১৭১১২২৩৩৪৪৫');
      expect(blockedBn.text, '০১৭১১২২৩৩৪৪');
    });

    test('strips non-digit characters like letters, spaces, and dashes', () {
      final res = apply('', '01711-223344abc');
      expect(res.text, '01711223344');
    });

    test('converts pasted +880 / 880 / 00880 numbers into 11-digit BD format', () {
      expect(apply('', '+8801711223344').text, '01711223344');
      expect(apply('', '880 1819-876543').text, '01819876543');
      expect(apply('', '008801912345678').text, '01912345678');
      expect(apply('', '+৮৮০১৭১১২২৩৩৪৪').text, '০১৭১১২২৩৩৪৪');
    });

    test('truncates arbitrary long pasted digits to 11 digits', () {
      expect(apply('', '01711223344556677').text, '01711223344');
    });
  });
}

