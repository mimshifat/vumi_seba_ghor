import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';

/// দোকানের প্রোফাইল ও সেটিংস রিপোজিটরি (BACKEND_MASTER_PLAN.md §1.2, §5)
class ShopSettingsRepository {
  final AppDatabase _db;

  ShopSettingsRepository(this._db);

  /// নির্দিষ্ট সেটিংস কি-এর মানের রিয়েক্টিভ ওয়াচ
  Stream<String?> watchSetting(String key) {
    return _db.shopSettingsDao.watchSetting(key);
  }

  /// নির্দিষ্ট সেটিংস কি-এর মান সংগ্রহ
  Future<String?> getSetting(String key) async {
    try {
      return await _db.shopSettingsDao.getSetting(key);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// সেটিংস আপডেট বা সংরক্ষণ
  Future<void> setSetting(String key, String value) async {
    try {
      if (key.trim().isEmpty) {
        throw AppFailure.requiredField('সেটিংসের কী');
      }
      await _db.shopSettingsDao.setSetting(key.trim(), value.trim());
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// সকল সেটিংসের রিয়েক্টিভ ওয়াচ
  Stream<Map<String, String>> watchAllSettings() {
    return _db.shopSettingsDao.watchAllSettings();
  }

  /// সকল সেটিংস সংগ্রহ
  Future<Map<String, String>> getAllSettings() async {
    try {
      return await _db.shopSettingsDao.getAllSettings();
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }
}

