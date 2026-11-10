import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/repository_providers.dart';
import '../../../../core/providers/mutation_controller.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/filter_bottom_sheet.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../domain/models/application_with_financials.dart';
import 'proposal_print_providers.dart';

/// আবেদনের সার্চ ও ফিল্টারিং স্টেট (Search & Filter Criteria State)
class ApplicationFilterState {
  final String searchQuery;
  final String? quickFilterKey; // 'all', 'ongoing', 'hearing', 'has_due', 'completed', or specific status name
  final String? selectedStatus;
  final String? selectedWorkType;
  final String? selectedOffice;
  final String? selectedMouza;
  final String dueStatus; // 'all', 'has_due', 'paid'
  final String sortBy; // 'newest', 'oldest', 'due_desc', 'name_asc', 'agreed_desc'

  const ApplicationFilterState({
    this.searchQuery = '',
    this.quickFilterKey = 'all',
    this.selectedStatus,
    this.selectedWorkType,
    this.selectedOffice,
    this.selectedMouza,
    this.dueStatus = 'all',
    this.sortBy = 'newest',
  });

  bool get hasActiveFilters {
    return (quickFilterKey != null && quickFilterKey != 'all') ||
        selectedStatus != null ||
        selectedWorkType != null ||
        selectedOffice != null ||
        selectedMouza != null ||
        dueStatus != 'all' ||
        searchQuery.isNotEmpty ||
        sortBy != 'newest';
  }

  ApplicationFilterState copyWith({
    String? searchQuery,
    String? quickFilterKey,
    String? selectedStatus,
    String? selectedWorkType,
    String? selectedOffice,
    String? selectedMouza,
    String? dueStatus,
    String? sortBy,
    bool clearStatus = false,
    bool clearWorkType = false,
    bool clearOffice = false,
    bool clearMouza = false,
  }) {
    return ApplicationFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      quickFilterKey: quickFilterKey ?? this.quickFilterKey,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedWorkType:
          clearWorkType ? null : (selectedWorkType ?? this.selectedWorkType),
      selectedOffice: clearOffice ? null : (selectedOffice ?? this.selectedOffice),
      selectedMouza: clearMouza ? null : (selectedMouza ?? this.selectedMouza),
      dueStatus: dueStatus ?? this.dueStatus,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// ফিল্টার স্টেট কন্ট্রোলার
class ApplicationFilterNotifier extends StateNotifier<ApplicationFilterState> {
  ApplicationFilterNotifier() : super(const ApplicationFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  void setQuickFilterKey(String? key) {
    state = state.copyWith(quickFilterKey: key ?? 'all');
  }

  void setSelectedStatus(String? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
  }

  void setSelectedWorkType(String? workType) {
    if (workType == null) {
      state = state.copyWith(clearWorkType: true);
    } else {
      state = state.copyWith(selectedWorkType: workType);
    }
  }

  void setSelectedOffice(String? office) {
    if (office == null) {
      state = state.copyWith(clearOffice: true);
    } else {
      state = state.copyWith(selectedOffice: office);
    }
  }

  void setSelectedMouza(String? mouza) {
    if (mouza == null) {
      state = state.copyWith(clearMouza: true);
    } else {
      state = state.copyWith(selectedMouza: mouza);
    }
  }

  void setDueStatus(String dueStatus) {
    state = state.copyWith(dueStatus: dueStatus);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void setCriteria(FilterCriteria criteria) {
    state = state.copyWith(
      selectedStatus: criteria.selectedStatus,
      selectedWorkType: criteria.selectedWorkType,
      selectedOffice: criteria.selectedOffice,
      dueStatus: criteria.dueStatus,
      sortBy: criteria.sortBy,
      clearStatus: criteria.selectedStatus == null,
      clearWorkType: criteria.selectedWorkType == null,
      clearOffice: criteria.selectedOffice == null,
    );
  }

  void clearFilters() {
    state = const ApplicationFilterState();
  }
}

/// আবেদনের ফিল্টার প্রোভাইডার
final applicationFilterProvider =
    StateNotifierProvider<ApplicationFilterNotifier, ApplicationFilterState>(
  (ref) => ApplicationFilterNotifier(),
);

/// ডেটাবেজ থেকে রিয়েলটাইম সমস্ত সক্রিয় আবেদন স্ট্রিম
final applicationsWithFinancialsStreamProvider =
    StreamProvider<List<ApplicationWithFinancials>>((ref) {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo.watchApplicationsWithFinancials();
});

/// ফিল্টারিং ও সার্চসহ সাজানো আবেদনের তালিকা প্রদানকারী
final filteredApplicationsProvider =
    Provider<List<ApplicationWithFinancials>>((ref) {
  final asyncApps = ref.watch(applicationsWithFinancialsStreamProvider);
  final filter = ref.watch(applicationFilterProvider);

  return asyncApps.when(
    data: (apps) {
      return apps.where((item) {
        final app = item.application;

        // ১. সার্চ কুয়েরি ফিল্টার (বাংলা ও ইংরেজি টলারেন্ট)
        if (filter.searchQuery.isNotEmpty) {
          final q = filter.searchQuery.toLowerCase();
          final enQ = BengaliDigits.toEnglish(q);
          final bnQ = BengaliDigits.toBengali(q);

          final nameMatch = app.applicantName.toLowerCase().contains(q);
          final phoneMatch = app.applicantPhone.contains(enQ) ||
              app.applicantPhone.contains(bnQ) ||
              app.applicantPhone.contains(q);
          final appNumMatch = app.appNumber != null &&
              (app.appNumber!.toLowerCase().contains(q) ||
                  app.appNumber!.contains(enQ));
          final caseNumMatch = app.caseNumber != null &&
              (app.caseNumber!.toLowerCase().contains(q) ||
                  app.caseNumber!.contains(enQ) ||
                  app.caseNumber!.contains(bnQ));
          final mouzaMatch =
              app.mouza != null && app.mouza!.toLowerCase().contains(q);

          if (!nameMatch &&
              !phoneMatch &&
              !appNumMatch &&
              !caseNumMatch &&
              !mouzaMatch) {
            return false;
          }
        }

        // ২. কুইক ফিল্টার চিপস
        if (filter.quickFilterKey != null && filter.quickFilterKey != 'all') {
          final k = filter.quickFilterKey!;
          if (k == 'ongoing') {
            if (app.status == 'সম্পন্ন' ||
                app.status == 'নামঞ্জুর' ||
                app.status == 'বাতিল') {
              return false;
            }
          } else if (k == 'has_due') {
            if (!item.effectiveDue.isPositive) return false;
          } else if (k == 'hearing') {
            if (app.status != 'শুনানি') return false;
          } else if (k == 'completed') {
            if (app.status != 'সম্পন্ন') return false;
          } else {
            if (app.status != k) return false;
          }
        }

        // ৩. বটমশীট থেকে নির্ধারিত ফিল্টার ক্রাইটেরিয়া
        if (filter.selectedStatus != null && filter.selectedStatus!.isNotEmpty) {
          if (app.status != filter.selectedStatus) return false;
        }

        if (filter.selectedWorkType != null &&
            filter.selectedWorkType!.isNotEmpty) {
          if (app.workType != filter.selectedWorkType) return false;
        }

        if (filter.selectedOffice != null && filter.selectedOffice!.isNotEmpty) {
          if (app.officeName != filter.selectedOffice) return false;
        }

        if (filter.selectedMouza != null && filter.selectedMouza!.isNotEmpty) {
          if (app.mouza != filter.selectedMouza) return false;
        }

        // ৪. বকেয়া ফিল্টার
        if (filter.dueStatus == 'has_due') {
          if (!item.effectiveDue.isPositive) return false;
        } else if (filter.dueStatus == 'paid') {
          if (item.effectiveDue.isPositive) return false;
        }

        return true;
      }).toList()
        ..sort((a, b) {
          // ৫. সর্টিং
          switch (filter.sortBy) {
            case 'oldest':
              return a.application.applicationDate
                  .compareTo(b.application.applicationDate);
            case 'due_desc':
              return b.effectiveDue.compareTo(a.effectiveDue);
            case 'name_asc':
              return a.application.applicantName
                  .compareTo(b.application.applicantName);
            case 'agreed_desc':
              return b.application.agreedAmount
                  .compareTo(a.application.agreedAmount);
            case 'newest':
            default:
              return b.application.applicationDate
                  .compareTo(a.application.applicationDate);
          }
        });
    },
    loading: () => const [],
    error: (_, __) => const [],
  );
});

/// প্রতিটি অবস্থার আবেদন কাউন্ট
final applicationStatusCountsProvider =
    FutureProvider<Map<String, int>>((ref) {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo.countByStatus();
});

/// নির্দিষ্ট একক আবেদনের রিয়েক্টিভ ওয়াচ
final applicationDetailProvider =
    StreamProvider.family<Application?, String>((ref, id) {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo.watchApplication(id);
});

/// নির্দিষ্ট একক আবেদনের সম্পূর্ণ আর্থিক হিসেবসহ সংগ্রহ
final applicationWithFinancialsDetailProvider =
    FutureProvider.family<ApplicationWithFinancials?, String>((ref, id) {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo.getApplicationWithFinancials(id);
});

/// নির্দিষ্ট আবেদনের অবস্থা রূপান্তর হিস্টোরি
final applicationStatusHistoryProvider =
    StreamProvider.family<List<StatusHistoryData>, String>((ref, applicationId) {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo.watchStatusHistory(applicationId);
});

/// নির্দিষ্ট আবেদনের সকল ডকুমেন্ট ওয়াচ
final applicationDocumentsProvider =
    StreamProvider.family<List<Document>, String>((ref, applicationId) {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo.watchDocuments(applicationId);
});

/// আবেদন সংক্রান্ত সকল মিউটেশন ও অ্যাকশন কন্ট্রোলার (ডাবল-ট্যাপ ও সেফটি লক সহ)
class ApplicationController extends MutationController {
  final ApplicationRepository _repo;
  final Ref? _ref;

  ApplicationController(this._repo, [this._ref]);

  void _invalidateAll() {
    if (_ref != null) {
      _ref.invalidate(applicationsWithFinancialsStreamProvider);
      _ref.invalidate(allUnifiedTransactionsStreamProvider);
      _ref.invalidate(financialOverviewProvider);
      _ref.invalidate(todayFinancialSnapshotProvider);
      _ref.invalidate(thisMonthFinancialSnapshotProvider);
      _ref.invalidate(pendingProposalCandidatesStreamProvider);
      _ref.invalidate(printedProposalBatchesStreamProvider);
    }
  }

  /// নতুন আবেদন তৈরি
  Future<Application?> createApplication({
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
    final res = await execute(() => _repo.createApplication(
          id: id,
          applicantId: applicantId,
          applicantName: applicantName,
          applicantPhone: applicantPhone,
          applicantAddress: applicantAddress,
          referenceId: referenceId,
          referenceName: referenceName,
          officeId: officeId,
          officeName: officeName,
          mouza: mouza,
          appNumber: appNumber,
          caseNumber: caseNumber,
          workType: workType,
          applicationDate: applicationDate,
          status: status,
          agreedAmountPaisa: agreedAmountPaisa,
          portalPhone: portalPhone,
          portalPassword: portalPassword,
          notes: notes,
          initialPaymentPaisa: initialPaymentPaisa,
          initialPaymentMethod: initialPaymentMethod,
        ));
    if (res != null) {
      _invalidateAll();
      _ref?.invalidate(applicationStatusCountsProvider);
    }
    return res;
  }

  /// আবেদন আপডেট
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
    await execute(() => _repo.updateApplication(
          id: id,
          applicantName: applicantName,
          applicantPhone: applicantPhone,
          applicantAddress: applicantAddress,
          referenceId: referenceId,
          referenceName: referenceName,
          officeId: officeId,
          officeName: officeName,
          mouza: mouza,
          appNumber: appNumber,
          caseNumber: caseNumber,
          agreedAmountPaisa: agreedAmountPaisa,
          portalPhone: portalPhone,
          portalPassword: portalPassword,
          updatePortalCredentials: updatePortalCredentials,
          notes: notes,
        ));
    _invalidateAll();
    _ref?.invalidate(applicationDetailProvider(id));
    _ref?.invalidate(applicationWithFinancialsDetailProvider(id));
  }

  /// পর্যায়ক্রমিক অবস্থা রূপান্তর (একক ট্রানজ্যাকশন)
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
    await execute(() => _repo.transitionStatus(
          applicationId: applicationId,
          newStatus: newStatus,
          note: note,
          feeExpensePaisa: feeExpensePaisa,
          feeExpenseCategory: feeExpenseCategory,
          paymentReceivedPaisa: paymentReceivedPaisa,
          paymentMethod: paymentMethod,
          hearingTaskTitle: hearingTaskTitle,
          hearingTaskDueDate: hearingTaskDueDate,
          hearingTaskPriority: hearingTaskPriority,
        ));
    _invalidateAll();
    _ref?.invalidate(applicationStatusHistoryProvider(applicationId));
    _ref?.invalidate(applicationDetailProvider(applicationId));
    _ref?.invalidate(applicationWithFinancialsDetailProvider(applicationId));
    _ref?.invalidate(applicationExpensesProvider(applicationId));
    _ref?.invalidate(applicationPaymentsProvider(applicationId));
    _ref?.invalidate(todayTasksCountProvider);
    _ref?.invalidate(tasksStreamProvider);
    _ref?.invalidate(applicationStatusCountsProvider);
  }

  /// বকেয়া মওকুফ ও নিষ্পত্তি চিহ্নিতকরণ
  Future<void> markAsPaid(String id, bool paid) async {
    await execute(() => _repo.markAsPaid(id, paid));
    _invalidateAll();
    _ref?.invalidate(applicationDetailProvider(id));
    _ref?.invalidate(applicationWithFinancialsDetailProvider(id));
  }

  /// আবেদন সফট ডিলিট
  Future<void> deleteApplication(String id) async {
    await execute(() => _repo.deleteApplication(id));
    _invalidateAll();
    _ref?.invalidate(applicationDetailProvider(id));
    _ref?.invalidate(applicationWithFinancialsDetailProvider(id));
    _ref?.invalidate(applicationStatusCountsProvider);
  }

  /// আবেদন পুনরুদ্ধার (Undo / Restore)
  Future<void> restoreApplication(String id) async {
    await execute(() => _repo.restoreApplication(id));
    _invalidateAll();
    _ref?.invalidate(applicationDetailProvider(id));
    _ref?.invalidate(applicationWithFinancialsDetailProvider(id));
    _ref?.invalidate(applicationStatusCountsProvider);
  }

  /// নতুন ডকুমেন্ট সংযোজন
  Future<Document?> addDocument({
    required String applicationId,
    required String fileName,
    required String fileType,
    required Uint8List fileData,
    required String fileSize,
  }) async {
    final res = await execute(() => _repo.addDocument(
          applicationId: applicationId,
          fileName: fileName,
          fileType: fileType,
          fileData: fileData,
          fileSize: fileSize,
        ));
    _ref?.invalidate(applicationDocumentsProvider(applicationId));
    return res;
  }

  /// ডকুমেন্ট মুছে ফেলা
  Future<void> deleteDocument({
    required String documentId,
    required String applicationId,
  }) async {
    await execute(() => _repo.deleteDocument(documentId));
    _ref?.invalidate(applicationDocumentsProvider(applicationId));
  }
}

/// আবেদন মিউটেশন কন্ট্রোলার প্রোভাইডার
final applicationControllerProvider =
    StateNotifierProvider<ApplicationController, AsyncValue<void>>((ref) {
  final repo = ref.watch(applicationRepositoryProvider);
  return ApplicationController(repo, ref);
});

