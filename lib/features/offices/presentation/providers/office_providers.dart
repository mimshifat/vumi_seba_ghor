import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';

/// সকল সক্রিয় ভূমি অফিসের রিয়েক্টিভ ওয়াচ
final officesStreamProvider = StreamProvider<List<Office>>((ref) {
  final repo = ref.watch(officeRepositoryProvider);
  return repo.watchOffices();
});

/// নির্দিষ্ট ভূমি অফিসের বিবরণ
final officeDetailProvider =
    StreamProvider.family<Office?, String>((ref, id) {
  final repo = ref.watch(officeRepositoryProvider);
  return Stream.fromFuture(repo.getOffice(id));
});

/// অফিসের অধীনস্থ সক্রিয় আবেদনের সংখ্যা
final officeApplicationCountProvider =
    FutureProvider.family<int, String>((ref, officeId) {
  final repo = ref.watch(officeRepositoryProvider);
  return repo.getApplicationCountForOffice(officeId);
});

/// ভূমি অফিস মিউটেশন কন্ট্রোলার (সেফটি লক সহ)
class OfficeController extends MutationController {
  final OfficeRepository _repo;
  final Ref? _ref;

  OfficeController(this._repo, [this._ref]);

  void _invalidateAll() {
    if (_ref != null) {
      _ref.invalidate(officesStreamProvider);
    }
  }

  /// নতুন ভূমি অফিস তৈরি
  Future<Office?> createOffice({
    String? id,
    required String name,
  }) async {
    final res = await execute(() => _repo.createOffice(id: id, name: name));
    if (res != null) _invalidateAll();
    return res;
  }

  /// ভূমি অফিসের নাম আপডেট
  Future<void> updateOffice({
    required String id,
    required String name,
  }) async {
    await execute(() => _repo.updateOffice(id: id, name: name));
    _invalidateAll();
    _ref?.invalidate(officeDetailProvider(id));
  }

  /// স্মার্ট ডিলিট: কোনো ফাইল না থাকলে হার্ড ডিলিট; ফাইল থাকলে সফট ডিলিট
  Future<bool?> deleteOffice(String id) async {
    final res = await execute(() => _repo.deleteOffice(id));
    if (res == true) {
      _invalidateAll();
      _ref?.invalidate(officeDetailProvider(id));
    }
    return res;
  }

  /// সফট ডিলিট ভূমি অফিস পুনরুদ্ধার
  Future<void> restoreOffice(String id) async {
    await execute(() => _repo.restoreOffice(id));
    _invalidateAll();
    _ref?.invalidate(officeDetailProvider(id));
  }
}

/// ভূমি অফিস কন্ট্রোলার প্রোভাইডার
final officeControllerProvider =
    StateNotifierProvider<OfficeController, AsyncValue<void>>((ref) {
  final repo = ref.watch(officeRepositoryProvider);
  return OfficeController(repo, ref);
});

