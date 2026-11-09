import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/providers/mutation_controller.dart';
import '../../data/datasources/telegram_config_store.dart';
import '../../data/repositories/backup_repository.dart';
import '../../domain/models/backup_validation_result.dart';

export '../../data/datasources/telegram_config_store.dart';
export '../../data/repositories/backup_repository.dart';
export '../../domain/models/backup_validation_result.dart';

/// টেলিগ্রাম অ্যাপ-প্রাইভেট কনফিগ স্টোর প্রোভাইডার
final telegramConfigStoreProvider = Provider<TelegramConfigStore>((ref) {
  return TelegramConfigStore.instance;
});

/// ব্যাকআপ ও রিস্টোর রিপোজিটরি প্রোভাইডার
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final store = ref.watch(telegramConfigStoreProvider);
  return BackupRepository(db, configStore: store);
});

/// সর্বশেষ ব্যাকআপ সময়ের রিয়েক্টিভ ওয়াচ (SQLite shop_settings)
final lastBackupTimeStreamProvider = StreamProvider<String?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.shopSettingsDao.watchSetting('last_backup_time');
});

/// টেলিগ্রাম বট টোকেন ওয়াচ (App-Private File Storage)
final telegramBotTokenStreamProvider = StreamProvider<String?>((ref) {
  final store = ref.watch(telegramConfigStoreProvider);
  return store.watchSetting('telegram_bot_token');
});

/// টেলিগ্রাম চ্যাট আইডি ওয়াচ (App-Private File Storage)
final telegramChatIdStreamProvider = StreamProvider<String?>((ref) {
  final store = ref.watch(telegramConfigStoreProvider);
  return store.watchSetting('telegram_chat_id');
});

/// টেলিগ্রাম অটো-ব্যাকআপ সক্রিয়তা ওয়াচ
final autoBackupTelegramStreamProvider = StreamProvider<bool>((ref) {
  final store = ref.watch(telegramConfigStoreProvider);
  return store.watchBoolSetting('auto_backup_telegram');
});

/// সর্বশেষ স্বয়ংক্রিয় ক্লাউড ব্যাকআপের তারিখ
final lastTelegramAutoBackupDateStreamProvider = StreamProvider<String?>((ref) {
  final store = ref.watch(telegramConfigStoreProvider);
  return store.watchSetting('last_telegram_auto_backup_date');
});

/// সর্বশেষ স্বয়ংক্রিয় ক্লাউড ব্যাকআপের স্ট্যাটাস ('success' বা 'failed')
final lastTelegramAutoBackupStatusStreamProvider = StreamProvider<String?>((ref) {
  final store = ref.watch(telegramConfigStoreProvider);
  return store.watchSetting('last_telegram_auto_backup_status');
});

/// সর্বশেষ স্বয়ংক্রিয় ক্লাউড ব্যাকআপ ব্যর্থতার বিবরণ
final lastTelegramAutoBackupErrorStreamProvider = StreamProvider<String?>((ref) {
  final store = ref.watch(telegramConfigStoreProvider);
  return store.watchSetting('last_telegram_auto_backup_error');
});

/// সর্বশেষ স্বয়ংক্রিয় ব্যাকআপ প্রচেষ্টার সময়
final lastTelegramAutoBackupAttemptTimeStreamProvider = StreamProvider<String?>((ref) {
  final store = ref.watch(telegramConfigStoreProvider);
  return store.watchSetting('last_telegram_auto_backup_attempt_time');
});

/// ব্যাকআপ ও রিস্টোর মিউটেশন কন্ট্রোলার (Mutation Controller)
///
/// এটি নিশ্চিত করে যে:
/// ১. ব্যাকআপ বা রিস্টোরের সময় বাটনে ডাবল-ট্যাপ প্রতিরোধ হবে।
/// ২. লোডিং অবস্থা ও ত্রুটি অবস্থা `AsyncValue`-এর মাধ্যমে স্বচ্ছভাবে পরিচালিত হবে।
/// ৩. নন-টেকনিক্যাল মানবিক বাংলায় সকল এরর হ্যান্ডেল হবে।
class BackupController extends MutationController {
  final BackupRepository _repo;

  BackupController(this._repo);

  /// ফোনে অফলাইন ব্যাকআপ এক্সপোর্ট
  Future<File?> exportToPhone({String? customDestinationDir}) {
    return execute(() => _repo.exportBackup(
          customDestinationDir: customDestinationDir,
        ));
  }

  /// ব্যাকগ্রাউন্ড আইসোলেটে ব্যাকআপ ফাইল যাচাই
  Future<BackupValidationResult?> validateFile(String filePath) {
    return execute(() => _repo.validateBackupFile(filePath));
  }

  /// ফাইল থেকে ডেটাবেজ রিস্টোর
  Future<void> restoreFromFile(
    String filePath, {
    required void Function(AppDatabase newDb) onDatabaseReopened,
    File? customLiveDbFile,
    AppDatabase Function()? databaseOpener,
    bool preserveCurrentSettings = true,
  }) {
    return execute(() => _repo.restoreBackup(
          filePath,
          onDatabaseReopened: onDatabaseReopened,
          customLiveDbFile: customLiveDbFile,
          databaseOpener: databaseOpener,
          preserveCurrentSettings: preserveCurrentSettings,
        ));
  }

  /// টেলিগ্রাম ক্লাউড ব্যাকআপ
  Future<void> exportToTelegram({
    required String botToken,
    required String chatId,
    bool skipPdfs = true,
  }) {
    return execute(() => _repo.exportBackupToTelegram(
          botToken: botToken,
          chatId: chatId,
          skipPdfs: skipPdfs,
        ));
  }

  /// দৈনিক স্বয়ংক্রিয় টেলিগ্রাম ব্যাকআপ চালু বা বন্ধ
  Future<void> setAutoBackupTelegram(bool enabled) {
    return execute(() => _repo.setAutoBackupTelegram(enabled));
  }

  /// দৈনিক স্বয়ংক্রিয় ব্যাকআপ চেক ও রান (অ্যাপ ওপেনিংয়ে ব্যাকগ্রাউন্ডে কল হয়)
  Future<bool> checkAndRunDailyTelegramBackup() {
    return _repo.checkAndRunDailyTelegramBackup();
  }

  /// টেলিগ্রাম সেটিংস সেভ
  Future<void> saveTelegramConfig({
    required String botToken,
    required String chatId,
  }) {
    return execute(() => _repo.saveTelegramConfig(
          botToken: botToken,
          chatId: chatId,
        ));
  }

  /// সর্বশেষ ব্যাকআপ ফাইল পাওয়া
  Future<File?> getLatestBackupFile() {
    return _repo.getLatestBackupFile();
  }
}

/// সর্বশেষ ব্যাকআপ ফাইল প্রোভাইডার
final latestBackupFileProvider = FutureProvider.autoDispose<File?>((ref) async {
  final repo = ref.watch(backupRepositoryProvider);
  return repo.getLatestBackupFile();
});

/// ব্যাকআপ কন্ট্রোলার স্টেট প্রোভাইডার
final backupControllerProvider =
    StateNotifierProvider<BackupController, AsyncValue<void>>((ref) {
  final repo = ref.watch(backupRepositoryProvider);
  return BackupController(repo);
});
