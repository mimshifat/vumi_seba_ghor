import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';
import '../../domain/models/proposal_print_models.dart';

/// এখনো প্রিন্ট/জমা হয়নি এমন 'প্রস্তাব প্রেরণ' আবেদনসমূহের রিয়েক্টিভ স্ট্রিম।
final pendingProposalCandidatesStreamProvider =
    StreamProvider<List<PendingProposalCandidate>>((ref) {
  final repo = ref.watch(proposalPrintRepositoryProvider);
  return repo.watchPendingProposals();
});

/// পূর্বে প্রিন্ট/জমা হওয়া ব্যাচগুলোর রিয়েক্টিভ স্ট্রিম।
final printedProposalBatchesStreamProvider =
    StreamProvider<List<ProposalBatchWithItems>>((ref) {
  final repo = ref.watch(proposalPrintRepositoryProvider);
  return repo.watchPrintedBatches();
});

/// প্রস্তাব প্রেরণ প্রিন্ট ব্যাচ মিউটেশন কন্ট্রোলার।
class ProposalPrintController extends MutationController {
  final ProposalPrintRepository _repo;
  final Ref? _ref;

  ProposalPrintController(this._repo, [this._ref]);

  void _invalidate() {
    _ref?.invalidate(pendingProposalCandidatesStreamProvider);
    _ref?.invalidate(printedProposalBatchesStreamProvider);
  }

  /// নির্বাচিত আবেদনগুলোকে প্রিন্ট/জমা সম্পন্ন ব্যাচ হিসেবে সংরক্ষণ করা।
  Future<String?> createPrintBatch({
    required List<PendingProposalCandidate> candidates,
    String? title,
    String? officeFilter,
    String? note,
  }) async {
    final batchId = await execute(() => _repo.createPrintBatch(
          candidates: candidates,
          title: title,
          officeFilter: officeFilter,
          note: note,
        ));
    if (batchId != null) {
      _invalidate();
    }
    return batchId;
  }

  /// একটি ব্যাচ থেকে নির্দিষ্ট আইটেম আনমার্ক করে পুনরায় 'প্রিন্ট বাকি' তালিকায় পাঠানো।
  Future<void> unmarkItem(String itemId) async {
    await execute(() => _repo.unmarkItem(itemId));
    _invalidate();
  }

  /// সম্পূর্ণ একটি ব্যাচ আনমার্ক করে সব কেস পুনরায় 'প্রিন্ট বাকি' তালিকায় পাঠানো।
  Future<void> unmarkBatch(String batchId) async {
    await execute(() => _repo.unmarkBatch(batchId));
    _invalidate();
  }
}

/// প্রস্তাব প্রেরণ প্রিন্ট কন্ট্রোলার প্রোভাইডার।
final proposalPrintControllerProvider =
    StateNotifierProvider<ProposalPrintController, AsyncValue<void>>((ref) {
  final repo = ref.watch(proposalPrintRepositoryProvider);
  return ProposalPrintController(repo, ref);
});

