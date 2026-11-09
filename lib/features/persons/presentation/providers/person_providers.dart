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

  PersonController(this._repo);

  /// নতুন গ্রাহক তৈরি
  Future<Person?> createPerson({
    String? id,
    required String name,
    required String phone,
    String? address,
    Uint8List? photo,
    String? notes,
  }) {
    return execute(() => _repo.createPerson(
          id: id,
          name: name,
          phone: phone,
          address: address,
          photo: photo,
          notes: notes,
        ));
  }

  /// গ্রাহক তথ্য আপডেট
  Future<void> updatePerson({
    required String id,
    required String name,
    required String phone,
    String? address,
    Uint8List? photo,
    String? notes,
  }) {
    return execute(() => _repo.updatePerson(
          id: id,
          name: name,
          phone: phone,
          address: address,
          photo: photo,
          notes: notes,
        ));
  }

  /// স্মার্ট ডিলিট: কোনো ফাইল না থাকলে হার্ড ডিলিট; ফাইল থাকলে সফট ডিলিট
  Future<bool?> deletePerson(String id) {
    return execute(() => _repo.deletePerson(id));
  }

  /// সফট ডিলিট গ্রাহক পুনরুদ্ধার
  Future<void> restorePerson(String id) {
    return execute(() => _repo.restorePerson(id));
  }
}

/// গ্রাহক কন্ট্রোলার প্রোভাইডার
final personControllerProvider =
    StateNotifierProvider<PersonController, AsyncValue<void>>((ref) {
  final repo = ref.watch(personRepositoryProvider);
  return PersonController(repo);
});

