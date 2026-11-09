import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_colors.dart';

void main() {
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

  runApp(
    ProviderScope(
      child: _AppRoot(key: _rootKey),
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
              onPressed: () => _rootKey.currentState?.rebuildApp(),
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

/// রেন্ডারিং ত্রুটির পর অ্যাপের উইজেট ট্রি পুনরায় তৈরি করার জন্য রুট উইজেট।
class _AppRoot extends StatefulWidget {
  const _AppRoot({super.key});

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  int _buildGeneration = 0;

  /// পুরো উইজেট ট্রি পুনরায় তৈরি করে।
  void rebuildApp() {
    setState(() => _buildGeneration++);
  }

  @override
  Widget build(BuildContext context) {
    // প্রতিবার নতুন কী ব্যবহার করলে পুরো সাবট্রি নতুন করে তৈরি হয়,
    // ফলে আগের রেন্ডার ত্রুটির অবস্থা পরিষ্কার হয়ে যায়।
    return KeyedSubtree(
      key: ValueKey(_buildGeneration),
      child: const BhumiKajerHisabApp(),
    );
  }
}

/// `_AppRoot`-এর গ্লোবাল কী — ত্রুটি থেকে ফিরে আসার জন্য।
final GlobalKey<_AppRootState> _rootKey = GlobalKey<_AppRootState>();
