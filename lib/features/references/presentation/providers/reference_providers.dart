import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';

/// রেফারেন্স সার্চ কিউয়েরি প্রোভাইডার
final referenceSearchQueryProvider = StateProvider<String>((ref) => '');

/// রেফারেন্স ব্যক্তিদের রিয়েক্টিভ ওয়াচ স্ট্রিম
final referencesStreamProvider = StreamProvider<List<Reference>>((ref) {
  final repo = ref.watch(referenceRepositoryProvider);
  final search = ref.watch(referenceSearchQueryProvider);
  return repo.watchReferences(search: search.isNotEmpty ? search : null);
});

/// নির্দিষ্ট একক রেফারেন্স ব্যক্তির রিয়েক্টিভ ওয়াচ
final referenceDetailProvider =
    StreamProvider.family<Reference?, String>((ref, id) {
  final repo = ref.watch(referenceRepositoryProvider);
  return repo.watchReference(id);
});

/// রেফারেন্স খাতা পরিসংখ্যান (Reference Ledger Statistics)
final referenceStatsProvider =
    FutureProvider.family<ReferenceLedgerStats, String>((ref, referenceId) {
  final repo = ref.watch(referenceRepositoryProvider);
  return repo.getReferenceStats(referenceId);
});

/// রেফারেন্স ব্যক্তির অধীনস্থ সক্রিয় আবেদন সংখ্যা
final referenceApplicationCountProvider =
    FutureProvider.family<int, String>((ref, referenceId) {
  final repo = ref.watch(referenceRepositoryProvider);
  return repo.getApplicationCountForReference(referenceId);
});

/// রেফারেন্স মিউটেশন কন্ট্রোলার (সেফটি লক সহ)
class ReferenceController extends MutationController {
  final ReferenceRepository _repo;
  final Ref? _ref;

  ReferenceController(this._repo, [this._ref]);

  void _invalidateAll() {
    if (_ref != null) {
      _ref.invalidate(referencesStreamProvider);
    }
  }

  /// নতুন রেফারেন্স তৈরি
  Future<Reference?> createReference({
    String? id,
    required String name,
    required String phone,
    String? address,
    Uint8List? photo,
    String? notes,
  }) async {
    final res = await execute(() => _repo.createReference(
          id: id,
          name: name,
          phone: phone,
          address: address,
          photo: photo,
          notes: notes,
        ));
    if (res != null) _invalidateAll();
    return res;
  }

  /// রেফারেন্স তথ্য আপডেট
  Future<void> updateReference({
    required String id,
    required String name,
    required String phone,
    String? address,
    Uint8List? photo,
    bool updatePhoto = false,
    String? notes,
  }) async {
    await execute(() => _repo.updateReference(
          id: id,
          name: name,
          phone: phone,
          address: address,
          photo: photo,
          updatePhoto: updatePhoto,
          notes: notes,
        ));
    _invalidateAll();
    _ref?.invalidate(referenceDetailProvider(id));
  }

  /// স্মার্ট ডিলিট: কোনো ফাইল না থাকলে হার্ড ডিলিট; ফাইল থাকলে সফট ডিলিট
  Future<bool?> deleteReference(String id) async {
    final res = await execute(() => _repo.deleteReference(id));
    if (res == true) {
      _invalidateAll();
      _ref?.invalidate(referenceDetailProvider(id));
    }
    return res;
  }

  /// সফট ডিলিট রেফারেন্স পুনরুদ্ধার
  Future<void> restoreReference(String id) async {
    await execute(() => _repo.restoreReference(id));
    _invalidateAll();
    _ref?.invalidate(referenceDetailProvider(id));
  }
}

/// রেফারেন্স কন্ট্রোলার প্রোভাইডার
final referenceControllerProvider =
    StateNotifierProvider<ReferenceController, AsyncValue<void>>((ref) {
  final repo = ref.watch(referenceRepositoryProvider);
  return ReferenceController(repo, ref);
});

