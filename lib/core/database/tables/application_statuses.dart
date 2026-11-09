/// আবেদনের বৈধ অবস্থা (status) — ডেটাবেজ সীমাবদ্ধতা ও UI-এর একক উৎস।
class ApplicationStatuses {
  const ApplicationStatuses._();

  /// স্বাভাবিক পর্যায়ক্রমিক অগ্রগতি (Happy Flow)।
  static const List<String> progress = [
    'আবেদন',
    'প্রস্তাব প্রেরণ',
    'শুনানি',
    'মঞ্জুর',
    'ডিসিআর প্রস্তুত',
    'সম্পন্ন',
  ];

  /// ব্যতিক্রমী বা বিশেষ অবস্থা।
  static const List<String> exception = [
    'অপেক্ষমাণ',
    'আপত্তি',
    'সংশোধন প্রয়োজন',
    'নামঞ্জুর',
  ];

  /// সব বৈধ অবস্থা।
  static const List<String> all = [...progress, ...exception];

  /// SQLite CHECK সীমাবদ্ধতার জন্য SQL তালিকা।
  ///
  /// একটি মাত্র উদ্ধৃতি ('...') থাকলে SQLite-এর কোনো সীমাবদ্ধতার মধ্যে
  /// দুটি অবস্থার মধ্যে অ্যাম্বিগুয়িটি তৈরি হয়, তাই এখানে উদ্ধৃতি নেই।
  static String get sqlList => all.map((s) => "'$s'").join(', ');
}
