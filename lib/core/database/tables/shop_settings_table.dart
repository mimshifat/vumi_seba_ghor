import 'package:drift/drift.dart';

/// দোকানের প্রোফাইল ও সেটিংস — key/value স্টোর।
///
/// ইচ্ছাকৃত ব্যতিক্রম: প্রাইমারি কী `key` (TEXT) — এটি একটি key-value
/// স্টোর, তাই UUID প্রাইমারি কীর নিয়ম এখানে প্রযোজ্য নয়।
class ShopSettings extends Table {
  @override
  String get tableName => 'shop_settings';

  /// সেটিংসের কী — SQL কলামের নাম `key`।
  ///
  /// Dart-এ `Table.key` নামে একটি সদস্য থাকায় এখানে `settingKey` নাম
  /// ব্যবহার করা হয়েছে, কিন্তু `.named('key')` দিয়ে কলামের প্রকৃত নাম
  /// অপরিবর্তিত রাখা হয়েছে।
  TextColumn get settingKey => text().named('key')();

  TextColumn get value => text()();

  /// Unix epoch milliseconds।
  IntColumn get createdAt => integer()();

  /// Unix epoch milliseconds।
  IntColumn get updatedAt => integer()();

  /// সফট ডিলিট টাইমস্ট্যাম্প। NULL মানে রেকর্ড সক্রিয়।
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};

  @override
  List<String> get customConstraints => [
        'CHECK (length(trim("key")) > 0)',
      ];
}
