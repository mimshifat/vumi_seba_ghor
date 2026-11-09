import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import 'bengali_digits.dart';

/// অ্যাপের সার্বিক ডায়ালার, এসএমএস, ক্লিপবোর্ড ও ইউআরএল লঞ্চার।
///
/// বাংলা বা ইংরেজি যেকোনো ফরম্যাটের নম্বরকে স্বয়ংক্রিয়ভাবে আন্তর্জাতিক
/// ডায়াল ফরম্যাটে রূপান্তর করে ফোনের নেটিভ ডায়াল প্যাড চালু করে।
class AppLauncher {
  const AppLauncher._();

  /// ফোন নম্বর পরিষ্কার করে ইংরেজি ডিজিটে রূপান্তর
  static String cleanPhoneNumber(String raw) {
    // বাংলা ডিজিটকে ইংরেজি ডিজিটে পরিবর্তন
    var cleaned = BengaliDigits.toEnglish(raw.trim());
    // স্পেস, ড্যাশ, প্রথম বন্ধনী মুছে ফেলা, তবে প্লাস চিহ্ন অক্ষত রাখা
    final hasPlus = cleaned.startsWith('+');
    cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (hasPlus) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  /// ফোনের ডায়াল প্যাড ওপেন করে নম্বরটি তুলে দেয়
  static Future<bool> makePhoneCall(
    BuildContext? context,
    String? rawPhone, {
    String? contactName,
  }) async {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      if (context != null && context.mounted) {
        _showSnackBar(context, 'কোনো মোবাইল নম্বর পাওয়া যায়নি।', isError: true);
      }
      return false;
    }

    final cleanPhone = cleanPhoneNumber(rawPhone);
    if (cleanPhone.isEmpty) {
      if (context != null && context.mounted) {
        _showSnackBar(context, 'সঠিক মোবাইল নম্বর পাওয়া যায়নি।', isError: true);
      }
      return false;
    }

    final uri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // যদি ডায়াল প্যাড ওপেন না হয় (যেমন: ট্যাবলেট বা আনসাপোর্টেড ডিভাইস), ক্লিপবোর্ডে কপি করে দেওয়া
        await Clipboard.setData(ClipboardData(text: cleanPhone));
        if (context != null && context.mounted) {
          _showSnackBar(
            context,
            'ডায়াল প্যাড খোলা যায়নি। নম্বরটি কপি করা হয়েছে: ${BengaliDigits.toBengali(cleanPhone)}',
          );
        }
        return false;
      }
      return true;
    } catch (_) {
      // এক্সেপশন ফলব্যাক
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (context != null && context.mounted) {
        _showSnackBar(
          context,
          'ডায়াল প্যাড খোলা যায়নি। নম্বরটি কপি করা হয়েছে: ${BengaliDigits.toBengali(cleanPhone)}',
        );
      }
      return false;
    }
  }

  /// টেক্সট বা নম্বর ক্লিপবোর্ডে কপি করার সুবিধা
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String? successMessage,
  }) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (context.mounted) {
      _showSnackBar(
        context,
        successMessage ?? 'কপি করা হয়েছে: $text',
      );
    }
  }

  /// ওয়েব ইউআরএল বা সোশ্যাল লিংক ওপেন করা
  static Future<bool> launchWeb(BuildContext? context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context != null && context.mounted) {
        _showSnackBar(context, 'লিংকটি খোলা সম্ভব হয়নি।', isError: true);
      }
      return launched;
    } catch (_) {
      if (context != null && context.mounted) {
        _showSnackBar(context, 'লিংকটি সঠিক নয়।', isError: true);
      }
      return false;
    }
  }

  static void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.rose : AppColors.slate900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

