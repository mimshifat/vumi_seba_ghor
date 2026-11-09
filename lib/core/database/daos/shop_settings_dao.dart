import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/shop_settings_table.dart';

part 'shop_settings_dao.g.dart';

@DriftAccessor(tables: [ShopSettings])
class ShopSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$ShopSettingsDaoMixin {
  ShopSettingsDao(super.db);

  /// নির্দিষ্ট সেটিংস কি-এর মানের রিয়েক্টিভ ওয়াচ
  Stream<String?> watchSetting(String key) {
    return (select(shopSettings)
          ..where((tbl) => tbl.settingKey.equals(key) & tbl.deletedAt.isNull()))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  /// নির্দিষ্ট সেটিংস কি-এর মান সংগ্রহ (Future)
  Future<String?> getSetting(String key) async {
    final row = await (select(shopSettings)
          ..where((tbl) => tbl.settingKey.equals(key) & tbl.deletedAt.isNull()))
        .getSingleOrNull();
    return row?.value;
  }

  /// সেটিংস আপডেট বা নতুন মান সংযোজন (Upsert)
  Future<int> setSetting(String key, String value) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(shopSettings).insertOnConflictUpdate(
      ShopSettingsCompanion(
        settingKey: Value(key),
        value: Value(value),
        createdAt: Value(now),
        updatedAt: Value(now),
        deletedAt: const Value(null),
      ),
    );
  }

  /// সকল সেটিংসের রিয়েক্টিভ ওয়াচ (Key-Value ম্যাপ আকারে)
  Stream<Map<String, String>> watchAllSettings() {
    return (select(shopSettings)..where((tbl) => tbl.deletedAt.isNull()))
        .watch()
        .map((rows) => {for (final row in rows) row.settingKey: row.value});
  }

  /// সকল সেটিংস সংগ্রহ (Key-Value ম্যাপ)
  Future<Map<String, String>> getAllSettings() async {
    final rows = await (select(shopSettings)
          ..where((tbl) => tbl.deletedAt.isNull()))
        .get();
    return {for (final row in rows) row.settingKey: row.value};
  }
}

