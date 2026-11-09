import '../utils/bengali_digits.dart';

/// স্ক্রিন-পর্যায়ের যাচাইকারীর জন্য সম্পূর্ণ কেন্দ্রীভূত ভ্যালিডেটর সেট।
class AppValidators {
  const AppValidators._();

  // --- প্রয়োজনীয় ফিল্ডের বাংলা বার্তা ---
  static const String applicantNameRequired = 'আবেদনকারীর নাম আবশ্যক';
  static const String phoneRequired = 'মোবাইল নম্বর আবশ্যক';
  static const String phoneInvalid = 'সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন';
  static const String officeRequired = 'ভূমি অফিস নির্বাচন আবশ্যক';
  static const String workTypeRequired = 'কাজের ধরন নির্বাচন আবশ্যক';
  static const String agreedAmountRequired = 'চুক্তির সার্ভিস ফি উল্লেখ করুন';
  static const String incomeAmountRequired = 'আয়ের পরিমাণ উল্লেখ করুন';
  static const String expenseAmountRequired = 'খরচের পরিমাণ উল্লেখ করুন';
  static const String expenseCategoryRequired = 'খরচের খাত নির্বাচন করুন';

  /// বাংলা ও ইংরেজি — উভয় অঙ্ক গ্রহণযোগ্য করে ইংরেজি অঙ্কে রূপান্তর করে।
  static String normalizeDigits(String value) => BengaliDigits.toEnglish(value);

  /// বাংলা ও ইংরেজি উভয় অঙ্ক সমর্থন করে ১১ ডিজিটের বাংলাদেশি মোবাইল
  /// নম্বর যাচাই করে।
  ///
  /// স্পেস, ড্যাশ ও ব্র্যাকেটসহ ইনপুট সরিয়ে ফেলা হয় এবং `+৮৮`, `০৮৮` বা
  /// `0088` প্রিফিক্সও গ্রহণ করা হয়।
  static bool isValidPhone(String? value) {
    if (value == null) return false;

    // কেবল অঙ্ক রাখা হয় — বাংলা অঙ্কও ইংরেজিতে রূপান্তর হয়।
    final digits = normalizeDigits(value).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;

    // সম্ভাব্য দেশের কোড সরানোর পর স্থানীয় নম্বরের সব সম্ভাব্য রূপ।
    final withoutCountryCode = <String>[
      digits,
      if (digits.startsWith('0088')) digits.substring(4),
      if (digits.startsWith('880')) digits.substring(3),
      if (digits.startsWith('88')) digits.substring(2),
    ];

    final candidates = <String>{
      for (final candidate in withoutCountryCode) ...[
        candidate,
        // জাতীয় ফোন নম্বরে সাধারণত ০ দিয়ে শুরু হয় — তা সরানো হয়।
        if (candidate.length == 11 && candidate.startsWith('0'))
          candidate.substring(1),
      ],
    };

    return candidates.any(
      (candidate) => RegExp(r'^1[3-9]\d{8}$').hasMatch(candidate),
    );
  }

  /// আবেদনকারীর নাম আবশ্যক।
  static String? validateApplicantName(String? value) {
    if (value == null || value.trim().isEmpty) return applicantNameRequired;
    return null;
  }

  /// মোবাইল নম্বর আবশ্যক / সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন।
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return phoneRequired;
    if (!isValidPhone(value)) return phoneInvalid;
    return null;
  }

  /// ভূমি অফিস নির্বাচন আবশ্যক।
  static String? validateOffice(String? value) {
    if (value == null || value.trim().isEmpty) return officeRequired;
    return null;
  }

  /// কাজের ধরন নির্বাচন আবশ্যক।
  static String? validateWorkType(String? value) {
    if (value == null || value.trim().isEmpty) return workTypeRequired;
    return null;
  }

  /// চুক্তির সার্ভিস ফি উল্লেখ করুন।
  ///
  /// শূন্য বা নেতিবাচক পরিমাণ গ্রহণযোগ্য নয় (ব্যবসা নিয়ম §9.5)।
  static String? validateAgreedAmount(String? value) {
    if (value == null || value.trim().isEmpty) return agreedAmountRequired;
    final paisa = parsePaisa(value);
    if (paisa == null || paisa <= 0) return agreedAmountRequired;
    return null;
  }

  /// আয়ের পরিমাণ উল্লেখ করুন।
  static String? validateIncomeAmount(String? value) {
    if (value == null || value.trim().isEmpty) return incomeAmountRequired;
    final paisa = parsePaisa(value);
    if (paisa == null || paisa <= 0) return incomeAmountRequired;
    return null;
  }

  /// খরচের পরিমাণ উল্লেখ করুন।
  static String? validateExpenseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return expenseAmountRequired;
    final paisa = parsePaisa(value);
    if (paisa == null || paisa <= 0) return expenseAmountRequired;
    return null;
  }

  /// খরচের খাত নির্বাচন করুন।
  static String? validateExpenseCategory(String? value) {
    if (value == null || value.trim().isEmpty) return expenseCategoryRequired;
    return null;
  }

  /// ব্যবহারকারীর ইনপুট থেকে পয়সা (integer) পড়ে।
  ///
  /// দশমিক ভাঙা বা অবৈধ ইনপুটে `null` ফেরত দেয় — কখনোই ভাসমান পয়সা
  /// ফেরত দেয় না।
  static int? parsePaisa(String? value) {
    if (value == null) return null;
    final cleaned = normalizeDigits(value)
        .replaceAll('৳', '')
        .replaceAll(',', '')
        .trim();
    if (cleaned.isEmpty) return null;

    final parts = cleaned.split('.');
    if (parts.length > 2) return null;

    final taka = int.tryParse(parts.first);
    if (taka == null || taka < 0) return null;

    if (parts.length == 1) return taka * 100;

    final fraction = parts[1];
    if (fraction.isEmpty || fraction.length > 2) return null;
    if (int.tryParse(fraction) == null) return null;

    final padded = fraction.padRight(2, '0');
    return taka * 100 + int.parse(padded);
  }
}
