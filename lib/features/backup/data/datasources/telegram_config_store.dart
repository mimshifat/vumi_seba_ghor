import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// টেলিগ্রাম বট কনফিগারেশন ও ক্লাউড ব্যাকআপ সেটিংস সংরক্ষণাগার।
///
/// এটি SQLite ডেটাবেজের সম্পূর্ণ বাইরে (App-Private File Storage-এ) কাজ করে।
/// ফলে:
/// ১. ব্যাকআপ `.db` ফাইলের ভেতরে কখনই টেলিগ্রাম বট টোকেন বা চ্যাট আইডি থাকবে না।
/// ২. অন্যের কোনো ব্যাকআপ ফাইল রিস্টোর করলেও বর্তমান ডিভাইসের টোকেন ও সেটিংস সুরক্ষিত থাকবে।
/// ৩. ডেটাবেজ কোনো কারণে ধ্বংস হলেও বটের ক্রেডেনশিয়াল নিরাপদে থাকবে।
class TelegramConfigStore {
  static TelegramConfigStore? _instance;
  static TelegramConfigStore get instance =>
      _instance ??= TelegramConfigStore();

  File? _customFile;
  Map<String, String> _cache = {};
  bool _isLoaded = false;

  final _changeStreamController =
      StreamController<Map<String, String>>.broadcast();

  TelegramConfigStore({File? customFile}) : _customFile = customFile;

  /// টেস্ট বা কাস্টম পথের জন্য স্টোর ইনিশিয়ালাইজ করা
  static TelegramConfigStore createForTesting(File file) {
    return TelegramConfigStore(customFile: file);
  }

  /// ডেডিকেটেড কনফিগ ফাইলের অবস্থান নির্ণয়
  Future<File> _getConfigFile() async {
    if (_customFile != null) return _customFile!;
    try {
      final dir = await getApplicationSupportDirectory();
      return File(p.join(dir.path, 'rojob_telegram_config.json'));
    } catch (_) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        return File(p.join(dir.path, 'rojob_telegram_config.json'));
      } catch (_) {
        return File(p.join(Directory.systemTemp.path, 'rojob_telegram_config.json'));
      }
    }
  }

  /// ডিস্ক থেকে কনফিগারেশন মেমরিতে লোড করা
  Future<void> _ensureLoaded() async {
    if (_isLoaded) return;
    try {
      final file = await _getConfigFile();
      if (file.existsSync()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = json.decode(content);
          if (decoded is Map) {
            _cache = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        }
      }
    } catch (_) {
      _cache = {};
    } finally {
      _isLoaded = true;
    }
  }

  /// ডিস্কে কনফিগারেশন সংরক্ষণ করা
  Future<void> _persist() async {
    try {
      final file = await _getConfigFile();
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      await file.writeAsString(json.encode(_cache), flush: true);
    } catch (_) {}
    _changeStreamController.add(Map.unmodifiable(_cache));
  }

  /// নির্দিষ্ট কি-এর মান পাঠ করা
  Future<String?> getSetting(String key) async {
    await _ensureLoaded();
    return _cache[key];
  }

  /// নির্দিষ্ট কি-এর মান সংরক্ষণ করা
  Future<void> setSetting(String key, String value) async {
    await _ensureLoaded();
    _cache[key] = value;
    await _persist();
  }

  /// একাধিক কি-মান সংরক্ষণ করা
  Future<void> setSettings(Map<String, String> values) async {
    await _ensureLoaded();
    _cache.addAll(values);
    await _persist();
  }

  /// বট টোকেন ও চ্যাট আইডি সংরক্ষণ
  Future<void> saveCredentials({
    required String botToken,
    required String chatId,
  }) async {
    await setSettings({
      'telegram_bot_token': botToken.trim(),
      'telegram_chat_id': chatId.trim(),
    });
  }

  /// স্বয়ংক্রিয় ক্লাউড ব্যাকআপ অন বা অফ করা
  Future<void> setAutoBackup(bool enabled) async {
    await setSetting('auto_backup_telegram', enabled ? 'true' : 'false');
  }

  /// সফল ব্যাকআপের রেকর্ড রাখা
  Future<void> recordBackupSuccess(String todayDate) async {
    await setSettings({
      'last_telegram_auto_backup_date': todayDate,
      'last_telegram_auto_backup_status': 'success',
      'last_telegram_auto_backup_error': '',
    });
  }

  /// ব্যর্থ ব্যাকআপের রেকর্ড রাখা
  Future<void> recordBackupFailure({
    required String errorMessage,
    required String attemptTime,
  }) async {
    await setSettings({
      'last_telegram_auto_backup_status': 'failed',
      'last_telegram_auto_backup_error': errorMessage,
      'last_telegram_auto_backup_attempt_time': attemptTime,
    });
  }

  /// সকল সেটিংস সংগ্রহ করা
  Future<Map<String, String>> getAllSettings() async {
    await _ensureLoaded();
    return Map.unmodifiable(_cache);
  }

  /// সেটিংস রিয়েক্টিভভাবে পর্যবেক্ষণ করা
  Stream<String?> watchSetting(String key) async* {
    await _ensureLoaded();
    yield _cache[key];
    yield* _changeStreamController.stream.map((map) => map[key]);
  }

  /// বুলিয়ান সেটিংস পর্যবেক্ষণ করা
  Stream<bool> watchBoolSetting(String key, {bool defaultValue = false}) {
    return watchSetting(key).map((val) {
      if (val == null) return defaultValue;
      return val.toLowerCase() == 'true';
    });
  }

  /// টেস্টের সুবিধার্থে ক্যাশ খালি করা
  void resetForTest() {
    _cache = {};
    _isLoaded = false;
  }
}

