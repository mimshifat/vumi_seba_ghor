import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/validators.dart';

/// রেফারেন্স খাতা রিপোজিটরি (BACKEND_MASTER_PLAN.md §1.2 নিয়ম ৬, §1.3, §5)
class ReferenceRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  ReferenceRepository(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  /// রেফারেন্স ব্যক্তিদের রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<Reference>> watchReferences({
    String? search,
    bool includeDeleted = false,
  }) {
    return _db.referenceDao.watchReferences(
      search: search,
      includeDeleted: includeDeleted,
    );
  }

  /// রেফারেন্স ব্যক্তিদের তালিকা সংগ্রহ (Future)
  Future<List<Reference>> getReferences({
    String? search,
    bool includeDeleted = false,
  }) async {
    try {
      return await _db.referenceDao.getReferences(
        search: search,
        includeDeleted: includeDeleted,
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট রেফারেন্স ব্যক্তি খোঁজা
  Future<Reference?> getReference(String id,
      {bool includeDeleted = false}) async {
    try {
      return await _db.referenceDao
          .getReferenceById(id, includeDeleted: includeDeleted);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট রেফারেন্স ব্যক্তির রিয়েক্টিভ ওয়াচ
  Stream<Reference?> watchReference(String id) {
    return _db.referenceDao.watchReferenceById(id);
  }

  /// রেফারেন্স ব্যক্তির আর্থিক ও কাজের পরিসংখ্যান (Reference Ledger)
  Future<ReferenceLedgerStats> getReferenceStats(String referenceId) async {
    try {
      return await _db.referenceDao.getReferenceStats(referenceId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নতুন রেফারেন্স ব্যক্তি তৈরি — ১১ ডিজিট ফোন নম্বর স্ট্যান্ডার্ডাইজেশন সহ
  Future<Reference> createReference({
    String? id,
    required String name,
    required String phone,
    String? address,
    Uint8List? photo,
    String? notes,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('রেফারেন্স ব্যক্তির নাম');
      }

      final cleanPhone = AppValidators.standardizePhone(phone);
      if (!AppValidators.isValidPhone(cleanPhone)) {
        throw AppFailure.invalidPhone();
      }

      final refId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.referenceDao.insertReference(
        ReferencesCompanion.insert(
          id: refId,
          name: cleanName,
          phone: cleanPhone,
          address: Value(address?.trim()),
          photo: Value(photo),
          notes: Value(notes?.trim()),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final created = await _db.referenceDao.getReferenceById(refId);
      return created!;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// রেফারেন্স ব্যক্তির তথ্য আপডেট
  Future<void> updateReference({
    required String id,
    required String name,
    required String phone,
    String? address,
    Uint8List? photo,
    String? notes,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('রেফারেন্স ব্যক্তির নাম');
      }

      final cleanPhone = AppValidators.standardizePhone(phone);
      if (!AppValidators.isValidPhone(cleanPhone)) {
        throw AppFailure.invalidPhone();
      }

      final existing = await _db.referenceDao.getReferenceById(id);
      if (existing == null) {
        throw AppFailure.custom('রেফারেন্স ব্যক্তি খুঁজে পাওয়া যায়নি।');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.referenceDao.updateReference(
        ReferencesCompanion(
          id: Value(id),
          name: Value(cleanName),
          phone: Value(cleanPhone),
          address: Value(address?.trim()),
          photo: Value(photo ?? existing.photo),
          notes: Value(notes?.trim()),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
          deletedAt: Value(existing.deletedAt),
        ),
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// স্মার্ট ডিলিট: কোনো ফাইল না থাকলে হার্ড ডিলিট; ফাইল থাকলে সফট ডিলিট।
  /// অতীত আবেদনে `referenceName` স্ন্যাপশট ১০০% অক্ষত থাকবে। (BACKEND_MASTER_PLAN.md §1.3)
  Future<bool> deleteReference(String id) async {
    try {
      return await _db.referenceDao.deleteReference(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// সফট ডিলিট রেফারেন্স ব্যক্তি পুনরুদ্ধার
  Future<void> restoreReference(String id) async {
    try {
      await _db.referenceDao.restoreReference(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// রেফারেন্স ব্যক্তির অধীনে সক্রিয় আবেদনের সংখ্যা
  Future<int> getApplicationCountForReference(String referenceId) async {
    try {
      return await _db.referenceDao
          .getApplicationCountForReference(referenceId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }
}

