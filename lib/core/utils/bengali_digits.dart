class BengaliDigits {
  BengaliDigits._();

  static const Map<String, String> _enToBn = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  static const Map<String, String> _bnToEn = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  static String toBengali(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      buffer.write(_enToBn[char] ?? char);
    }
    return buffer.toString();
  }

  static String toEnglish(String bengaliStr) {
    final buffer = StringBuffer();
    for (int i = 0; i < bengaliStr.length; i++) {
      final char = bengaliStr[i];
      buffer.write(_bnToEn[char] ?? char);
    }
    return buffer.toString();
  }
}

