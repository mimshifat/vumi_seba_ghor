import 'dart:convert';

import '../../../../core/utils/bengali_digits.dart';

/// ভূমি পোর্টাল (`lsg-land-owner.land.gov.bd`) লগইন ও অটো-ফিল সহায়ক।
class LandPortalHelper {
  const LandPortalHelper._();

  /// নাগরিক / ভূমি মালিক পোর্টাল লগইন URL।
  static const String lsgLoginUrl = 'https://lsg-land-owner.land.gov.bd/login';

  /// পোর্টালের মোবাইল ইনপুট (+880 পাশে থাকায়) ১০ ডিজিটের ইংরেজি নম্বর চায় (যেমন: 1711223344)।
  ///
  /// বাংলা বা ইংরেজি, `+880` বা `0` যুক্ত যেকোনো নম্বরকে ১০-ডিজিট পোর্টাল ফরম্যাটে রূপান্তর করে।
  /// ইমেইল বা নন-ফোন ইনপুট হলে তা অপরিবর্তিত রাখে।
  static String toTenDigitPortalMobile(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('@')) return trimmed;

    final english = BengaliDigits.toEnglish(trimmed);
    var digits = english.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('00880') && digits.length >= 15) {
      digits = digits.substring(5);
    } else if (digits.startsWith('880') && digits.length >= 13) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Content-Disposition হেডার থেকে ফাইলের নাম বের করে।
  static String? extractFileNameFromContentDisposition(String? header) {
    if (header == null || header.trim().isEmpty) return null;
    final utf8Match = RegExp(
      r"filename\*\s*=\s*(?:UTF-8''|utf-8'')([^;\r\n]+)",
    ).firstMatch(header);
    if (utf8Match != null) {
      final raw = utf8Match.group(1)?.trim();
      if (raw != null && raw.isNotEmpty) {
        try {
          return Uri.decodeFull(raw.replaceAll('"', ''));
        } catch (_) {
          return raw.replaceAll('"', '');
        }
      }
    }

    final plainMatch = RegExp(
      r'filename\s*=\s*"?([^";\r\n]+)"?',
      caseSensitive: false,
    ).firstMatch(header);
    final plain = plainMatch?.group(1)?.trim();
    return (plain != null && plain.isNotEmpty) ? plain : null;
  }

  /// ডাউনলোড ফাইলের নামের অবৈধ অক্ষর পরিষ্কার করে নিরাপদ ফাইলনেম দেয়।
  static String sanitizeFileName(
    String raw, {
    String fallbackExtension = 'pdf',
  }) {
    var cleaned = raw.trim().replaceAll(RegExp(r'[\\/:*?"<>|\r\n]+'), '_');
    cleaned = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') {
      return 'bhumi_portal_${DateTime.now().millisecondsSinceEpoch}.$fallbackExtension';
    }
    if (!cleaned.contains('.')) {
      cleaned = '$cleaned.$fallbackExtension';
    }
    return cleaned;
  }

  /// WebView-এ সরাসরি লোড করার অনুমোদিত স্কিম কি না।
  static bool isInternalWebScheme(String scheme) {
    final s = scheme.toLowerCase();
    return s == 'http' ||
        s == 'https' ||
        s == 'about' ||
        s == 'blob' ||
        s == 'data';
  }

  /// `intent://...` URL থেকে `S.browser_fallback_url` বের করে (যদি থাকে)।
  static String? extractIntentFallbackUrl(String rawUrl) {
    if (!rawUrl.toLowerCase().startsWith('intent://')) return null;
    final match = RegExp(
      r'S\.browser_fallback_url=([^;]+)',
      caseSensitive: false,
    ).firstMatch(rawUrl);
    final encoded = match?.group(1)?.trim();
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = Uri.decodeComponent(encoded);
      final parsed = Uri.tryParse(decoded);
      if (parsed != null &&
          (parsed.scheme == 'http' || parsed.scheme == 'https')) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// লগইন পেজে মোবাইল নম্বর (বা ইমেইল) ও পাসওয়ার্ড অটো-ফিল করার নিরাপদ JavaScript তৈরি করে।
  ///
  /// কেবল `#mobile` (বা `input[name="username"]` / `input[type="email"]`) এবং
  /// `#see-password` (বা `input[name="password"]`) ফিল্ড পূরণ করে।
  /// ক্যাপচা (`#mainCaptcha` / `#txtInput`) স্পর্শ করে না।
  ///
  /// [onlyIfEmpty] `true` হলে আগে থেকে ইউজার কিছু টাইপ করে থাকলে ওভাররাইট করে না।
  static String buildLsgAutofillScript({
    required String mobile,
    required String password,
    bool onlyIfEmpty = false,
  }) {
    final tenDigitMobile = toTenDigitPortalMobile(mobile);
    final isEmail = tenDigitMobile.contains('@');
    final mobileJson = jsonEncode(tenDigitMobile);
    final passwordJson = jsonEncode(password);

    return '''
(function() {
  try {
    var mobileVal = $mobileJson;
    var passVal = $passwordJson;
    var onlyIfEmpty = ${onlyIfEmpty ? 'true' : 'false'};
    var isEmail = ${isEmail ? 'true' : 'false'};

    if (!isEmail) {
      var mobileRadio = document.getElementById('identity');
      if (mobileRadio && mobileRadio.type === 'radio' && !mobileRadio.checked) {
        mobileRadio.click();
      }
    }

    function setNativeValue(el, val) {
      if (!el) return false;
      if (onlyIfEmpty && el.value && el.value.trim().length > 0) {
        return false;
      }
      var proto = window.HTMLInputElement.prototype;
      var descriptor = Object.getOwnPropertyDescriptor(proto, 'value');
      if (descriptor && descriptor.set) {
        descriptor.set.call(el, val);
      } else {
        el.value = val;
      }
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
      el.dispatchEvent(new Event('blur', { bubbles: true }));
      return true;
    }

    var mobileInput = isEmail
      ? (document.querySelector('input[type="email"], input[name="email"], input[name="username"]:not([type="number"])') ||
         document.getElementById('email'))
      : (document.getElementById('mobile') ||
         document.querySelector('input[name="username"][type="number"], input[name="username"][type="tel"], input[name="username"]'));
    var passInput = document.getElementById('see-password') ||
      document.querySelector('input[name="password"], input[type="password"]');

    var mobileFilled = false;
    var passwordFilled = false;

    if (mobileInput && mobileVal) {
      mobileFilled = setNativeValue(mobileInput, mobileVal);
    }
    if (passInput && passVal) {
      passwordFilled = setNativeValue(passInput, passVal);
    }

    return JSON.stringify({
      mobileFilled: mobileFilled,
      passwordFilled: passwordFilled,
      foundInputs: Boolean(mobileInput || passInput)
    });
  } catch (e) {
    return JSON.stringify({
      mobileFilled: false,
      passwordFilled: false,
      foundInputs: false,
      error: String(e)
    });
  }
})();
''';
  }
}
