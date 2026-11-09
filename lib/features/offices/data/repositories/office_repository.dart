import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';

/// ভূমি অফিস রিপোজিটরি (BACKEND_MASTER_PLAN.md §1.3, §5)
class OfficeRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  OfficeRepository(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  /// সকল ভূমি অফিসের রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<Office>> watchOffices({bool includeDeleted = false}) {
    return _db.officeDao.watchOffices(includeDeleted: includeDeleted);
  }

  /// সকল ভূমি অফিসের তালিকা সংগ্রহ (Future)
  Future<List<Office>> getOffices({bool includeDeleted = false}) async {
    try {
      return await _db.officeDao.getOffices(includeDeleted: includeDeleted);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট ভূমি অফিস সংগ্রহ
  Future<Office?> getOffice(String id, {bool includeDeleted = false}) async {
    try {
      return await _db.officeDao.getOfficeById(id, includeDeleted: includeDeleted);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নতুন ভূমি অফিস তৈরি
  Future<Office> createOffice({
    String? id,
    required String name,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('ভূমি অফিসের নাম');
      }

      final officeId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.officeDao.insertOffice(
        OfficesCompanion.insert(
          id: officeId,
          name: cleanName,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final created = await _db.officeDao.getOfficeById(officeId);
      return created!;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// ভূমি অফিসের নাম আপডেট
  Future<void> updateOffice({
    required String id,
    required String name,
  }) async {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('ভূমি অফিসের নাম');
      }

      final existing = await _db.officeDao.getOfficeById(id);
      if (existing == null) {
        throw AppFailure.custom('ভূমি অফিস খুঁজে পাওয়া যায়নি।');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.officeDao.updateOffice(
        OfficesCompanion(
          id: Value(id),
          name: Value(cleanName),
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
  /// অতীত আবেদনের `officeName` স্ন্যাপশট ১০০% অক্ষত থাকবে। (BACKEND_MASTER_PLAN.md §1.3)
  Future<bool> deleteOffice(String id) async {
    try {
      return await _db.officeDao.deleteOffice(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// সফট ডিলিট ভূমি অফিস পুনরুদ্ধার
  Future<void> restoreOffice(String id) async {
    try {
      await _db.officeDao.restoreOffice(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// অফিসের অধীনে সক্রিয় আবেদনের সংখ্যা
  Future<int> getApplicationCountForOffice(String officeId) async {
    try {
      return await _db.officeDao.getApplicationCountForOffice(officeId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }
}

