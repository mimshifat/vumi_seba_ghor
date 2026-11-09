import 'dart:io';
import 'package:sqlite3/common.dart';

/// অ্যাপের কেন্দ্রীয় এরর ও এক্সেপশন র‍্যাপার।
///
/// ব্যবহারকারী একজন সাধারণ ভূমি সেবা পেশাদার, তাই কোনো টেকনিক্যাল
/// কোড বা এরর স্ট্যাকট্রেস কখনো স্ক্রিনে দেখানো হয় না।
/// সকল বার্তা সম্মানজনক, সহজ এবং স্বাভাবিক বাংলায় উপস্থাপিত।
/// (BACKEND_MASTER_PLAN.md §2.1)
class AppFailure implements Exception {
  /// ব্যবহারকারী-বান্ধব প্রাকৃতিক বাংলা বার্তা।
  final String message;

  /// ঐচ্ছিক মেশিন-কোড (যেমন: duplicateAppNumber, invalidAmount ইত্যাদি)।
  final String? code;

  /// মূল কারণ / এক্সেপশন (অভ্যন্তরীণ লগিং বা ডিবাগিংয়ের জন্য)।
  final Object? cause;

  /// স্ট্যাকট্রেস (অভ্যন্তরীণ লগিংয়ের জন্য)।
  final StackTrace? stackTrace;

  const AppFailure({
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  // --- পূর্বনির্ধারিত সাধারণ বাংলা বার্তা কারখানা (Factories) ---

  /// ডুপ্লিকেট আবেদন নম্বর
  factory AppFailure.duplicateAppNumber([String? customMessage]) => AppFailure(
        message: customMessage ??
            'এই আবেদন নম্বরটি ইতিমধ্যে এই অফিসে সংরক্ষিত আছে। অনুগ্রহ করে নম্বরটি পরীক্ষা করুন।',
        code: 'duplicateAppNumber',
      );

  /// অবৈধ বা ত্রুটিপূর্ণ টাকার অংক
  factory AppFailure.invalidAmount([String? customMessage]) => AppFailure(
        message: customMessage ??
            'টাকার অংকটি সঠিক নয়। অনুগ্রহ করে শুধুমাত্র সংখ্যা লিখুন (যেমন: ৫০০০)।',
        code: 'invalidAmount',
      );

  /// মোবাইল নম্বর ত্রুটি
  factory AppFailure.invalidPhone([String? customMessage]) => AppFailure(
        message: customMessage ??
            'মোবাইল নম্বরটি সঠিক নয়। অনুগ্রহ করে ১১ ডিজিটের সঠিক মোবাইল নম্বর দিন (যেমন: ০১৮১৯...)।',
        code: 'invalidPhone',
      );

  /// আবশ্যক ফিল্ড খালি
  factory AppFailure.requiredField(String fieldName) => AppFailure(
        message: '$fieldName আবশ্যক',
        code: 'requiredField',
      );

  /// বকেয়ার চেয়ে অতিরিক্ত আদায় সতর্কতা
  factory AppFailure.overpaymentWarning([String? customMessage]) => AppFailure(
        message: customMessage ??
            'গ্রাহকের বকেয়ার চেয়ে জমার পরিমাণ বেশি হয়ে যাচ্ছে। আপনি কি নিশ্চিত এই টাকা জমা নিতে চান?',
        code: 'overpaymentWarning',
      );

  /// মেমোরি পূর্ণ (Disk full)
  factory AppFailure.diskFull([Object? cause]) => AppFailure(
        message:
            'আপনার ফোনের মেমোরি পূর্ণ হয়ে গেছে। অনুগ্রহ করে কিছু অপ্রয়োজনীয় ফাইল মুছে পুনরায় চেষ্টা করুন।',
        code: 'diskFull',
        cause: cause,
      );

  /// নষ্ট বা ভুল ব্যাকআপ ফাইল
  factory AppFailure.corruptBackup([Object? cause]) => AppFailure(
        message:
            'বাছাইকৃত ফাইলটি সঠিক ব্যাকআপ ফাইল নয় অথবা ফাইলটি নষ্ট হয়ে গেছে। আপনার বর্তমান কোনো তথ্য পরিবর্তন হয়নি।',
        code: 'corruptBackup',
        cause: cause,
      );

  /// সিস্টেমের ডিফল্ট ক্যাটাগরি মোছা নিষেধ
  factory AppFailure.cannotDeleteDefaultCategory([String? name]) => AppFailure(
        message: name != null
            ? '"$name" সিস্টেমের ডিফল্ট খাত, এটি মুছে ফেলা যাবে না।'
            : 'সিস্টেমের ডিফল্ট খাত মুছে ফেলা যাবে না।',
        code: 'cannotDeleteDefaultCategory',
      );

  /// অপরিবর্তনীয় স্ন্যাপশট লঙ্ঘনের চেষ্টা
  factory AppFailure.immutableSnapshotViolation([String? customMessage]) =>
      AppFailure(
        message: customMessage ??
            'আবেদনের স্থায়ী স্ন্যাপশট তথ্য অপরিবর্তনীয়।',
        code: 'immutableSnapshotViolation',
      );

  /// অপ্রত্যাশিত সিস্টেম বা ডেটাবেজ ত্রুটি
  factory AppFailure.system([Object? cause, StackTrace? stackTrace]) =>
      AppFailure(
        message:
            'একটি অপ্রত্যাশিত সমস্যা হয়েছিল, তবে আপনার পূর্ববর্তী কোনো তথ্য নষ্ট হয়নি। অনুগ্রহ করে আবার চেষ্টা করুন।',
        code: 'systemError',
        cause: cause,
        stackTrace: stackTrace,
      );

  /// কাস্টম বাংলা বার্তা
  factory AppFailure.custom(String message, {String? code, Object? cause}) =>
      AppFailure(
        message: message,
        code: code,
        cause: cause,
      );

  /// যেকোনো এক্সেপশনকে প্রাকৃতিক বাংলা [AppFailure]-এ রূপান্তর করে।
  ///
  /// কোনো টেকনিক্যাল এরর (যেমন: `SqliteException(19)`) কখনো বাইরে ফাঁস হয় না।
  static AppFailure fromException(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }

    if (error is SqliteException) {
      final msg = error.message.toLowerCase();
      final explanation = (error.explanation ?? '').toLowerCase();
      final fullText = '$msg $explanation';

      // ১. অপরিবর্তনীয় ট্রিগার ফেইলিউর (RAISE(ABORT, ...))
      if (fullText.contains('application snapshot columns are immutable')) {
        return AppFailure.immutableSnapshotViolation(
          'আবেদনকারীর নাম, ফোন, ঠিকানা, রেফারেন্স বা অফিসের নাম একবার সংরক্ষণ করার পর পরিবর্তন করা যায় না।',
        );
      }
      if (fullText.contains('payments are immutable')) {
        return AppFailure.custom(
          'পূর্বে সংরক্ষিত পেমেন্ট পরিবর্তন করা যাবে না। ভুল সংশোধনে এন্ট্রি মুছে নতুন করে যোগ করুন।',
          code: 'paymentImmutable',
          cause: error,
        );
      }
      if (fullText.contains('expenses are immutable')) {
        return AppFailure.custom(
          'পূর্বে সংরক্ষিত খরচ পরিবর্তন করা যাবে না। ভুল সংশোধনে এন্ট্রি মুছে নতুন করে যোগ করুন।',
          code: 'expenseImmutable',
          cause: error,
        );
      }

      // ২. ডুপ্লিকেট ইউনিক কী (UNIQUE constraint failed)
      if (error.extendedResultCode == 2067 ||
          fullText.contains('unique constraint failed')) {
        if (fullText.contains('app_number') ||
            fullText.contains('applications.app_number')) {
          return AppFailure.duplicateAppNumber();
        }
        return AppFailure.custom(
          'একই তথ্য ইতিমধ্যে ডেটাবেজে সংরক্ষিত আছে। অনুগ্রহ করে তথ্য পরীক্ষা করুন।',
          code: 'duplicateEntry',
          cause: error,
        );
      }

      // ৩. চেক সীমাবদ্ধতা (CHECK constraint failed)
      if (error.extendedResultCode == 275 ||
          fullText.contains('check constraint failed')) {
        return AppFailure.custom(
          'প্রদত্ত তথ্যের মান গ্রহণযোগ্য নিয়মের সাথে মিলছে না। অনুগ্রহ করে সঠিক তথ্য দিন।',
          code: 'checkConstraintError',
          cause: error,
        );
      }

      // ৪. ফরেন কী ভায়োলেশন
      if (error.extendedResultCode == 787 ||
          fullText.contains('foreign key constraint failed')) {
        return AppFailure.custom(
          'সংশ্লিষ্ট মূল তথ্যের সাথে সংযোগ খুঁজে পাওয়া যায়নি।',
          code: 'foreignKeyError',
          cause: error,
        );
      }

      // ৫. ডিস্ক ফুল (SQLITE_FULL = 13)
      if (error.resultCode == 13 ||
          error.extendedResultCode == 13 ||
          fullText.contains('full') ||
          fullText.contains('no space')) {
        return AppFailure.diskFull(error);
      }

      // অন্যান্য ডেটাবেজ এরর
      return AppFailure(
        message:
            'ডেটাবেজ সংরক্ষণে একটি সাময়িক সমস্যা হয়েছে। আপনার পূর্ববর্তী তথ্য অক্ষত আছে।',
        code: 'databaseError',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FileSystemException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('no space') || msg.contains('full')) {
        return AppFailure.diskFull(error);
      }
      return AppFailure(
        message: 'ফাইল সংরক্ষণ বা পড়ার সময় সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
        code: 'fileSystemError',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is FormatException) {
      return AppFailure.invalidAmount();
    }

    if (error is ArgumentError) {
      final message = error.message;
      if (message is String && message.isNotEmpty) {
        return AppFailure.custom(message, cause: error);
      }
      return AppFailure.custom(
        'প্রদত্ত তথ্যে ভুল রয়েছে। অনুগ্রহ করে তথ্য যাচাই করুন।',
        code: 'argumentError',
        cause: error,
      );
    }

    return AppFailure.system(error, stackTrace);
  }

  @override
  String toString() => 'AppFailure(message: $message, code: $code)';
}
