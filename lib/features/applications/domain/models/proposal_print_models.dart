import '../../../../core/database/app_database.dart';

/// 'প্রস্তাব প্রেরণ' অবস্থায় থাকা কিন্তু এখনো প্রিন্ট/জমা না হওয়া আবেদন।
class PendingProposalCandidate {
  final Application application;
  final String? statusHistoryId;
  final int statusEnteredAt;

  const PendingProposalCandidate({
    required this.application,
    required this.statusHistoryId,
    required this.statusEnteredAt,
  });

  ProposalPrintRow toPdfRow() {
    return ProposalPrintRow(
      applicantName: application.applicantName,
      caseNumber: application.caseNumber,
      officeName: application.officeName,
    );
  }
}

/// পূর্বে প্রিন্ট/জমা হওয়া একটি ব্যাচ ও তার ভেতরের কেসসমূহ।
class ProposalBatchWithItems {
  final ProposalPrintBatch batch;
  final List<ProposalPrintBatchItem> items;

  const ProposalBatchWithItems({
    required this.batch,
    required this.items,
  });

  List<ProposalPrintRow> toPdfRows() {
    return items
        .map(
          (item) => ProposalPrintRow(
            applicantName: item.applicantNameSnapshot,
            caseNumber: item.caseNumberSnapshot,
            officeName: item.officeNameSnapshot,
          ),
        )
        .toList();
  }
}

/// PDF তালিকার একটি সারি — আবেদনকারীর নাম ও কেস নম্বর।
class ProposalPrintRow {
  final String applicantName;
  final String? caseNumber;
  final String? officeName;

  const ProposalPrintRow({
    required this.applicantName,
    this.caseNumber,
    this.officeName,
  });
}

