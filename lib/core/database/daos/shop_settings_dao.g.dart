// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$ShopSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShopSettingsTable get shopSettings => attachedDatabase.shopSettings;
  ShopSettingsDaoManager get managers => ShopSettingsDaoManager(this);
}

class ShopSettingsDaoManager {
  final _$ShopSettingsDaoMixin _db;
  ShopSettingsDaoManager(this._db);
  $$ShopSettingsTableTableManager get shopSettings =>
      $$ShopSettingsTableTableManager(_db.attachedDatabase, _db.shopSettings);
}
