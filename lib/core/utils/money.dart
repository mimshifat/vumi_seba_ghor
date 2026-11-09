import 'package:intl/intl.dart';
import 'bengali_digits.dart';

class Money implements Comparable<Money> {
  /// Internal storage in Paisa (1 Taka = 100 Paisa)
  /// Guaranteed integer safety - no float rounding errors
  final int paisa;

  const Money._(this.paisa);

  static const Money zero = Money._(0);

  factory Money.fromPaisa(int paisa) => Money._(paisa);

  /// টাকার পরিমাণ থেকে [Money] তৈরি করে (১ টাকা = ১০০ পয়সা)।
  ///
  /// পূর্ণসংখ্যা মানের জন্য সম্পূর্ণ পূর্ণসংখ্যা গণনা করা হয় — কোনো
  /// ভাসমান মাধ্যমিক ফল থাকে না (BACKEND_MASTER_PLAN.md)।
  factory Money.fromTaka(num taka) {
    if (taka is int) return Money._(taka * 100);
    return Money._((taka * 100).round());
  }

  /// টাকার পরিমাণ লিখিত অবস্থা থেকে পড়ার চেষ্টা করে।
  ///
  /// পার্স করা না গেলে [Money.zero] ফেরত দেয়।
  ///
  /// ⚠️ আর্থিক গণনার জন্য এই পদ্ধতি ব্যবহার করা উচিত নয় — এটি অবৈধ
  /// লেখাকে চুপচাপ শূন্যে পরিণত করে। কঠোর আচরণের জন্য
  /// [Money.fromJson] ব্যবহার করুন।
  factory Money.parse(String value) {
    try {
      return Money._(_parseExactPaisa(value));
    } on FormatException {
      return Money.zero;
    }
  }

  int get inTaka => paisa ~/ 100;
  double get inTakaDouble => paisa / 100.0;

  bool get isZero => paisa == 0;
  bool get isPositive => paisa > 0;
  bool get isNegative => paisa < 0;

  Money operator +(Money other) => Money._(paisa + other.paisa);
  Money operator -(Money other) => Money._(paisa - other.paisa);

  /// পূর্ণসংখ্যা গুণক দিয়ে টাকার পরিমাণ বাড়ায়।
  ///
  /// শুধু পূর্ণসংখ্যা গুণক গ্রহণ করা হয়, কারণ ভাসমান গুণকে রাউন্ডিং
  /// করলে পয়সার সঠিকতা নষ্ট হয় (BACKEND_MASTER_PLAN.md)।
  Money operator *(int factor) => Money._(paisa * factor);

  bool operator <(Money other) => paisa < other.paisa;
  bool operator <=(Money other) => paisa <= other.paisa;
  bool operator >(Money other) => paisa > other.paisa;
  bool operator >=(Money other) => paisa >= other.paisa;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && other.paisa == paisa);

  @override
  int get hashCode => paisa.hashCode;

  @override
  int compareTo(Money other) => paisa.compareTo(other.paisa);

  /// Returns standard formatted string like "৳৭,০০০" or "৳১২,৫০০"
  String formatBengali({bool includeSymbol = true}) {
    final absTaka = inTaka.abs();
    final formatter = NumberFormat('#,##,###', 'en_US');
    final formattedNumber = formatter.format(absTaka);
    final bnNumber = BengaliDigits.toBengali(formattedNumber);
    final prefix = paisa < 0 ? '-' : '';
    final symbol = includeSymbol ? '৳' : '';
    return '$prefix$symbol$bnNumber';
  }

  String formatEnglish({bool includeSymbol = true}) {
    final absTaka = inTaka.abs();
    final formatter = NumberFormat('#,##,###', 'en_US');
    final formattedNumber = formatter.format(absTaka);
    final prefix = paisa < 0 ? '-' : '';
    final symbol = includeSymbol ? '৳' : '';
    return '$prefix$symbol$formattedNumber';
  }

  @override
  String toString() => formatBengali();

  /// JSON সিরিয়ালাইজেশন — সবসময় পয়সা (integer) হিসেবে সংরক্ষণ করে।
  ///
  /// ভাসমান দশমিক কখনোই সংরক্ষিত হয় না, তাই isolate বা ব্যাকআপের
  /// সীমানায় টাকার পরিমাণ কখনোই পূর্ণসংখ্যা হিসেবে হারায় না।
  int toJson() => paisa;

  /// [toJson] এর বিপরীত — পয়সা (integer) থেকে [Money] তৈরি করে।
  ///
  /// কঠোরভাবে: কোনো অবৈধ মান চুপচাপ শূন্যে পরিণত হয় না — বরং
  /// [FormatException] ছুঁড়ে দেওয়া হয়। কারণ আর্থিক হিসাবে শূন্য
  /// ধরে নেওয়া ভুল হিসাব দিয়ে আসে (BACKEND_MASTER_PLAN.md)।
  ///
  /// গ্রহণযোগ্য মান:
  ///  - `int` — পয়সা হিসেবে ব্যাখ্যা করা হয়।
  ///  - `num` — কোনো ভাসমান অংশ না থাকলে পয়সা হিসেবে ব্যাখ্যা করা হয়।
  ///  - `String` — দশমিক টাকার লিখিত রূপ (যেমন `'7000'`, `'12.50'`)।
  ///    শূন্য বা ভাঙা লেখা চূপচাপ শূন্য হিসেবে গণ্য হয় না — বরং বৈধতা
  ///    যাচাই করে ফেলে দেওয়া হয়।
  factory Money.fromJson(Object? json) {
    if (json is int) return Money._(json);
    if (json is num) {
      // ভাসমান অংশ থাকলে এটি পয়সা হিসেবে নির্ভরযোগ্য নয়।
      if (json != json.roundToDouble()) {
        throw FormatException(
          'টাকার পরিমাণে ভাসমান অংশ থাকা যাবে না: $json',
        );
      }
      return Money._(json.toInt());
    }
    if (json is String) return Money._(_parseExactPaisa(json));
    throw FormatException(
      'টাকার পরিমাণ হিসেবে অবৈধ মান: ${json.runtimeType}',
    );
  }

  /// লিখিত দশমিক রূপকে ভাসমান দশমিক ছাড়াই পয়সায় রূপান্তর করে।
  ///
  /// `[parse]` থেকে পার্থক্য: অবৈধ লেখা শূন্যে পরিণত হয় না, বরং
  /// [FormatException] ছুঁড়ে দেয় (BACKEND_MASTER_PLAN.md)। এখানে `double` নেই —
  /// পয়সা সরাসরি গণনা করা হয়, তাই কোনো রাউন্ডিং ত্রুটি নেই।
  static int _parseExactPaisa(String value) {
    final cleaned = BengaliDigits.toEnglish(
      value.replaceAll('৳', '').replaceAll(',', '').trim(),
    );

    if (cleaned.isEmpty) {
      throw const FormatException('টাকার পরিমাণ খালি।');
    }

    final negative = cleaned.startsWith('-');
    final unsigned =
        negative || cleaned.startsWith('+') ? cleaned.substring(1) : cleaned;

    final parts = unsigned.split('.');
    if (parts.length > 2) {
      throw FormatException('টাকার পরিমাণের বিন্যাস সঠিক নয়: $value');
    }

    final taka = int.tryParse(parts.first);
    if (taka == null || taka < 0) {
      throw FormatException('টাকার পরিমাণের বিন্যাস সঠিক নয়: $value');
    }

    var paisa = taka * 100;
    if (parts.length == 2) {
      final fraction = parts[1];
      if (fraction.isEmpty || fraction.length > 2) {
        throw FormatException('টাকার পরিমাণের বিন্যাস সঠিক নয়: $value');
      }
      final fractionValue = int.tryParse(fraction);
      if (fractionValue == null) {
        throw FormatException('টাকার পরিমাণের বিন্যাস সঠিক নয়: $value');
      }
      paisa += fractionValue * (fraction.length == 1 ? 10 : 1);
    }

    return negative ? -paisa : paisa;
  }
}

