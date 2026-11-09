import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/providers/mutation_controller.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/repositories/backup_repository.dart';
import '../../domain/models/backup_validation_result.dart';

export '../../data/repositories/backup_repository.dart';
export '../../domain/models/backup_validation_result.dart';

/// ব্যাকআপ ও রিস্টোর রিপোজিটরি প্রোভাইডার
final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupRepository(db);
});

/// সর্বশেষ ব্যাকআপ সময়ের রিয়েক্টিভ ওয়াচ
final lastBackupTimeStreamProvider = StreamProvider<String?>((ref) {
  return ref.watch(shopSettingProvider('last_backup_time').stream);
});

/// টেলিগ্রাম বট টোকেন ওয়াচ
final telegramBotTokenStreamProvider = StreamProvider<String?>((ref) {
  return ref.watch(shopSettingProvider('telegram_bot_token').stream);
});

/// টেলিগ্রাম চ্যাট আইডি ওয়াচ
final telegramChatIdStreamProvider = StreamProvider<String?>((ref) {
  return ref.watch(shopSettingProvider('telegram_chat_id').stream);
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
  }) {
    return execute(() => _repo.restoreBackup(
          filePath,
          onDatabaseReopened: onDatabaseReopened,
          customLiveDbFile: customLiveDbFile,
          databaseOpener: databaseOpener,
        ));
  }

  /// টেলিগ্রাম ক্লাউড ব্যাকআপ
  Future<void> exportToTelegram({
    required String botToken,
    required String chatId,
  }) {
    return execute(() => _repo.exportBackupToTelegram(
          botToken: botToken,
          chatId: chatId,
        ));
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
}

/// ব্যাকআপ কন্ট্রোলার স্টেট প্রোভাইডার
final backupControllerProvider =
    StateNotifierProvider<BackupController, AsyncValue<void>>((ref) {
  final repo = ref.watch(backupRepositoryProvider);
  return BackupController(repo);
});
