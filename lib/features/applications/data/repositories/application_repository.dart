import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/case_number_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/models/application_with_financials.dart';

/// আবেদন ব্যবস্থাপনার ব্যবসায়িক রিপোজিটরি।
///
/// নিরাপত্তা, স্ন্যাপশট গ্যারান্টি, ডুপ্লিকেট চেকিং এবং এরর ম্যাপিং নিশ্চিত করে।
/// (BACKEND_MASTER_PLAN.md §1.2, §1.3, §2.1, §5)
class ApplicationRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  ApplicationRepository(this._db, [Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  /// ফিল্টার ও সার্চসহ সকল সক্রিয় আবেদনের স্ট্রিম
  Stream<List<Application>> watchApplications({
    String? status,
    String? workType,
    String? officeId,
    String? mouza,
    bool? isMarkedAsPaid,
    String? search,
    bool includeDeleted = false,
  }) {
    return _db.applicationDao.watchApplications(
      status: status,
      workType: workType,
      officeId: officeId,
      mouza: mouza,
      isMarkedAsPaid: isMarkedAsPaid,
      search: search,
      includeDeleted: includeDeleted,
    );
  }

  /// নির্দিষ্ট আবেদন খোঁজা
  Future<Application?> getApplication(String id,
      {bool includeDeleted = false}) async {
    try {
      return await _db.applicationDao
          .getApplicationById(id, includeDeleted: includeDeleted);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট আবেদনের রিয়েক্টিভ ওয়াচ
  Stream<Application?> watchApplication(String id) {
    return _db.applicationDao.watchApplicationById(id);
  }

  /// আবেদন ও তার মোট আর্থিক হিসাবসহ রিয়েক্টিভ ওয়াচ স্ট্রিম
  Stream<List<ApplicationWithFinancials>> watchApplicationsWithFinancials({
    bool includeDeleted = false,
  }) {
    return _db.applicationDao
        .watchApplicationsWithFinancials(includeDeleted: includeDeleted);
  }

  /// আবেদন ও তার মোট আর্থিক হিসাবসহ সংগ্রহ (Future)
  Future<List<ApplicationWithFinancials>> getApplicationsWithFinancials({
    bool includeDeleted = false,
  }) async {
    try {
      return await _db.applicationDao
          .getApplicationsWithFinancials(includeDeleted: includeDeleted);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্দিষ্ট আবেদনের সম্পূর্ণ আর্থিক হিসেবসহ তথ্য
  Future<ApplicationWithFinancials?> getApplicationWithFinancials(
      String id) async {
    try {
      return await _db.applicationDao.getApplicationWithFinancialsById(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নতুন আবেদন তৈরি — ইউনিভার্সাল স্ন্যাপশট ও ট্রানজ্যাকশন সেফটি সহ
  Future<Application> createApplication({
    String? id,
    String? applicantId,
    required String applicantName,
    required String applicantPhone,
    String? applicantAddress,
    String? referenceId,
    String? referenceName,
    String? officeId,
    required String officeName,
    String? mouza,
    String? appNumber,
    String? caseNumber,
    required String workType,
    DateTime? applicationDate,
    String status = 'আবেদন',
    required int agreedAmountPaisa,
    String? portalPhone,
    String? portalPassword,
    String? notes,
    int? initialPaymentPaisa,
    String initialPaymentMethod = 'নগদ',
  }) async {
    try {
      // ১. ইনপুট ভ্যালিডেশন
      final cleanName = applicantName.trim();
      if (cleanName.isEmpty) {
        throw AppFailure.requiredField('আবেদনকারীর নাম');
      }

      final standardizedPhone = AppValidators.standardizePhone(applicantPhone);
      if (!AppValidators.isValidPhone(standardizedPhone)) {
        throw AppFailure.invalidPhone();
      }

      final cleanOffice = officeName.trim();
      if (cleanOffice.isEmpty) {
        throw AppFailure.requiredField('ভূমি অফিস নির্বাচন');
      }

      final cleanWorkType = workType.trim();
      if (cleanWorkType.isEmpty) {
        throw AppFailure.requiredField('কাজের ধরন নির্বাচন');
      }

      if (agreedAmountPaisa <= 0) {
        throw AppFailure.invalidAmount(
            'চুক্তির টাকা শূন্য (০) বা তার বেশি হতে হবে।');
      }

      // ২. স্ন্যাপশট তথ্য রেজল্যুশন (যদি আইডি দেওয়া থাকে কিন্তু নাম না থাকে)
      String finalName = cleanName;
      String finalPhone = standardizedPhone;
      String? finalAddress = applicantAddress?.trim();
      String? finalRefName = referenceName?.trim();
      String finalOfficeName = cleanOffice;

      if (applicantId != null && applicantId.isNotEmpty) {
        final person = await _db.personDao.getPersonById(applicantId);
        if (person != null) {
          if (finalName.isEmpty) finalName = person.name;
          if (finalPhone.isEmpty) finalPhone = person.phone;
          finalAddress ??= person.address;
        }
      }

      if (referenceId != null && referenceId.isNotEmpty && (finalRefName == null || finalRefName.isEmpty)) {
        final ref = await _db.referenceDao.getReferenceById(referenceId);
        if (ref != null) {
          finalRefName = ref.name;
        }
      }

      if (officeId != null && officeId.isNotEmpty && finalOfficeName.isEmpty) {
        final office = await _db.officeDao.getOfficeById(officeId);
        if (office != null) {
          finalOfficeName = office.name;
        }
      }

      // ৩. ডুপ্লিকেট আবেদন নম্বর চেক
      final cleanAppNum = appNumber?.trim();
      if (cleanAppNum != null && cleanAppNum.isNotEmpty) {
        final isDuplicate = await _db.applicationDao.isDuplicateAppNumber(
          cleanAppNum,
          officeId: officeId,
        );
        if (isDuplicate) {
          throw AppFailure.duplicateAppNumber();
        }
      }

      // ৪. ACID ট্রানজ্যাকশন: আবেদন তৈরি + অবস্থা হিস্টোরি + প্রাথমিক জমা
      final appId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      final appDateMs = applicationDate?.millisecondsSinceEpoch ?? now;
      final cleanPortalPhone = portalPhone?.trim();
      if (cleanPortalPhone != null &&
          cleanPortalPhone.isNotEmpty &&
          !AppValidators.isValidPhone(cleanPortalPhone)) {
        throw AppFailure.invalidPhone();
      }
      final cleanPortalPassword = portalPassword?.trim();

      await _db.transaction(() async {
        // আবেদন ইনসার্ট
        await _db.applicationDao.insertApplication(
          ApplicationsCompanion.insert(
            id: appId,
            applicantId: Value(applicantId),
            applicantName: finalName,
            applicantPhone: finalPhone,
            applicantAddress: Value(finalAddress),
            referenceId: Value(referenceId),
            referenceName: Value(finalRefName),
            officeId: Value(officeId),
            officeName: finalOfficeName,
            mouza: Value(mouza?.trim()),
            appNumber: Value(cleanAppNum),
            caseNumber: Value(CaseNumberFormatter.normalizeIfStructured(caseNumber)),
            workType: cleanWorkType,
            applicationDate: appDateMs,
            status: status,
            agreedAmount: agreedAmountPaisa,
            isMarkedAsPaid: const Value(0),
            portalPhone: Value(
              cleanPortalPhone != null && cleanPortalPhone.isNotEmpty
                  ? AppValidators.standardizePhone(cleanPortalPhone)
                  : null,
            ),
            portalPassword: Value(
              cleanPortalPassword != null && cleanPortalPassword.isNotEmpty
                  ? cleanPortalPassword
                  : null,
            ),
            notes: Value(notes?.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // প্রাথমিক অবস্থা পরিবর্তন হিস্টোরি লগ
        await _db.applicationDao.insertStatusHistory(
          StatusHistoryCompanion.insert(
            id: _uuid.v4(),
            applicationId: appId,
            prevStatus: const Value(null),
            newStatus: status,
            changedAt: now,
            note: const Value('আবেদন তৈরি করা হয়েছে'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // যদি প্রাথমিক জমা দেওয়া হয়ে থাকে
        if (initialPaymentPaisa != null && initialPaymentPaisa > 0) {
          await _db.financeDao.insertPayment(
            PaymentsCompanion.insert(
              id: _uuid.v4(),
              applicationId: appId,
              amount: initialPaymentPaisa,
              date: now,
              method: initialPaymentMethod.trim().isNotEmpty
                  ? initialPaymentMethod.trim()
                  : 'নগদ',
              note: const Value('আবেদন তৈরির প্রাথমিক জমা'),
              isStatusFee: const Value(0),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });

      final created = await _db.applicationDao.getApplicationById(appId);
      return created!;
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// আবেদনের সার্বিক তথ্য হালনাগাদ
  Future<void> updateApplication({
    required String id,
    String? applicantName,
    String? applicantPhone,
    String? applicantAddress,
    String? referenceId,
    String? referenceName,
    String? officeId,
    String? officeName,
    String? mouza,
    String? appNumber,
    String? caseNumber,
    int? agreedAmountPaisa,
    String? portalPhone,
    String? portalPassword,
    bool updatePortalCredentials = false,
    String? notes,
  }) async {
    try {
      final existing = await _db.applicationDao.getApplicationById(id);
      if (existing == null) {
        throw AppFailure.custom('আবেদনটি খুঁজে পাওয়া যায়নি।');
      }

      final cleanName = applicantName?.trim();
      if (cleanName != null && cleanName.isEmpty) {
        throw AppFailure.requiredField('আবেদনকারীর নাম');
      }

      final cleanPhone = applicantPhone != null
          ? AppValidators.standardizePhone(applicantPhone)
          : null;
      if (cleanPhone != null && !AppValidators.isValidPhone(cleanPhone)) {
        throw AppFailure.invalidPhone();
      }

      if (agreedAmountPaisa != null && agreedAmountPaisa <= 0) {
        throw AppFailure.invalidAmount('চুক্তির টাকা শূন্যর বেশি হতে হবে।');
      }

      final cleanAppNum = appNumber?.trim();
      final effectiveOfficeId = officeId ?? existing.officeId;
      if (cleanAppNum != null &&
          cleanAppNum.isNotEmpty &&
          cleanAppNum != existing.appNumber) {
        final isDuplicate = await _db.applicationDao.isDuplicateAppNumber(
          cleanAppNum,
          excludeId: id,
          officeId: effectiveOfficeId,
        );
        if (isDuplicate) {
          throw AppFailure.duplicateAppNumber();
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final trimmedCase = CaseNumberFormatter.normalizeIfStructured(caseNumber);
      final hadNoCaseBefore =
          existing.caseNumber == null || existing.caseNumber!.trim().isEmpty;
      final hasCaseNow = trimmedCase != null && trimmedCase.isNotEmpty;

      final cleanPortalPhone = portalPhone?.trim();
      if (updatePortalCredentials &&
          cleanPortalPhone != null &&
          cleanPortalPhone.isNotEmpty &&
          !AppValidators.isValidPhone(cleanPortalPhone)) {
        throw AppFailure.invalidPhone();
      }
      final resolvedPortalPhone = updatePortalCredentials
          ? (cleanPortalPhone != null && cleanPortalPhone.isNotEmpty
              ? AppValidators.standardizePhone(cleanPortalPhone)
              : null)
          : existing.portalPhone;
      final cleanPortalPass = portalPassword?.trim();
      final resolvedPortalPass = updatePortalCredentials
          ? (cleanPortalPass != null && cleanPortalPass.isNotEmpty
              ? cleanPortalPass
              : null)
          : existing.portalPassword;

      await _db.transaction(() async {
        await _db.applicationDao.updateApplication(
          existing.toCompanion(true).copyWith(
            applicantName: Value(cleanName ?? existing.applicantName),
            applicantPhone: Value(cleanPhone ?? existing.applicantPhone),
            applicantAddress:
                Value(applicantAddress?.trim() ?? existing.applicantAddress),
            referenceId: Value(referenceId ?? existing.referenceId),
            referenceName:
                Value(referenceName?.trim() ?? existing.referenceName),
            officeId: Value(officeId ?? existing.officeId),
            officeName: Value(officeName?.trim() ?? existing.officeName),
            mouza: Value(mouza?.trim() ?? existing.mouza),
            appNumber: Value(cleanAppNum ?? existing.appNumber),
            caseNumber: Value(trimmedCase ?? existing.caseNumber),
            agreedAmount: Value(agreedAmountPaisa ?? existing.agreedAmount),
            portalPhone: Value(resolvedPortalPhone),
            portalPassword: Value(resolvedPortalPass),
            notes: Value(notes?.trim() ?? existing.notes),
            updatedAt: Value(now),
          ),
        );

        // কেস নম্বর ছাড়াই আগে প্রিন্ট হয়ে থাকলে, নতুন কেস নম্বর বসানোর পর
        // আবার 'প্রিন্ট বাকি' তালিকায় নিয়ে আসা।
        if (existing.status == 'প্রস্তাব প্রেরণ' &&
            hadNoCaseBefore &&
            hasCaseNow) {
          await _db.proposalPrintDao.requeueIfPrintedWithoutCaseNumber(id);
        }
      });
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// পর্যায়ক্রমিক অবস্থা পরিবর্তন (Atomic Status Transition Workflow)
  ///
  /// একক ACID ট্রানজ্যাকশনে:
  /// ১. অবস্থা আপডেট
  /// ২. অবস্থা হিস্টোরি সংরক্ষণ
  /// ৩. সরকারি ফি/কাজের খরচ সংরক্ষণ (যদি থাকে)
  /// ৪. ধাপ ফি আদায় (যদি থাকে)
  /// ৫. শুনানির টাস্ক শিডিউল (যদি থাকে)
  Future<void> transitionStatus({
    required String applicationId,
    required String newStatus,
    String? note,
    int? feeExpensePaisa,
    String? feeExpenseCategory,
    int? paymentReceivedPaisa,
    String paymentMethod = 'নগদ',
    String? hearingTaskTitle,
    DateTime? hearingTaskDueDate,
    String? hearingTaskPriority,
  }) async {
    try {
      final app = await _db.applicationDao.getApplicationById(applicationId);
      if (app == null) {
        throw AppFailure.custom('আবেদনটি খুঁজে পাওয়া যায়নি।');
      }

      final prevStatus = app.status;
      final now = DateTime.now().millisecondsSinceEpoch;
      final statusHistoryId = _uuid.v4();

      await _db.transaction(() async {
        // ১. আবেদন টেবিল অবস্থা আপডেট
        await (_db.update(_db.applications)
              ..where((tbl) => tbl.id.equals(applicationId)))
            .write(
          ApplicationsCompanion(
            status: Value(newStatus),
            updatedAt: Value(now),
          ),
        );

        // ২. অবস্থা পরিবর্তন হিস্টোরি রেকর্ড
        await _db.applicationDao.insertStatusHistory(
          StatusHistoryCompanion.insert(
            id: statusHistoryId,
            applicationId: applicationId,
            prevStatus: Value(prevStatus),
            newStatus: newStatus,
            changedAt: now,
            note: Value(note?.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // ৩. সরকারি ফি বা কাজের খরচ যোগ (আবেদন সংশ্লিষ্ট খরচ)
        if (feeExpensePaisa != null && feeExpensePaisa > 0) {
          await _db.financeDao.insertExpense(
            ExpensesCompanion.insert(
              id: _uuid.v4(),
              applicationId: Value(applicationId),
              amount: feeExpensePaisa,
              category: feeExpenseCategory?.trim().isNotEmpty == true
                  ? feeExpenseCategory!.trim()
                  : 'সরকারি ফি',
              date: now,
              isGeneral: const Value(0),
              statusHistoryId: Value(statusHistoryId),
              statusName: Value(newStatus),
              isStatusExp: const Value(1),
              note: Value(note?.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }

        // ৪. এই ধাপে টাকা আদায় হলে
        if (paymentReceivedPaisa != null && paymentReceivedPaisa > 0) {
          await _db.financeDao.insertPayment(
            PaymentsCompanion.insert(
              id: _uuid.v4(),
              applicationId: applicationId,
              amount: paymentReceivedPaisa,
              date: now,
              method: paymentMethod.trim().isNotEmpty ? paymentMethod.trim() : 'নগদ',
              statusHistoryId: Value(statusHistoryId),
              statusName: Value(newStatus),
              isStatusFee: const Value(1),
              note: Value(note?.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }

        // ৫. স্বয়ংক্রিয় শুনানির টাস্ক তৈরি
        if (hearingTaskTitle != null && hearingTaskTitle.trim().isNotEmpty) {
          final dueMs = hearingTaskDueDate?.millisecondsSinceEpoch ??
              now + const Duration(days: 7).inMilliseconds;
          await _db.taskDao.insertTask(
            TasksCompanion.insert(
              id: _uuid.v4(),
              title: hearingTaskTitle.trim(),
              dueDate: dueMs,
              priority: Value(hearingTaskPriority ?? 'জরুরি'),
              category: const Value('শুনানি'),
              status: const Value('করতে হবে'),
              applicationId: Value(applicationId),
              description: Value('ধাপ পরিবর্তন: $newStatus'),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// বকেয়া মওকুফ ও নিষ্পত্তি চিহ্নিতকরণ ('Mark as Paid')
  Future<void> markAsPaid(String id, bool paid) async {
    try {
      await _db.applicationDao.markAsPaid(id, paid);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// আবেদন সফট ডিলিট (ক্যাশবই অডিট ট্রেইল ও রিলেশনশিপ অক্ষত রেখে)
  Future<void> deleteApplication(String id) async {
    try {
      await _db.applicationDao.softDeleteApplication(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// সফট ডিলিট আবেদন পুনরুদ্ধার (Undo / Restore)
  Future<void> restoreApplication(String id) async {
    try {
      await _db.applicationDao.restoreApplication(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// অবস্থা পরিবর্তনের ইতিহাস সংগ্রহ (Future)
  Future<List<StatusHistoryData>> getStatusHistory(String applicationId) async {
    try {
      return await _db.applicationDao.getStatusHistory(applicationId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// অবস্থা পরিবর্তনের ইতিহাস ওয়াচ
  Stream<List<StatusHistoryData>> watchStatusHistory(String applicationId) {
    return _db.applicationDao.watchStatusHistory(applicationId);
  }

  /// প্রতিটি অবস্থার সক্রিয় আবেদন সংখ্যা
  Future<Map<String, int>> countByStatus() async {
    try {
      return await _db.applicationDao.countByStatus();
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// আবেদন সংক্রান্ত সকল সক্রিয় ডকুমেন্ট ওয়াচ
  Stream<List<Document>> watchDocuments(String applicationId) {
    return _db.applicationDao.watchDocuments(applicationId);
  }

  /// আবেদন সংক্রান্ত সকল সক্রিয় ডকুমেন্ট সংগ্রহ
  Future<List<Document>> getDocuments(String applicationId) async {
    try {
      return await _db.applicationDao.getDocuments(applicationId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নতুন ডকুমেন্ট সংযোজন
  Future<Document> addDocument({
    String? id,
    required String applicationId,
    required String fileName,
    required String fileType,
    required Uint8List fileData,
    required String fileSize,
  }) async {
    try {
      final docId = id ?? _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.applicationDao.insertDocument(
        DocumentsCompanion.insert(
          id: docId,
          applicationId: applicationId,
          fileName: fileName,
          fileType: fileType,
          fileData: fileData,
          fileSize: fileSize,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final docs = await _db.applicationDao.getDocuments(applicationId);
      return docs.firstWhere((d) => d.id == docId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// ডকুমেন্ট হার্ড ডিলিট (Physical DELETE — মেমোরি খালি করতে ডেটাবেজ থেকে সম্পূর্ণ মুছে ফেলা)
  Future<void> deleteDocument(String id) async {
    try {
      await _db.applicationDao.deleteDocument(id);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }
}
