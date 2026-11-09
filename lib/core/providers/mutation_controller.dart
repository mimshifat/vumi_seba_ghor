import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_failure.dart';

/// মিউটেশন ও ফর্ম সাবমিশন সেফটি কন্ট্রোলার (Mutation Safety Controller)।
///
/// এটি নিশ্চিত করে যে:
/// ১. বাটনে দ্রুত পরপর একাধিক চাপ (Double-Tap) দিলে দ্বিতীয় অপারেশন স্বয়ংক্রিয়ভাবে ব্লক হয়।
/// ২. লোডিং, ডেটা ও ত্রুটি অবস্থা `AsyncValue`-এর মাধ্যমে পরিচালিত হয়।
/// ৩. যেকোনো এরর স্বয়ংক্রিয়ভাবে প্রাকৃতিক বাংলা [AppFailure]-এ রূপান্তরিত হয়।
/// (BACKEND_MASTER_PLAN.md §2.3, §3, §5 ফেজ ২)
abstract class MutationController extends StateNotifier<AsyncValue<void>> {
  MutationController([AsyncValue<void>? initial])
      : super(initial ?? const AsyncValue.data(null));

  /// বর্তমানে কোনো অপারেশন চলমান আছে কিনা
  bool get isLoading => state.isLoading;

  /// সেফটি লক সমন্বিত অপারেশন কার্যকরকারী
  Future<T?> execute<T>(Future<T> Function() action) async {
    if (state.isLoading) {
      // ডাবল-ট্যাপ ও রি-এন্ট্রি রোধ: চলমান থাকা অবস্থায় পরবর্তী কল অবিলম্বে অগ্রাহ্য করা হয়
      return null;
    }

    state = const AsyncValue.loading();
    try {
      final result = await action();
      state = const AsyncValue.data(null);
      return result;
    } catch (e, s) {
      final failure = AppFailure.fromException(e, s);
      state = AsyncValue.error(failure, s);
      return null;
    }
  }

  /// স্টেট রিসেট করা
  void reset() {
    state = const AsyncValue.data(null);
  }
}

