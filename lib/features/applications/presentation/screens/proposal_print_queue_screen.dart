import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/utils/pdf_letterhead_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/services/proposal_pdf_service.dart';
import '../../domain/models/proposal_print_models.dart';
import '../providers/application_providers.dart';
import '../providers/proposal_print_providers.dart';
import 'application_detail_screen.dart';
import 'proposal_pdf_preview_screen.dart';

enum _ProposalSortMode {
  newest('নতুন আগে'),
  oldest('পুরোনো আগে'),
  caseAsc('কেস নং অনুযায়ী'),
  nameAsc('নাম অনুযায়ী');

  final String label;
  const _ProposalSortMode(this.label);
}

/// 'প্রস্তাব প্রেরণ' স্ট্যাটাসের নতুন ও পূর্বে প্রিন্টকৃত কেস তালিকা ও PDF ব্যবস্থাপনা স্ক্রিন।
class ProposalPrintQueueScreen extends ConsumerStatefulWidget {
  const ProposalPrintQueueScreen({super.key});

  @override
  ConsumerState<ProposalPrintQueueScreen> createState() =>
      _ProposalPrintQueueScreenState();
}

class _ProposalPrintQueueScreenState
    extends ConsumerState<ProposalPrintQueueScreen> {
  String? _selectedOffice; // null = সব অফিস
  _ProposalSortMode _sortMode = _ProposalSortMode.newest;

  /// ব্যবহারকারীর ম্যানুয়াল টিক/আনটিক ওভাররাইড।
  /// ডিফল্টভাবে যেগুলোতে `caseNumber` আছে সেগুলো টিক থাকে এবং যেগুলোতে নেই
  /// সেগুলো আনটিক থাকে — যাতে ভুলবশত কেস নং ছাড়া আবেদন প্রিন্ট না হয়।
  final Map<String, bool> _selectionOverrides = {};
  bool _isGeneratingPdf = false;

  bool _hasCaseNumber(PendingProposalCandidate c) {
    return c.application.caseNumber?.trim().isNotEmpty ?? false;
  }

  bool _isCandidateSelected(PendingProposalCandidate c) {
    return _selectionOverrides[c.application.id] ?? _hasCaseNumber(c);
  }

  List<PendingProposalCandidate> _sortCandidates(
    List<PendingProposalCandidate> input,
  ) {
    final sorted = List<PendingProposalCandidate>.from(input);
    switch (_sortMode) {
      case _ProposalSortMode.newest:
        sorted.sort(
          (a, b) => b.statusEnteredAt.compareTo(a.statusEnteredAt),
        );
      case _ProposalSortMode.oldest:
        sorted.sort(
          (a, b) => a.statusEnteredAt.compareTo(b.statusEnteredAt),
        );
      case _ProposalSortMode.caseAsc:
        sorted.sort((a, b) {
          final ac = BengaliDigits.toEnglish(
            a.application.caseNumber?.trim() ?? '',
          );
          final bc = BengaliDigits.toEnglish(
            b.application.caseNumber?.trim() ?? '',
          );
          if (ac.isEmpty && bc.isEmpty) {
            return b.statusEnteredAt.compareTo(a.statusEnteredAt);
          }
          if (ac.isEmpty) return 1;
          if (bc.isEmpty) return -1;
          return ac.compareTo(bc);
        });
      case _ProposalSortMode.nameAsc:
        sorted.sort(
          (a, b) =>
              a.application.applicantName.compareTo(b.application.applicantName),
        );
    }
    return sorted;
  }

  String _formatDateTime(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final day = BengaliDigits.toBengali(dt.day.toString().padLeft(2, '0'));
    final month = BengaliDigits.toBengali(dt.month.toString().padLeft(2, '0'));
    final year = BengaliDigits.toBengali(dt.year);
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hour = BengaliDigits.toBengali(hour12.toString().padLeft(2, '0'));
    final min = BengaliDigits.toBengali(dt.minute.toString().padLeft(2, '0'));
    final period = dt.hour >= 12 ? 'অপরাহ্ন' : 'পূর্বাহ্ন';
    return '$day/$month/$year • $hour:$min $period';
  }

  PdfShopInfo _resolveShopInfo() {
    final settings = ref.read(shopSettingsStreamProvider).valueOrNull;
    return PdfShopInfo.fromSettings(settings);
  }

  Future<void> _openPendingPdfPreview(
    List<PendingProposalCandidate> selectedCandidates,
  ) async {
    if (selectedCandidates.isEmpty || _isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final now = DateTime.now();
      final shopInfo = _resolveShopInfo();
      final pdfBytes = await ProposalPdfService.buildProposalListPdf(
        rows: selectedCandidates.map((c) => c.toPdfRow()).toList(),
        shopName: shopInfo.shopName,
        proprietorName: shopInfo.proprietorName,
        shopPhone: shopInfo.shopPhone,
        shopAddress: shopInfo.shopAddress,
        officeLabel: _selectedOffice,
        printedAt: now,
      );

      if (!mounted) return;
      setState(() => _isGeneratingPdf = false);

      final dateTag =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      final marked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (ctx) => ProposalPdfPreviewScreen(
            pdfBytes: pdfBytes,
            title: 'প্রস্তাব প্রেরণ PDF প্রিভিউ',
            pdfFileName: 'prostab_preron_$dateTag.pdf',
            itemCount: selectedCandidates.length,
            isPendingBatch: true,
            onMarkAsPrinted: () async {
              final batchId = await ref
                  .read(proposalPrintControllerProvider.notifier)
                  .createPrintBatch(
                    candidates: selectedCandidates,
                    officeFilter: _selectedOffice,
                  );
              if (batchId == null) {
                final err = ref.read(proposalPrintControllerProvider).error;
                throw err ?? Exception('ব্যাচ সংরক্ষণ ব্যর্থ হয়েছে।');
              }
            },
          ),
        ),
      );

      if (!mounted) return;
      if (marked == true) {
        setState(() {
          for (final c in selectedCandidates) {
            _selectionOverrides.remove(c.application.id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${BengaliDigits.toBengali(selectedCandidates.length)} টি কেস প্রিন্ট/জমা সম্পন্ন হিসেবে সংরক্ষিত হয়েছে।',
            ),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF তৈরি করতে সমস্যা হয়েছে: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Future<void> _reprintBatch(ProposalBatchWithItems batchWithItems) async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final shopInfo = _resolveShopInfo();
      final printedDate =
          DateTime.fromMillisecondsSinceEpoch(batchWithItems.batch.printedAt);
      final pdfBytes = await ProposalPdfService.buildProposalListPdf(
        rows: batchWithItems.toPdfRows(),
        shopName: shopInfo.shopName,
        proprietorName: shopInfo.proprietorName,
        shopPhone: shopInfo.shopPhone,
        shopAddress: shopInfo.shopAddress,
        title: batchWithItems.batch.title ?? 'প্রস্তাব প্রেরণ — কেস তালিকা',
        officeLabel: batchWithItems.batch.officeFilter,
        printedAt: printedDate,
      );

      if (!mounted) return;
      setState(() => _isGeneratingPdf = false);

      final dateTag =
          '${printedDate.year}${printedDate.month.toString().padLeft(2, '0')}${printedDate.day.toString().padLeft(2, '0')}';

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ProposalPdfPreviewScreen(
            pdfBytes: pdfBytes,
            title: 'পুনরায় প্রিন্ট / PDF',
            pdfFileName: 'prostab_preron_$dateTag.pdf',
            itemCount: batchWithItems.items.length,
            isPendingBatch: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF তৈরি করতে সমস্যা হয়েছে: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Future<void> _openApplicationDetail(String applicationId) async {
    final allApps =
        ref.read(applicationsWithFinancialsStreamProvider).valueOrNull ??
            const [];
    final match = allApps.where((a) => a.application.id == applicationId);
    if (match.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ApplicationDetailScreen(
          application: match.first.toDemoApplication(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingProposalCandidatesStreamProvider);
    final batchesAsync = ref.watch(printedProposalBatchesStreamProvider);

    final allPending = pendingAsync.valueOrNull ?? const [];
    final batches = batchesAsync.valueOrNull ?? const [];

    // অফিস তালিকা বের করা
    final offices = allPending
        .map((c) => c.application.officeName)
        .toSet()
        .toList()
      ..sort();

    final effectiveOffice =
        (_selectedOffice != null && offices.contains(_selectedOffice))
            ? _selectedOffice
            : null;

    final officeFiltered = effectiveOffice == null
        ? allPending
        : allPending
            .where((c) => c.application.officeName == effectiveOffice)
            .toList();

    final filteredPending = _sortCandidates(officeFiltered);
    final selectedCandidates =
        filteredPending.where(_isCandidateSelected).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('প্রস্তাব প্রেরণ PDF তালিকা'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: [
              Tab(
                text:
                    'প্রিন্ট বাকি (${BengaliDigits.toBengali(filteredPending.length)})',
              ),
              Tab(
                text:
                    'আগে প্রিন্ট করা (${BengaliDigits.toBengali(batches.length)})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendingTab(
              pendingAsync: pendingAsync,
              allPending: allPending,
              filteredPending: filteredPending,
              selectedCandidates: selectedCandidates,
              offices: offices,
              effectiveOffice: effectiveOffice,
            ),
            _buildHistoryTab(batchesAsync: batchesAsync, batches: batches),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab({
    required AsyncValue<List<PendingProposalCandidate>> pendingAsync,
    required List<PendingProposalCandidate> allPending,
    required List<PendingProposalCandidate> filteredPending,
    required List<PendingProposalCandidate> selectedCandidates,
    required List<String> offices,
    required String? effectiveOffice,
  }) {
    if (pendingAsync.isLoading && allPending.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allPending.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'নতুন কোনো কেস বাকি নেই',
        message:
            'বর্তমানে "প্রস্তাব প্রেরণ" স্ট্যাটাসে প্রিন্ট বা জমা করার মতো কোনো নতুন আবেদন নেই। নতুন আবেদন "প্রস্তাব প্রেরণ"-এ এলে এখানে দেখাবে।',
      );
    }

    final allSelected = filteredPending.isNotEmpty &&
        selectedCandidates.length == filteredPending.length;
    final missingCaseCount =
        filteredPending.where((c) => !_hasCaseNumber(c)).length;
    final selectedMissingCaseCount =
        selectedCandidates.where((c) => !_hasCaseNumber(c)).length;

    return Column(
      children: [
        // অফিস ফিল্টার + সর্টিং + সিলেক্ট কন্ট্রোল হেডার
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.sm,
            AppSpacing.base,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (offices.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildOfficeChip(
                        label:
                            'সব অফিস (${BengaliDigits.toBengali(allPending.length)})',
                        selected: effectiveOffice == null,
                        onTap: () => setState(() => _selectedOffice = null),
                      ),
                      ...offices.map((office) {
                        final count = allPending
                            .where((c) => c.application.officeName == office)
                            .length;
                        return _buildOfficeChip(
                          label: '$office (${BengaliDigits.toBengali(count)})',
                          selected: effectiveOffice == office,
                          onTap: () => setState(() => _selectedOffice = office),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'নির্বাচিত: ${BengaliDigits.toBengali(selectedCandidates.length)} / ${BengaliDigits.toBengali(filteredPending.length)} টি',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  PopupMenuButton<_ProposalSortMode>(
                    initialValue: _sortMode,
                    tooltip: 'সাজানোর ক্রম',
                    onSelected: (mode) => setState(() => _sortMode = mode),
                    itemBuilder: (ctx) => _ProposalSortMode.values
                        .map(
                          (m) => PopupMenuItem(
                            value: m,
                            child: Row(
                              children: [
                                if (m == _sortMode)
                                  const Icon(Icons.check,
                                      size: 16, color: AppColors.primary)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(m.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort,
                              size: 14, color: AppColors.slate700),
                          const SizedBox(width: 4),
                          Text(
                            _sortMode.label,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (allSelected) {
                          for (final c in filteredPending) {
                            _selectionOverrides[c.application.id] = false;
                          }
                        } else {
                          for (final c in filteredPending) {
                            _selectionOverrides[c.application.id] = true;
                          }
                        }
                      });
                    },
                    child: Text(
                      allSelected ? 'সব আনটিক' : 'সব টিক',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (missingCaseCount > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.amberSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    selectedMissingCaseCount > 0
                        ? 'সতর্কতা: নির্বাচিত ${BengaliDigits.toBengali(selectedMissingCaseCount)} টি আবেদনে কেস নং লেখা নেই।'
                        : '${BengaliDigits.toBengali(missingCaseCount)} টি আবেদনে কেস নং না থাকায় স্বয়ংক্রিয়ভাবে আনটিক রাখা হয়েছে। ফাইলে ঢুকে কেস নং যোগ করতে পারেন।',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // পেন্ডিং কেস তালিকা
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.base),
            itemCount: filteredPending.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (ctx, index) {
              final item = filteredPending[index];
              final app = item.application;
              final isSelected = _isCandidateSelected(item);
              final caseNo = app.caseNumber?.trim();
              final hasCaseNo = caseNo != null && caseNo.isNotEmpty;

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: () {
                    setState(() {
                      _selectionOverrides[app.id] = !isSelected;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.45)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          onChanged: (checked) {
                            setState(() {
                              _selectionOverrides[app.id] = checked == true;
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.applicantName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasCaseNo
                                          ? AppColors.primarySurface
                                          : AppColors.amberSurface,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: Text(
                                      hasCaseNo
                                          ? 'কেস নং: $caseNo'
                                          : 'কেস নং নেই',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: hasCaseNo
                                            ? AppColors.primary
                                            : AppColors.amber,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    app.officeName,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: AppColors.slate500,
                          ),
                          tooltip: 'আবেদন বিস্তারিত দেখুন',
                          onPressed: () => _openApplicationDetail(app.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // নিচের অ্যাকশন বার
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: AppButton(
              text:
                  'PDF তৈরি ও প্রিন্ট করুন (${BengaliDigits.toBengali(selectedCandidates.length)} টি)',
              icon: Icons.picture_as_pdf_outlined,
              width: double.infinity,
              isLoading: _isGeneratingPdf,
              onPressed: selectedCandidates.isEmpty
                  ? null
                  : () => _openPendingPdfPreview(selectedCandidates),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab({
    required AsyncValue<List<ProposalBatchWithItems>> batchesAsync,
    required List<ProposalBatchWithItems> batches,
  }) {
    if (batchesAsync.isLoading && batches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (batches.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'এখনো কোনো PDF প্রিন্ট করা হয়নি',
        message:
            'আপনি যে কেসগুলোর PDF প্রিন্ট ও জমা সম্পন্ন করবেন, সেগুলো তারিখ অনুযায়ী এখানে সংরক্ষিত থাকবে।',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: batches.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (ctx, index) {
        final entry = batches[index];
        final batch = entry.batch;
        final items = entry.items;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.xs,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              0,
              AppSpacing.base,
              AppSpacing.base,
            ),
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              batch.title ?? 'প্রস্তাব প্রেরণ তালিকা',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_formatDateTime(batch.printedAt)}  •  ${BengaliDigits.toBengali(items.length)} টি কেস',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primary,
                  ),
                  tooltip: 'পুনরায় PDF / প্রিন্ট',
                  onPressed: () => _reprintBatch(entry),
                ),
                const Icon(Icons.expand_more, color: AppColors.slate500),
              ],
            ),
            children: [
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${BengaliDigits.toBengali(i + 1)}.',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].applicantNameSnapshot,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              items[i].caseNumberSnapshot?.isNotEmpty == true
                                  ? 'কেস নং: ${items[i].caseNumberSnapshot}'
                                  : 'কেস নং: —',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.undo_rounded,
                          size: 18,
                          color: AppColors.slate500,
                        ),
                        tooltip: 'এই কেসটি পুনরায় "প্রিন্ট বাকি" তালিকায় নিন',
                        onPressed: () async {
                          final confirm = await ConfirmDialog.show(
                            context,
                            title: 'তালিকায় ফেরত পাঠাবেন?',
                            message:
                                '"${items[i].applicantNameSnapshot}" কেসটিকে কি আবার "প্রিন্ট বাকি" তালিকায় ফেরত পাঠাতে চান?',
                            confirmText: 'হ্যাঁ, ফেরত নিন',
                            icon: Icons.undo_rounded,
                          );
                          if (confirm == true) {
                            await ref
                                .read(proposalPrintControllerProvider.notifier)
                                .unmarkItem(items[i].id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reprintBatch(entry),
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('পুনরায় PDF / প্রিন্ট'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await ConfirmDialog.show(
                        context,
                        title: 'সম্পূর্ণ ব্যাচ ফেরত পাঠাবেন?',
                        message:
                            'এই ব্যাচের সব ${BengaliDigits.toBengali(items.length)} টি কেস পুনরায় "প্রিন্ট বাকি" তালিকায় ফিরে যাবে।',
                        confirmText: 'হ্যাঁ, ফেরত নিন',
                        isDestructive: true,
                        icon: Icons.undo_rounded,
                      );
                      if (confirm == true) {
                        await ref
                            .read(proposalPrintControllerProvider.notifier)
                            .unmarkBatch(batch.id);
                      }
                    },
                    icon: const Icon(Icons.undo_rounded,
                        size: 16, color: AppColors.rose),
                    label: const Text(
                      'ব্যাচ আনমার্ক',
                      style: TextStyle(color: AppColors.rose),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfficeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primarySurface,
        backgroundColor: AppColors.slate100,
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontFamily: AppTypography.fontFamily,
        ),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
