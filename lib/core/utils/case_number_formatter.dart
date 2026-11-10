import 'bengali_digits.dart';

/// নামজারি / মিসকেস নম্বরের বিশ্লেষিত অংশসমূহ।
///
/// আদর্শ ফরম্যাট: `[ক্রমিক]/[রেজিস্টার কোড]/[অর্থবছর]`
/// উদাহরণ: `৭০৯১/IX-I/২০২৫-২০২৬`
class CaseNumberParts {
  final int serial;
  final String registerCode;
  final int fiscalStartYear;

  const CaseNumberParts({
    required this.serial,
    required this.registerCode,
    required this.fiscalStartYear,
  });

  int get fiscalEndYear => fiscalStartYear + 1;

  /// বাংলা অঙ্কে আদর্শ কেস নম্বর (যেমন: `৭০৯১/IX-I/২০২৫-২০২৬`)।
  String get formatted =>
      '${BengaliDigits.toBengali(serial)}/$registerCode/${BengaliDigits.toBengali('$fiscalStartYear-$fiscalEndYear')}';

  /// ইংরেজি অঙ্কে কেস নম্বর (যেমন: `7091/IX-I/2025-2026`)।
  String get formattedEnglish =>
      '$serial/$registerCode/$fiscalStartYear-$fiscalEndYear';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseNumberParts &&
          serial == other.serial &&
          registerCode == other.registerCode &&
          fiscalStartYear == other.fiscalStartYear;

  @override
  int get hashCode => Object.hash(serial, registerCode, fiscalStartYear);
}

/// বাংলাদেশের নামজারি ও ভূমি অফিসের কেস নম্বর ফরম্যাটিং ও যাচাইয়ের ইউটিলিটি।
///
/// সরকারি বিধি অনুযায়ী ফরম্যাট: `[আবেদন বা কেস ক্রমিক]/[রেজিস্টার কোড]/[অর্থবছর]`
/// - **ক্রমিক নম্বর**: প্রতি অর্থবছরে (১ জুলাই) `১` থেকে শুরু হয়।
/// - **রেজিস্টার কোড**: নামজারি ও জমা-খারিজ নথির জন্য স্থায়ী কোড `IX-I`।
/// - **অর্থবছর**: বাংলাদেশের সরকারি আর্থিক বর্ষপঞ্জি (১ জুলাই – ৩০ জুন),
///   যেমন: `২০১৪-২০১৫`, `২০২৫-২০২৬`।
class CaseNumberFormatter {
  const CaseNumberFormatter._();

  static const String defaultRegisterCode = 'IX-I';

  static const String invalidFormatMessage =
      'সঠিক ফরম্যাটে দিন: ক্রমিক/IX-I/অর্থবছর (যেমন: ৭০৯১/IX-I/২০২৫-২০২৬)';

  static final RegExp _prefixPattern = RegExp(
    r'^(?:কেস\s*নম্বর|কেস\s*নং|কেস|মামলা\s*নম্বর|মামলা\s*নং|মামলা|case\s*number|case\s*no\.?)\s*[:.\-]?\s*',
    caseSensitive: false,
  );

  static final RegExp _registerPattern = RegExp(
    r'^[A-Za-z\u0980-\u09FF]+(?:-[A-Za-z0-9\u0980-\u09FF]+)*$',
  );

  /// প্রদত্ত তারিখের বাংলাদেশের সরকারি অর্থবছর (১ জুলাই – ৩০ জুন) ফেরত দেয়।
  ///
  /// উদাহরণ:
  /// - ৩০ জুন ২০১৫ -> `২০১৪-২০১৫`
  /// - ১ জুলাই ২০১৫ -> `২০১৫-২০১৬`
  /// - ১ জুলাই ২০২৫ – ৩০ জুন ২০২৬ -> `২০২৫-২০২৬`
  static String fiscalYearForDate(DateTime date, {bool bengaliDigits = true}) {
    final startYear = fiscalStartYearForDate(date);
    final raw = '$startYear-${startYear + 1}';
    return bengaliDigits ? BengaliDigits.toBengali(raw) : raw;
  }

  /// প্রদত্ত তারিখের অর্থবছরের শুরুর সাল ফেরত দেয়।
  static int fiscalStartYearForDate(DateTime date) {
    return date.month >= 7 ? date.year : date.year - 1;
  }

  /// ইনপুট থেকে অতিরিক্ত প্রিফিক্স (যেমন `কেস নং: `) বাদ দেয়।
  static String stripPrefix(String raw) {
    return raw.trim().replaceFirst(_prefixPattern, '').trim();
  }

  static int? _parseFiscalStartYear(String rawFiscal) {
    final normalized = BengaliDigits.toEnglish(rawFiscal)
        .replaceAll(RegExp(r'[–—−]'), '-')
        .replaceAll(RegExp(r'\s*-\s*'), '-')
        .trim();

    final fullMatch = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(normalized);
    if (fullMatch != null) {
      final start = int.parse(fullMatch.group(1)!);
      final end = int.parse(fullMatch.group(2)!);
      if (start >= 1971 && start <= 2099 && end == start + 1) {
        return start;
      }
      return null;
    }

    final shortMatch = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(normalized);
    if (shortMatch != null) {
      final start = int.parse(shortMatch.group(1)!);
      final endTwo = int.parse(shortMatch.group(2)!);
      if (start >= 1971 && start <= 2099 && endTwo == (start + 1) % 100) {
        return start;
      }
      return null;
    }

    return null;
  }

  static String? _normalizeRegisterCode(String rawReg) {
    final collapsed = rawReg
        .trim()
        .replaceAll(RegExp(r'\s*-\s*'), '-')
        .replaceAll(RegExp(r'\s+'), '-');
    if (collapsed.isEmpty) return null;

    final upper = collapsed.toUpperCase();
    // ব্যবহারকারীরা অনেক সময় রোমান `I`-এর বদলে `1` লিখে ফেলেন
    if (upper == 'IX-1' || upper == 'IX-I') {
      return defaultRegisterCode;
    }

    if (!_registerPattern.hasMatch(collapsed)) {
      return null;
    }

    // ASCII অক্ষর বড় হাতের রাখি, বাংলা অক্ষর অপরিবর্তিত থাকে
    return collapsed.replaceAllMapped(
      RegExp(r'[a-z]+'),
      (m) => m.group(0)!.toUpperCase(),
    );
  }

  /// কাঁচা কেস নম্বর টেক্সট বিশ্লেষণ করে [CaseNumberParts] ফেরত দেয়।
  ///
  /// সমর্থিত রূপ:
  /// 1. ৩-অংশ: `৭০৯১/IX-I/২০২৫-২০২৬`, `7091/ix-i/2025-26`
  /// 2. ২-অংশ: `7091/2025-2026` (স্বয়ংক্রিয়ভাবে `IX-I` বসে)
  /// 3. ১-অংশ (কেবল [referenceDate] দেওয়া থাকলে): `7091` -> `৭০৯১/IX-I/<অর্থবছর>`
  static CaseNumberParts? tryParse(
    String? raw, {
    DateTime? referenceDate,
    String registerCode = defaultRegisterCode,
  }) {
    if (raw == null) return null;
    final cleaned = stripPrefix(raw).replaceAll('\\', '/');
    if (cleaned.isEmpty) return null;

    final parts = cleaned
        .split('/')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length == 3) {
      final serialEn = BengaliDigits.toEnglish(parts[0]);
      if (!RegExp(r'^\d+$').hasMatch(serialEn)) return null;
      final serial = int.tryParse(serialEn);
      if (serial == null || serial <= 0) return null;

      final reg = _normalizeRegisterCode(parts[1]);
      if (reg == null) return null;

      final fiscalStart = _parseFiscalStartYear(parts[2]);
      if (fiscalStart == null) return null;

      return CaseNumberParts(
        serial: serial,
        registerCode: reg,
        fiscalStartYear: fiscalStart,
      );
    }

    if (parts.length == 2) {
      final serialEn = BengaliDigits.toEnglish(parts[0]);
      if (!RegExp(r'^\d+$').hasMatch(serialEn)) return null;
      final serial = int.tryParse(serialEn);
      if (serial == null || serial <= 0) return null;

      final fiscalStart = _parseFiscalStartYear(parts[1]);
      if (fiscalStart == null) return null;

      final reg = _normalizeRegisterCode(registerCode) ?? defaultRegisterCode;
      return CaseNumberParts(
        serial: serial,
        registerCode: reg,
        fiscalStartYear: fiscalStart,
      );
    }

    if (parts.length == 1 && referenceDate != null) {
      final serialEn = BengaliDigits.toEnglish(parts[0]);
      if (!RegExp(r'^\d+$').hasMatch(serialEn)) return null;
      final serial = int.tryParse(serialEn);
      if (serial == null || serial <= 0) return null;

      final reg = _normalizeRegisterCode(registerCode) ?? defaultRegisterCode;
      return CaseNumberParts(
        serial: serial,
        registerCode: reg,
        fiscalStartYear: fiscalStartYearForDate(referenceDate),
      );
    }

    return null;
  }

  /// ইনপুটটি পূর্ণ ৩-অংশের (`ক্রমিক/রেজিস্টার/অর্থবছর`) আদর্শ কাঠামোয় আছে কি না।
  static bool isCanonicalStructure(String? raw) {
    if (raw == null) return false;
    final cleaned = stripPrefix(raw).replaceAll('\\', '/');
    final parts = cleaned.split('/');
    if (parts.length != 3) return false;
    return tryParse(cleaned) != null;
  }

  /// কেস নম্বরকে আদর্শ `[ক্রমিক]/[রেজিস্টার]/[অর্থবছর]` রূপে ফরম্যাট করে।
  ///
  /// যদি ইনপুটটি পার্সযোগ্য না হয় (যেমন পুরোনো বা লিগ্যাসি টেক্সট), তবে মূল ট্রিমকৃত
  /// মান অপরিবর্তিত ফেরত দেয়। খালি হলে `null` ফেরত দেয়।
  static String? format(
    String? raw, {
    DateTime? referenceDate,
    String registerCode = defaultRegisterCode,
  }) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parsed = tryParse(
      trimmed,
      referenceDate: referenceDate,
      registerCode: registerCode,
    );
    if (parsed != null) {
      return parsed.formatted;
    }

    return trimmed;
  }

  /// কেবলমাত্র ২ বা ৩ অংশের কাঠামোবদ্ধ কেস নম্বর হলেই আদর্শায়ন করে;
  /// ১-অংশের কেবল সংখ্যা বা অসংগঠিত লিগ্যাসি স্ট্রিং অপরিবর্তিত রাখে।
  static String? normalizeIfStructured(String? raw) {
    return format(raw);
  }

  /// UI বা PDF-এ প্রদর্শনের জন্য পরিচ্ছন্ন রূপ ফেরত দেয়।
  static String formatDisplay(String? raw) {
    if (raw == null) return '';
    final stripped = stripPrefix(raw);
    if (stripped.isEmpty) return '';
    final parsed = tryParse(stripped);
    return parsed?.formatted ?? stripped;
  }

  /// ফর্ম ফিল্ড ভ্যালিডেটর (ঐচ্ছিক ফিল্ড — খালি হলে বৈধ)।
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (tryParse(value) != null) return null;
    return invalidFormatMessage;
  }

  /// দুটি কেস নম্বরকে অর্থবছর ও ক্রমিক অনুযায়ী সংখ্যাগতভাবে তুলনা করে (সর্টিংয়ের জন্য)।
  static int compareCaseNumbers(String? a, String? b) {
    final cleanA = a?.trim() ?? '';
    final cleanB = b?.trim() ?? '';
    if (cleanA.isEmpty && cleanB.isEmpty) return 0;
    if (cleanA.isEmpty) return 1;
    if (cleanB.isEmpty) return -1;

    final parsedA = tryParse(cleanA);
    final parsedB = tryParse(cleanB);

    if (parsedA != null && parsedB != null) {
      final yearCmp = parsedA.fiscalStartYear.compareTo(parsedB.fiscalStartYear);
      if (yearCmp != 0) return yearCmp;
      final serialCmp = parsedA.serial.compareTo(parsedB.serial);
      if (serialCmp != 0) return serialCmp;
      return parsedA.registerCode.compareTo(parsedB.registerCode);
    }

    if (parsedA != null) return -1;
    if (parsedB != null) return 1;

    return BengaliDigits.toEnglish(cleanA)
        .compareTo(BengaliDigits.toEnglish(cleanB));
  }
}

