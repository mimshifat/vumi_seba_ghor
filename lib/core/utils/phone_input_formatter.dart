import 'package:flutter/services.dart';

import 'bengali_digits.dart';

/// বাংলাদেশি মোবাইল নম্বরের জন্য ১১ ডিজিট ইনপুট ফরম্যাটার।
///
/// - কেবল ইংরেজি (`0-9`) ও বাংলা (`০-৯`) অঙ্ক গ্রহণ করে।
/// - `+880` / `880` / `00880` প্রিফিক্স বা স্পেস/হাইফেনসহ নম্বর পেস্ট করলে
///   স্বয়ংক্রিয়ভাবে ১১ ডিজিটের `01...` ফরম্যাটে রূপান্তর করে।
/// - ১১ ডিজিটের বেশি টাইপ বা পেস্ট করা যায় না।
class BdPhoneInputFormatter extends TextInputFormatter {
  static const int maxDigits = 11;

  static final RegExp _digitRegex = RegExp(r'[0-9০-৯]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = _extractDigits(oldValue.text);
    final rawNewDigits = _extractDigits(newValue.text);

    // ১১ ডিজিট পূর্ণ থাকার পর নতুন কোনো অঙ্ক টাইপ করলে পুরোনো মানই রাখি
    if (oldDigits.length >= maxDigits &&
        rawNewDigits.length > oldDigits.length &&
        newValue.text.length - oldValue.text.length == 1) {
      return oldValue;
    }

    var formatted = rawNewDigits;
    var strippedPrefixCount = 0;

    // পেস্ট করার সময় +880 / 880 / 00880 প্রিফিক্স থাকলে তা সরিয়ে ১১ ডিজিট করি
    if (formatted.length > maxDigits) {
      final eng = BengaliDigits.toEnglish(formatted);
      if (eng.startsWith('008801') && formatted.length >= 15) {
        formatted = formatted.substring(4);
        strippedPrefixCount = 4;
      } else if (eng.startsWith('8801') && formatted.length >= 13) {
        formatted = formatted.substring(2);
        strippedPrefixCount = 2;
      }
    }

    if (formatted.length > maxDigits) {
      formatted = formatted.substring(0, maxDigits);
    }

    // কার্সর পজিশন নিরাপদভাবে নির্ণয়
    final rawSelectionEnd = newValue.selection.end;
    int targetOffset;
    if (rawSelectionEnd < 0) {
      targetOffset = formatted.length;
    } else {
      final prefixBeforeCursor = newValue.text.substring(
        0,
        rawSelectionEnd.clamp(0, newValue.text.length),
      );
      final digitsBeforeCursor = _extractDigits(prefixBeforeCursor).length;
      targetOffset = (digitsBeforeCursor - strippedPrefixCount)
          .clamp(0, formatted.length);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: targetOffset),
    );
  }

  static String _extractDigits(String input) {
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (_digitRegex.hasMatch(ch)) {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }
}

