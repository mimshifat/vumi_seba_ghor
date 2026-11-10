import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../utils/case_number_formatter.dart';
import '../utils/validators.dart';
import 'app_field_label.dart';

/// বাংলাদেশের নামজারি কেস নম্বর (`[ক্রমিক]/[রেজিস্টার]/[অর্থবছর]`) ইনপুট ফিল্ড।
///
/// - কেবল ক্রমিক (যেমন `7091`) বা `7091/2025-2026` লিখলে [referenceDate]-এর
///   অর্থবছর অনুযায়ী তাৎক্ষণিক ফরম্যাট সাজেশন দেখায় এবং ফোকাস ছাড়লে
///   স্বয়ংক্রিয়ভাবে `৭০৯১/IX-I/২০২৫-২০২৬` রূপে সাজিয়ে দেয়।
class CaseNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final DateTime? referenceDate;
  final void Function(String)? onChanged;

  const CaseNumberField({
    super.key,
    required this.controller,
    this.label = 'কেস নম্বর',
    this.isRequired = false,
    this.referenceDate,
    this.onChanged,
  });

  @override
  State<CaseNumberField> createState() => _CaseNumberFieldState();
}

class _CaseNumberFieldState extends State<CaseNumberField> {
  final FocusNode _focusNode = FocusNode();

  DateTime get _effectiveDate => widget.referenceDate ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant CaseNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    if (mounted) setState(() {});
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _applyAutoFormatIfPossible();
    }
  }

  void _applyAutoFormatIfPossible() {
    final raw = widget.controller.text.trim();
    if (raw.isEmpty) return;

    final parsed = CaseNumberFormatter.tryParse(
      raw,
      referenceDate: _effectiveDate,
    );
    if (parsed == null) return;

    final formatted = parsed.formatted;
    if (formatted != widget.controller.text) {
      widget.controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      widget.onChanged?.call(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fiscalYear = CaseNumberFormatter.fiscalYearForDate(_effectiveDate);
    final rawText = widget.controller.text.trim();
    final parsed = rawText.isNotEmpty
        ? CaseNumberFormatter.tryParse(rawText, referenceDate: _effectiveDate)
        : null;
    final suggestion = parsed?.formatted;
    final showSuggestionChip =
        suggestion != null && suggestion != rawText;
    final isAlreadyCanonical =
        rawText.isNotEmpty &&
        CaseNumberFormatter.isCanonicalStructure(rawText) &&
        suggestion == rawText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(
          label: widget.label,
          isRequired: widget.isRequired,
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: AppValidators.validateCaseNumber,
          onChanged: widget.onChanged,
          style: AppTypography.bodyLarge.copyWith(fontSize: 14.5),
          decoration: InputDecoration(
            hintText: 'যেমন: ৭০৯১/IX-I/$fiscalYear',
            helperText: 'ফরম্যাট: ক্রমিক/IX-I/অর্থবছর (১ জুলাই – ৩০ জুন)',
            helperMaxLines: 2,
            prefixIcon: const Icon(
              Icons.gavel_outlined,
              size: 18,
              color: AppColors.slate400,
            ),
            suffixIcon: showSuggestionChip
                ? IconButton(
                    icon: const Icon(
                      Icons.auto_fix_high_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    tooltip: 'আদর্শ ফরম্যাটে সাজান',
                    onPressed: _applyAutoFormatIfPossible,
                  )
                : (isAlreadyCanonical
                    ? const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: AppColors.emerald,
                      )
                    : null),
          ),
        ),
        if (showSuggestionChip) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: _applyAutoFormatIfPossible,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'সঠিক ফরম্যাটে বসান: $suggestion',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

