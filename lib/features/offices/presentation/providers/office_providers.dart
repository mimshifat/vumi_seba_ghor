import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';
import '../../domain/models/office_mouza_data.dart';

/// সকল সক্রিয় ভূমি অফিসের রিয়েক্টিভ ওয়াচ
final officesStreamProvider = StreamProvider<List<Office>>((ref) {
  final repo = ref.watch(officeRepositoryProvider);
  return repo.watchOffices();
});

/// ব্যবহারকারীর নিজস্ব যুক্ত করা কাস্টম মৌজাসমূহের রিয়েক্টিভ ওয়াচ (অফিসভিত্তিক)
final customMouzasStreamProvider =
    StreamProvider<Map<String, List<String>>>((ref) {
  try {
    final db = ref.watch(appDatabaseProvider);
    return db.shopSettingsDao.watchSetting('custom_mouzas_json').map((jsonStr) {
      if (jsonStr == null || jsonStr.trim().isEmpty) return {};
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(
                k.toString(),
                (v as List).map((e) => e.toString()).toList(),
              ));
        }
      } catch (_) {}
      return {};
    });
  } catch (_) {
    return Stream.value({});
  }
});

/// ব্যবহারকারীর মুছে ফেলা মৌজাসমূহের রিয়েক্টিভ ওয়াচ (অফিসভিত্তিক)
final deletedMouzasStreamProvider =
    StreamProvider<Map<String, List<String>>>((ref) {
  try {
    final db = ref.watch(appDatabaseProvider);
    return db.shopSettingsDao
        .watchSetting('deleted_mouzas_json')
        .map((jsonStr) {
      if (jsonStr == null || jsonStr.trim().isEmpty) return {};
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(
                k.toString(),
                (v as List).map((e) => e.toString()).toList(),
              ));
        }
      } catch (_) {}
      return {};
    });
  } catch (_) {
    return Stream.value({});
  }
});

/// নির্দিষ্ট অফিসের জন্য মৌজাসমূহের রিয়েক্টিভ ওয়াচ
final mouzasForOfficeProvider =
    Provider.family<List<String>, String?>((ref, officeName) {
  final customMap = ref.watch(customMouzasStreamProvider).valueOrNull ?? {};
  final deletedMap = ref.watch(deletedMouzasStreamProvider).valueOrNull ?? {};
  final customList =
      officeName != null ? (customMap[officeName.trim()] ?? []) : <String>[];
  final deletedList =
      officeName != null ? (deletedMap[officeName.trim()] ?? []) : <String>[];
  return OfficeMouzaData.getMouzasForOffice(
    officeName,
    customMouzas: customList,
    deletedMouzas: deletedList,
  );
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

  /// নির্দিষ্ট অফিসে নতুন মৌজা যোগ করা
  Future<void> addCustomMouza({
    required String officeName,
    required String mouzaName,
  }) async {
    final cleanOffice = officeName.trim();
    final cleanMouza = mouzaName.trim();
    if (cleanOffice.isEmpty || cleanMouza.isEmpty || _ref == null) {
      return;
    }

    await execute(() async {
      final db = _ref.read(appDatabaseProvider);

      // ১. পূর্বে মুছে ফেলা তালিকায় থাকলে সেখান থেকে বাদ দেওয়া (পুনরুদ্ধার)
      final delJson = await db.shopSettingsDao.getSetting('deleted_mouzas_json');
      if (delJson != null && delJson.trim().isNotEmpty) {
        try {
          final decodedDel = jsonDecode(delJson);
          if (decodedDel is Map) {
            final delMap = decodedDel.map((k, v) => MapEntry(
                  k.toString(),
                  (v as List).map((e) => e.toString()).toList(),
                ));
            final delList = delMap[cleanOffice] ?? [];
            if (delList.contains(cleanMouza)) {
              delMap[cleanOffice] =
                  delList.where((e) => e != cleanMouza).toList();
              await db.shopSettingsDao.setSetting(
                'deleted_mouzas_json',
                jsonEncode(delMap),
              );
            }
          }
        } catch (_) {}
      }

      // ২. কাস্টম মৌজা তালিকায় সংরক্ষণ
      final jsonStr = await db.shopSettingsDao.getSetting('custom_mouzas_json');
      Map<String, List<String>> map = {};
      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map) {
            map = decoded.map((k, v) => MapEntry(
                  k.toString(),
                  (v as List).map((e) => e.toString()).toList(),
                ));
          }
        } catch (_) {}
      }

      final current = map[cleanOffice] ?? [];
      if (!current.contains(cleanMouza)) {
        map[cleanOffice] = [...current, cleanMouza];
        await db.shopSettingsDao
            .setSetting('custom_mouzas_json', jsonEncode(map));
      }
    });

    _ref.invalidate(customMouzasStreamProvider);
    _ref.invalidate(deletedMouzasStreamProvider);
    _ref.invalidate(mouzasForOfficeProvider(cleanOffice));
  }

  /// নির্দিষ্ট অফিসের যেকোনো (প্রমিত বা কাস্টম) মৌজার নাম পরিবর্তন (Edit)
  Future<void> updateMouza({
    required String officeName,
    required String oldMouzaName,
    required String newMouzaName,
  }) async {
    final cleanOffice = officeName.trim();
    final cleanOld = oldMouzaName.trim();
    final cleanNew = newMouzaName.trim();
    if (cleanOffice.isEmpty ||
        cleanOld.isEmpty ||
        cleanNew.isEmpty ||
        cleanOld == cleanNew ||
        _ref == null) {
      return;
    }

    await execute(() async {
      final db = _ref.read(appDatabaseProvider);

      // কাস্টম তালিকা পড়া
      final jsonStr = await db.shopSettingsDao.getSetting('custom_mouzas_json');
      Map<String, List<String>> customMap = {};
      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map) {
            customMap = decoded.map((k, v) => MapEntry(
                  k.toString(),
                  (v as List).map((e) => e.toString()).toList(),
                ));
          }
        } catch (_) {}
      }

      final currentCustom = customMap[cleanOffice] ?? [];
      final idx = currentCustom.indexOf(cleanOld);

      if (idx != -1) {
        // কাস্টম মৌজা হলে সরাসরি তালিকায় নাম আপডেট
        final updatedList = List<String>.from(currentCustom);
        updatedList[idx] = cleanNew;
        customMap[cleanOffice] = updatedList;
      } else {
        // প্রমিত/ডিফল্ট মৌজা হলে: পুরাতন নাম deleted তালিকায় রাখা এবং নতুন নাম custom তালিকায় যুক্ত করা
        final delJson =
            await db.shopSettingsDao.getSetting('deleted_mouzas_json');
        Map<String, List<String>> delMap = {};
        if (delJson != null && delJson.trim().isNotEmpty) {
          try {
            final decodedDel = jsonDecode(delJson);
            if (decodedDel is Map) {
              delMap = decodedDel.map((k, v) => MapEntry(
                    k.toString(),
                    (v as List).map((e) => e.toString()).toList(),
                  ));
            }
          } catch (_) {}
        }
        final curDel = delMap[cleanOffice] ?? [];
        if (!curDel.contains(cleanOld)) {
          delMap[cleanOffice] = [...curDel, cleanOld];
          await db.shopSettingsDao.setSetting(
            'deleted_mouzas_json',
            jsonEncode(delMap),
          );
        }

        if (!currentCustom.contains(cleanNew)) {
          customMap[cleanOffice] = [...currentCustom, cleanNew];
        }
      }

      await db.shopSettingsDao.setSetting(
        'custom_mouzas_json',
        jsonEncode(customMap),
      );
    });

    _ref.invalidate(customMouzasStreamProvider);
    _ref.invalidate(deletedMouzasStreamProvider);
    _ref.invalidate(mouzasForOfficeProvider(cleanOffice));
  }

  /// নির্দিষ্ট অফিসের যেকোনো (প্রমিত বা কাস্টম) মৌজা মুছে ফেলা (Delete)
  Future<void> deleteMouza({
    required String officeName,
    required String mouzaName,
  }) async {
    final cleanOffice = officeName.trim();
    final cleanMouza = mouzaName.trim();
    if (cleanOffice.isEmpty || cleanMouza.isEmpty || _ref == null) {
      return;
    }

    await execute(() async {
      final db = _ref.read(appDatabaseProvider);

      // ১. কাস্টম তালিকায় থাকলে সেখান থেকে মুছে ফেলা
      final jsonStr = await db.shopSettingsDao.getSetting('custom_mouzas_json');
      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map) {
            final customMap = decoded.map((k, v) => MapEntry(
                  k.toString(),
                  (v as List).map((e) => e.toString()).toList(),
                ));
            final current = customMap[cleanOffice] ?? [];
            if (current.contains(cleanMouza)) {
              customMap[cleanOffice] =
                  current.where((e) => e != cleanMouza).toList();
              await db.shopSettingsDao.setSetting(
                'custom_mouzas_json',
                jsonEncode(customMap),
              );
            }
          }
        } catch (_) {}
      }

      // ২. deleted_mouzas_json এ যোগ করা যাতে প্রমিত বা অন্য যেকোনো মৌজাও আর প্রদর্শিত না হয়
      final delJson =
          await db.shopSettingsDao.getSetting('deleted_mouzas_json');
      Map<String, List<String>> delMap = {};
      if (delJson != null && delJson.trim().isNotEmpty) {
        try {
          final decodedDel = jsonDecode(delJson);
          if (decodedDel is Map) {
            delMap = decodedDel.map((k, v) => MapEntry(
                  k.toString(),
                  (v as List).map((e) => e.toString()).toList(),
                ));
          }
        } catch (_) {}
      }

      final curDel = delMap[cleanOffice] ?? [];
      if (!curDel.contains(cleanMouza)) {
        delMap[cleanOffice] = [...curDel, cleanMouza];
        await db.shopSettingsDao.setSetting(
          'deleted_mouzas_json',
          jsonEncode(delMap),
        );
      }
    });

    _ref.invalidate(customMouzasStreamProvider);
    _ref.invalidate(deletedMouzasStreamProvider);
    _ref.invalidate(mouzasForOfficeProvider(cleanOffice));
  }

  /// Backward compatible wrapper
  Future<void> updateCustomMouza({
    required String officeName,
    required String oldMouzaName,
    required String newMouzaName,
  }) =>
      updateMouza(
        officeName: officeName,
        oldMouzaName: oldMouzaName,
        newMouzaName: newMouzaName,
      );

  /// Backward compatible wrapper
  Future<void> deleteCustomMouza({
    required String officeName,
    required String mouzaName,
  }) =>
      deleteMouza(
        officeName: officeName,
        mouzaName: mouzaName,
      );

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

