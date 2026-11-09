import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';

/// গ্রাহক সার্চ কিউয়েরি প্রোভাইডার
final personSearchQueryProvider = StateProvider<String>((ref) => '');

/// গ্রাহকদের রিয়েক্টিভ ওয়াচ স্ট্রিম
final personsStreamProvider = StreamProvider<List<Person>>((ref) {
  final repo = ref.watch(personRepositoryProvider);
  final search = ref.watch(personSearchQueryProvider);
  return repo.watchPersons(search: search.isNotEmpty ? search : null);
});

/// নির্দিষ্ট একক গ্রাহকের রিয়েক্টিভ ওয়াচ
final personDetailProvider = StreamProvider.family<Person?, String>((ref, id) {
  final repo = ref.watch(personRepositoryProvider);
  return repo.watchPerson(id);
});

/// গ্রাহকের অধীনস্থ সক্রিয় আবেদন সংখ্যা
final personApplicationCountProvider =
    FutureProvider.family<int, String>((ref, personId) {
  final repo = ref.watch(personRepositoryProvider);
  return repo.getApplicationCountForPerson(personId);
});

/// গ্রাহক মিউটেশন কন্ট্রোলার (সেফটি লক সহ)
class PersonController extends MutationController {
  final PersonRepository _repo;
  final Ref? _ref;

  PersonController(this._repo, [this._ref]);

  void _invalidateAll() {
    if (_ref != null) {
      _ref.invalidate(personsStreamProvider);
    }
  }

  /// নতুন গ্রাহক তৈরি
  Future<Person?> createPerson({
    String? id,
    required String name,
    required String phone,
    String? address,
    Uint8List? photo,
    String? notes,
  }) async {
    final res = await execute(() => _repo.createPerson(
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

  /// গ্রাহক তথ্য আপডেট
  Future<void> updatePerson({
    required String id,
    required String name,
    required String phone,
    String? address,
    Uint8List? photo,
    String? notes,
  }) async {
    await execute(() => _repo.updatePerson(
          id: id,
          name: name,
          phone: phone,
          address: address,
          photo: photo,
          notes: notes,
        ));
    _invalidateAll();
    _ref?.invalidate(personDetailProvider(id));
  }

  /// স্মার্ট ডিলিট: কোনো ফাইল না থাকলে হার্ড ডিলিট; ফাইল থাকলে সফট ডিলিট
  Future<bool?> deletePerson(String id) async {
    final res = await execute(() => _repo.deletePerson(id));
    if (res == true) {
      _invalidateAll();
      _ref?.invalidate(personDetailProvider(id));
    }
    return res;
  }

  /// সফট ডিলিট গ্রাহক পুনরুদ্ধার
  Future<void> restorePerson(String id) async {
    await execute(() => _repo.restorePerson(id));
    _invalidateAll();
    _ref?.invalidate(personDetailProvider(id));
  }
}

/// গ্রাহক কন্ট্রোলার প্রোভাইডার
final personControllerProvider =
    StateNotifierProvider<PersonController, AsyncValue<void>>((ref) {
  final repo = ref.watch(personRepositoryProvider);
  return PersonController(repo, ref);
});

