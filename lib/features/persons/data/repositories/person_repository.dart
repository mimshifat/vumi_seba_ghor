import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/validators.dart';

/// গ্রাহক খাতা রিপোজিটরি (BACKEND_MASTER_PLAN.md §1.3, §5)
class PersonRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  PersonRepository(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  /// গ্রাহকদের রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<Person>> watchPersons({
    String? search,
    bool includeDeleted = false,
  }) {
    return _db.personDao.watchPersons(
      search: search,
      includeDeleted: includeDeleted,
    );
  }

  /// গ্রাহকদের তালিকা সংগ্রহ (Future)
  Future<List<Person>> getPersons({
    String? search,
    bool includeDeleted = false,
  }) async {
    try {
      return await _db.personDao.getPersons(
        search: search,
        includeDeleted: includeDeleted,
      );
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট গ্রাহক খোঁজা
  Future<Person?> getPerson(String id, {bool includeDeleted = false}) async {
    try {
      return await _db.personDao.getPersonById(id, includeDeleted: includeDeleted);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট গ্রাহকের রিয়েক্টিভ ওয়াচ
  Stream<Person?> watchPerson(String id) {
    return _db.personDao.watchPersonById(id);
  }

  /// নতুন গ্রাহক তৈরি — ১১ ডিজিট মোবাইল নম্বর স্ট্যান্ডার্ডাইজেশন সহ
  Future<Person> createPerson({
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
        throw AppFailure.requiredField('গ্রাহকের নাম');
      }

      final cleanPhone = AppValidators.standardizePhone(phone);
      if (!AppValidators.isValidPhone(cleanPhone)) {
        throw AppFailure.invalidPhone();
      }

      final personId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.personDao.insertPerson(
        PersonsCompanion.insert(
          id: personId,
          name: cleanName,
          phone: cleanPhone,
          address: Value(address?.trim()),
          photo: Value(photo),
          notes: Value(notes?.trim()),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final created = await _db.personDao.getPersonById(personId);
      return created!;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// গ্রাহকের তথ্য আপডেট
  Future<void> updatePerson({
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
        throw AppFailure.requiredField('গ্রাহকের নাম');
      }

      final cleanPhone = AppValidators.standardizePhone(phone);
      if (!AppValidators.isValidPhone(cleanPhone)) {
        throw AppFailure.invalidPhone();
      }

      final existing = await _db.personDao.getPersonById(id);
      if (existing == null) {
        throw AppFailure.custom('গ্রাহক খুঁজে পাওয়া যায়নি।');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.personDao.updatePerson(
        PersonsCompanion(
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
  /// অতীত আবেদনের স্ন্যাপশট অক্ষত থাকবে। (BACKEND_MASTER_PLAN.md §1.3)
  Future<bool> deletePerson(String id) async {
    try {
      return await _db.personDao.deletePerson(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// সফট ডিলিট গ্রাহক পুনরুদ্ধার
  Future<void> restorePerson(String id) async {
    try {
      await _db.personDao.restorePerson(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// গ্রাহকের সক্রিয় আবেদনের সংখ্যা
  Future<int> getApplicationCountForPerson(String personId) async {
    try {
      return await _db.personDao.getApplicationCountForPerson(personId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }
}

