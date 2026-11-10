import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';

/// তৈরি করা 'প্রস্তাব প্রেরণ' PDF প্রিভিউ, প্রিন্ট ও শেয়ার করার স্ক্রিন।
class ProposalPdfPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String title;
  final String pdfFileName;
  final int itemCount;
  final bool isPendingBatch;
  final Future<void> Function()? onMarkAsPrinted;

  const ProposalPdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.title,
    required this.pdfFileName,
    required this.itemCount,
    this.isPendingBatch = false,
    this.onMarkAsPrinted,
  });

  @override
  State<ProposalPdfPreviewScreen> createState() =>
      _ProposalPdfPreviewScreenState();
}

class _ProposalPdfPreviewScreenState extends State<ProposalPdfPreviewScreen> {
  bool _isSaving = false;
  bool _isMarked = false;
  bool _hasPrintedOrShared = false;

  Future<void> _markPrinted() async {
    if (_isSaving || _isMarked || widget.onMarkAsPrinted == null) return;
    setState(() => _isSaving = true);
    try {
      await widget.onMarkAsPrinted!();
      if (!mounted) return;
      _isMarked = true;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ব্যাচ সংরক্ষণ করা যায়নি: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Future<void> _confirmAndMarkFromButton() async {
    if (!_hasPrintedOrShared) {
      final proceed = await ConfirmDialog.show(
        context,
        title: 'এখনো প্রিন্ট বা শেয়ার করা হয়নি',
        message:
            'আপনি এখনো প্রিভিউ থেকে প্রিন্ট বা শেয়ার বাটনে চাপ দেননি। '
            'তারপরও কি এই ${BengaliDigits.toBengali(widget.itemCount)} টি কেস "আগে প্রিন্ট করা" তালিকায় সরিয়ে নিতে চান?',
        confirmText: 'হ্যাঁ, সম্পন্ন হয়েছে',
        cancelText: 'না, প্রিন্ট করি আগে',
        icon: Icons.warning_amber_rounded,
      );
      if (proceed != true) return;
    }
    await _markPrinted();
  }

  Future<void> _handleBackNavigation() async {
    if (!widget.isPendingBatch || _isMarked || _isSaving) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }

    final title = _hasPrintedOrShared
        ? 'প্রিন্ট ও জমা নিশ্চিতকরণ'
        : 'এখনো প্রিন্ট করা হয়নি';
    final message = _hasPrintedOrShared
        ? 'এই ${BengaliDigits.toBengali(widget.itemCount)} টি কেস কি "আগে প্রিন্ট করা হয়েছে" তালিকায় সরিয়ে নিবেন? '
            'সরিয়ে নিলে পরবর্তীতে নতুন আসা কেসগুলো আলাদাভাবে দেখাবে।'
        : 'আপনি এখনো প্রিন্ট বা শেয়ার করেননি। '
            'তবুও কি এই ${BengaliDigits.toBengali(widget.itemCount)} টি কেস "আগে প্রিন্ট করা" তালিকায় সরিয়ে নিবেন?';

    final shouldMark = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmText: 'হ্যাঁ, সম্পন্ন হয়েছে',
      cancelText: 'না, বাকি থাকুক',
      icon: _hasPrintedOrShared
          ? Icons.print_outlined
          : Icons.warning_amber_rounded,
    );

    if (!mounted) return;
    if (shouldMark == true) {
      await _markPrinted();
    } else if (shouldMark == false) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isPendingBatch || _isMarked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: PdfPreview(
          build: (_) async => widget.pdfBytes,
          pdfFileName: widget.pdfFileName,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
          onPrinted: (_) {
            if (mounted) {
              setState(() => _hasPrintedOrShared = true);
            }
          },
          onShared: (_) {
            if (mounted) {
              setState(() => _hasPrintedOrShared = true);
            }
          },
        ),
        bottomNavigationBar: widget.isPendingBatch
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.sm,
                    AppSpacing.base,
                    AppSpacing.base,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _hasPrintedOrShared
                            ? 'প্রিন্ট/শেয়ার সম্পন্ন হয়েছে — নিচের বাটনে চাপ দিলে এগুলো "আগে প্রিন্ট করা" তালিকায় চলে যাবে।'
                            : 'প্রথমে উপরের/নিচের আইকন থেকে প্রিন্ট বা PDF সেভ করুন, এরপর নিচের বাটনে চাপ দিন।',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: _hasPrintedOrShared
                              ? AppColors.emerald
                              : AppColors.textSecondary,
                          fontWeight: _hasPrintedOrShared
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        text:
                            'প্রিন্ট / জমা সম্পন্ন (${BengaliDigits.toBengali(widget.itemCount)} টি)',
                        icon: Icons.check_circle_outline,
                        isLoading: _isSaving,
                        onPressed: _confirmAndMarkFromButton,
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
