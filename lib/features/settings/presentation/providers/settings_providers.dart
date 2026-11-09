import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';

// -------------------------------------------------------------
// খাত ও ক্যাটাগরি স্ট্রিম প্রোভাইডার
// -------------------------------------------------------------

/// খরচের খাত স্ট্রিম (isGeneral null হলে সব, true হলে সাধারণ, false হলে ফাইলের খরচ)
final expenseCategoriesStreamProvider =
    StreamProvider.family<List<ExpenseCategory>, bool?>((ref, isGeneral) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchExpenseCategories(isGeneral: isGeneral);
});

/// স্বতন্ত্র আয়ের খাত স্ট্রিম
final incomeCategoriesStreamProvider =
    StreamProvider<List<IncomeCategory>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchIncomeCategories();
});

/// কাজের ধরনের স্ট্রিম
final workTypesStreamProvider = StreamProvider<List<WorkType>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchWorkTypes();
});

/// দোকানের সকল সেটিংসের রিয়েক্টিভ ওয়াচ (Key-Value Map)
final shopSettingsStreamProvider = StreamProvider<Map<String, String>>((ref) {
  final repo = ref.watch(shopSettingsRepositoryProvider);
  return repo.watchAllSettings();
});

/// একক সেটিংস কি-এর মানের রিয়েক্টিভ ওয়াচ
final shopSettingProvider =
    StreamProvider.family<String?, String>((ref, key) {
  final repo = ref.watch(shopSettingsRepositoryProvider);
  return repo.watchSetting(key);
});

// -------------------------------------------------------------
// ক্যাটাগরি মিউটেশন কন্ট্রোলার (Category Mutation Controller)
// -------------------------------------------------------------

class CategoryController extends MutationController {
  final CategoryRepository _repo;
  final Ref? _ref;

  CategoryController(this._repo, [this._ref]);

  void _invalidateAll() {
    if (_ref != null) {
      _ref.invalidate(expenseCategoriesStreamProvider(null));
      _ref.invalidate(expenseCategoriesStreamProvider(true));
      _ref.invalidate(expenseCategoriesStreamProvider(false));
      _ref.invalidate(incomeCategoriesStreamProvider);
      _ref.invalidate(workTypesStreamProvider);
    }
  }

  /// খরচের খাত তৈরি
  Future<ExpenseCategory?> createExpenseCategory({
    String? id,
    required String name,
    required bool isGeneral,
  }) async {
    final res = await execute(() => _repo.createExpenseCategory(
          id: id,
          name: name,
          isGeneral: isGeneral,
        ));
    if (res != null) _invalidateAll();
    return res;
  }

  /// খরচের খাত আপডেট
  Future<void> updateExpenseCategory({
    required String id,
    required String name,
  }) async {
    await execute(() => _repo.updateExpenseCategory(id: id, name: name));
    _invalidateAll();
  }

  /// খরচের খাত মোছা (সিস্টেমের ডিফল্ট খাত সুরক্ষা সহ)
  Future<bool?> deleteExpenseCategory(String id) async {
    final res = await execute(() => _repo.deleteExpenseCategory(id));
    if (res == true) _invalidateAll();
    return res;
  }

  /// স্বতন্ত্র আয়ের খাত তৈরি
  Future<IncomeCategory?> createIncomeCategory({
    String? id,
    required String name,
  }) async {
    final res = await execute(() => _repo.createIncomeCategory(id: id, name: name));
    if (res != null) _invalidateAll();
    return res;
  }

  /// স্বতন্ত্র আয়ের খাত আপডেট
  Future<void> updateIncomeCategory({
    required String id,
    required String name,
  }) async {
    await execute(() => _repo.updateIncomeCategory(id: id, name: name));
    _invalidateAll();
  }

  /// স্বতন্ত্র আয়ের খাত মোছা (ডিফল্ট সুরক্ষা সহ)
  Future<bool?> deleteIncomeCategory(String id) async {
    final res = await execute(() => _repo.deleteIncomeCategory(id));
    if (res == true) _invalidateAll();
    return res;
  }

  /// কাজের ধরন তৈরি
  Future<WorkType?> createWorkType({
    String? id,
    required String name,
  }) async {
    final res = await execute(() => _repo.createWorkType(id: id, name: name));
    if (res != null) _invalidateAll();
    return res;
  }

  /// কাজের ধরন আপডেট
  Future<void> updateWorkType({
    required String id,
    required String name,
  }) async {
    await execute(() => _repo.updateWorkType(id: id, name: name));
    _invalidateAll();
  }

  /// কাজের ধরন মোছা (ডিফল্ট সুরক্ষা সহ)
  Future<bool?> deleteWorkType(String id) async {
    final res = await execute(() => _repo.deleteWorkType(id));
    if (res == true) _invalidateAll();
    return res;
  }
}

final categoryControllerProvider =
    StateNotifierProvider<CategoryController, AsyncValue<void>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return CategoryController(repo, ref);
});

// -------------------------------------------------------------
// দোকান সেটিংস কন্ট্রোলার (Shop Settings Controller)
// -------------------------------------------------------------

class ShopSettingsController extends MutationController {
  final ShopSettingsRepository _repo;

  ShopSettingsController(this._repo);

  /// সেটিংস আপডেট বা সংরক্ষণ
  Future<void> setSetting(String key, String value) {
    return execute(() => _repo.setSetting(key, value));
  }
}

final shopSettingsControllerProvider =
    StateNotifierProvider<ShopSettingsController, AsyncValue<void>>((ref) {
  final repo = ref.watch(shopSettingsRepositoryProvider);
  return ShopSettingsController(repo);
});

