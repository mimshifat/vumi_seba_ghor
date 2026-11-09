import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// অ্যাপের প্রধান ডেটাবেজ ইনস্ট্যান্স।
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// টেস্ট ও প্রিভিউয়ের জন্য ইন-মেমোরি ডেটাবেজ প্রদানকারী।
final inMemoryDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'টেস্টে inMemoryDatabaseProvider ব্যবহার করতে '
    'provider override করুন।',
  );
});
