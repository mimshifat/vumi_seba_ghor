import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/models/proposal_print_models.dart';

/// 'প্রস্তাব প্রেরণ' PDF প্রিন্ট ও জমা ব্যাচ ব্যবস্থাপনা রিপোজিটরি।
class ProposalPrintRepository {
  final AppDatabase _db;
  final Uuid _uuid;

  ProposalPrintRepository(this._db, [Uuid? uuid])
      : _uuid = uuid ?? const Uuid();

  /// এখনো প্রিন্ট/জমা হয়নি এমন 'প্রস্তাব প্রেরণ' আবেদনসমূহের স্ট্রিম।
  Stream<List<PendingProposalCandidate>> watchPendingProposals() {
    return _db.proposalPrintDao.watchPendingProposals();
  }

  /// এখনো প্রিন্ট/জমা হয়নি এমন 'প্রস্তাব প্রেরণ' আবেদনসমূহের তালিকা।
  Future<List<PendingProposalCandidate>> getPendingProposals() async {
    try {
      return await _db.proposalPrintDao.getPendingProposals();
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// পূর্বে প্রিন্ট/জমা হওয়া ব্যাচগুলোর স্ট্রিম।
  Stream<List<ProposalBatchWithItems>> watchPrintedBatches() {
    return _db.proposalPrintDao.watchPrintedBatches();
  }

  /// পূর্বে প্রিন্ট/জমা হওয়া ব্যাচগুলোর তালিকা।
  Future<List<ProposalBatchWithItems>> getPrintedBatches() async {
    try {
      return await _db.proposalPrintDao.getPrintedBatches();
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// নির্বাচিত আবেদনগুলোকে একটি প্রিন্ট/জমা ব্যাচ হিসেবে সংরক্ষণ করা।
  ///
  /// একক ট্রানজ্যাকশনের ভেতরে:
  /// ১. প্রতিটি আবেদন সক্রিয় ও 'প্রস্তাব প্রেরণ' অবস্থায় আছে কিনা পুনরায় যাচাই।
  /// ২. ইতিমধ্যে প্রিন্টেড বা ডুপ্লিকেট আবেদন বাদ দেওয়া।
  /// ৩. সর্বশেষ স্ন্যাপশটসহ ব্যাচ ও আইটেম সংরক্ষণ।
  Future<String> createPrintBatch({
    required List<PendingProposalCandidate> candidates,
    String? title,
    String? officeFilter,
    String? note,
  }) async {
    if (candidates.isEmpty) {
      throw AppFailure.custom('অন্তত একটি আবেদন নির্বাচন করুন।');
    }

    try {
      return await _db.transaction(() async {
        final now = DateTime.now().millisecondsSinceEpoch;
        final batchId = _uuid.v4();
        final seenAppIds = <String>{};
        final itemCompanions = <ProposalPrintBatchItemsCompanion>[];

        for (final candidate in candidates) {
          final appId = candidate.application.id;
          if (!seenAppIds.add(appId)) continue;

          // ডেটাবেজ থেকে সর্বশেষ অবস্থা যাচাই (stale selection সুরক্ষা)
          final freshApp = await _db.applicationDao.getApplicationById(appId);
          if (freshApp == null || freshApp.status != 'প্রস্তাব প্রেরণ') {
            continue;
          }

          final latestShId = await _db.proposalPrintDao
              .getLatestProposalEntryHistoryId(appId);
          final alreadyPrinted = await _db.proposalPrintDao
              .isAlreadyPrintedForEntry(appId, latestShId);
          if (alreadyPrinted) {
            continue;
          }

          final trimmedCase = freshApp.caseNumber?.trim();
          itemCompanions.add(
            ProposalPrintBatchItemsCompanion.insert(
              id: _uuid.v4(),
              batchId: batchId,
              applicationId: freshApp.id,
              statusHistoryId: Value(latestShId),
              applicantNameSnapshot: freshApp.applicantName,
              caseNumberSnapshot: Value(
                trimmedCase != null && trimmedCase.isNotEmpty
                    ? trimmedCase
                    : null,
              ),
              officeNameSnapshot: Value(freshApp.officeName),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }

        if (itemCompanions.isEmpty) {
          throw AppFailure.custom(
            'নির্বাচিত কেসগুলোর অবস্থা পরিবর্তিত হয়েছে অথবা ইতিমধ্যে প্রিন্ট সম্পন্ন হয়েছে।',
          );
        }

        final cleanOffice =
            officeFilter != null && officeFilter.trim().isNotEmpty
                ? officeFilter.trim()
                : null;
        final cleanTitle = (title != null && title.trim().isNotEmpty)
            ? title.trim()
            : (cleanOffice != null
                ? '$cleanOffice — প্রস্তাব প্রেরণ'
                : 'প্রস্তাব প্রেরণ তালিকা');

        final batchCompanion = ProposalPrintBatchesCompanion.insert(
          id: batchId,
          title: Value(cleanTitle),
          officeFilter: Value(cleanOffice),
          printedAt: now,
          itemCount: itemCompanions.length,
          note: Value(note?.trim().isNotEmpty == true ? note!.trim() : null),
          createdAt: now,
          updatedAt: now,
        );

        await _db.proposalPrintDao.insertBatchWithItems(
          batch: batchCompanion,
          items: itemCompanions,
        );
        return batchId;
      });
    } catch (e, s) {
      if (e is AppFailure) rethrow;
      throw AppFailure.fromException(e, s);
    }
  }

  /// একটি ব্যাচের নির্দিষ্ট আইটেমকে আবার 'প্রিন্ট বাকি' তালিকায় ফেরত পাঠানো।
  Future<void> unmarkItem(String itemId) async {
    try {
      await _db.proposalPrintDao.softDeleteBatchItem(itemId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }

  /// সম্পূর্ণ একটি ব্যাচকে আনমার্ক করে সব কেস আবার 'প্রিন্ট বাকি' তালিকায় ফেরত পাঠানো।
  Future<void> unmarkBatch(String batchId) async {
    try {
      await _db.proposalPrintDao.softDeleteBatch(batchId);
    } catch (e, s) {
      throw AppFailure.fromException(e, s);
    }
  }
}
