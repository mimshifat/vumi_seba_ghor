import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_colors.dart';
import 'core/database/app_database.dart';
import 'core/database/database_provider.dart';
import 'core/database/database_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // গ্লোবাল ক্র্যাশ শিল্ড — কোনো অপ্রত্যাশিত ত্রুটি অ্যাপ বন্ধ করবে না।
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logCrash('FlutterError', details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _logCrash('PlatformDispatcher', error, stack);
    return true; // অ্যাপ চলমান থাকে।
  };

  // রেন্ডারিং ত্রুটি হলে মৃত্যুর পর্দা না দেখিয়ে পুনরায় চেষ্টার কার্ড দেখানো।
  ErrorWidget.builder = buildErrorRecoveryWidget;

  // রিস্টোর ব্যর্থতাজনিত কোনো ক্র্যাশ থাকলে স্বয়ংক্রিয় প্রাক-রিস্টোর ব্যাকআপ পুনরুদ্ধার
  await AppDatabase.checkAndRecoverPreRestoreSnapshot();

  // ডেটাবেজ সংযোগ ও আবশ্যকীয় সিস্টেম সেটিংস নিশ্চিতকরণ (কোনো ডেমো আবেদন ছাড়া)
  final db = AppDatabase.open();
  try {
    await DatabaseSeeder.seedEssentialDefaults(db);
  } catch (e, s) {
    _logCrash('DatabaseSeeder', e, s);
  }

  runApp(
    AppRoot(
      key: rootAppKey,
      initialDb: db,
    ),
  );
}

/// ক্র্যাশের বিবরণ ডিভাইস কনসোলে লিখে রাখে।
void _logCrash(String source, Object error, StackTrace? stack) {
  debugPrint('[$source] $error');
  if (stack != null) debugPrintStack(stackTrace: stack, maxFrames: 20);
}

/// রেন্ডারিং ত্রুটি হলে ব্যবহারকারীকে মৃত্যুর পর্দা না দেখিয়ে পুনরায়
/// চেষ্টার কার্ড দেখানোর জন্য বিকল্প উইজেট।
Widget buildErrorRecoveryWidget(FlutterErrorDetails details) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.rose),
            const SizedBox(height: 16),
            const Text(
              'কিছু একটা সমস্যা হয়েছে',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'স্ক্রিনটি পুনরায় তৈরি করার চেষ্টা করুন। আপনার কোনো তথ্য হারায়নি।',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => rootAppKey.currentState?.rebuildApp(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('পুনরায় চেষ্টা করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// `AppRoot`-এর গ্লোবাল কী — ত্রুটি থেকে ফিরে আসার ও ডেটাবেজ সোয়াপ করার জন্য।
final GlobalKey<AppRootState> rootAppKey = GlobalKey<AppRootState>();

/// রেন্ডারিং ত্রুটির পর অ্যাপের উইজেট ট্রি পুনরায় তৈরি করার জন্য রুট উইজেট।
class AppRoot extends StatefulWidget {
  final AppDatabase initialDb;
  const AppRoot({super.key, required this.initialDb});

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  late AppDatabase _currentDb;
  Key _scopeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentDb = widget.initialDb;
  }

  /// ডেটাবেজ রিস্টোর সম্পন্ন হলে নতুন সংযোগ দিয়ে সমগ্র উইজেট ও প্রোভাইডার ট্রি রিলোড করে।
  void replaceDatabase(AppDatabase newDb) {
    setState(() {
      _currentDb = newDb;
      _scopeKey = UniqueKey();
    });
  }

  /// পুরো উইজেট ট্রি পুনরায় তৈরি করে।
  void rebuildApp() {
    setState(() => _scopeKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _scopeKey,
      overrides: [
        appDatabaseProvider.overrideWithValue(_currentDb),
      ],
      child: const BhumiKajerHisabApp(),
    );
  }
}
