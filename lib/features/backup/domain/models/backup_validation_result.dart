/// ব্যাকআপ ফাইল যাচাইকরণের ফলাফল মডেল (Backup Validation Result)।
///
/// ব্যাকগ্রাউন্ড আইসোলেটে [sqlite3] দিয়ে ব্যাকআপ ফাইলের কাঠামোগত
/// অখণ্ডতা ও রেকর্ড পরিসংখ্যান পরীক্ষা করে এটি তৈরি হয়।
class BackupValidationResult {
  /// ফাইলটি একটি বৈধ ও অক্ষত ব্যাকআপ কিনা
  final bool isValid;

  /// অবৈধ হলে মানবিক বাংলা কারণ
  final String? errorMessage;

  /// ফাইলের আকার (বাইটে)
  final int fileSizeBytes;

  /// মোট সক্রিয় ও সফট-ডিলিটকৃত আবেদন সংখ্যা
  final int totalApplications;

  /// মোট পেমেন্ট সংখ্যা
  final int totalPayments;

  /// মোট খরচ সংখ্যা
  final int totalExpenses;

  /// মোট নিবন্ধিত গ্রাহক সংখ্যা
  final int totalPersons;

  /// মোট রেফারেন্স ব্যক্তি সংখ্যা
  final int totalReferences;

  /// ডেটাবেজ স্কিমা সংস্করণ
  final int schemaVersion;

  /// এটি একটি হালকা ক্লাউড ব্যাকআপ কিনা (ভারী দলিল/ছবির বাইনারি ব্লব বাদ দেওয়া)
  final bool isLightweight;

  /// ব্যাকআপ ফাইলের সর্বশেষ পরিবর্তনের তারিখ
  final DateTime? backupDate;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.fileSizeBytes = 0,
    this.totalApplications = 0,
    this.totalPayments = 0,
    this.totalExpenses = 0,
    this.totalPersons = 0,
    this.totalReferences = 0,
    this.schemaVersion = 1,
    this.isLightweight = false,
    this.backupDate,
  });

  /// ত্রুটিযুক্ত ব্যাকআপ ফাইলের জন্য সহজ ফ্যাক্টরি
  factory BackupValidationResult.invalid(String message) {
    return BackupValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

