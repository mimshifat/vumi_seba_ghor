import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../utils/bengali_digits.dart';
import '../utils/case_number_formatter.dart';
import 'app_field_label.dart';

/// ইংরেজি ও বাংলা যেকোনো অঙ্কে ইনপুট নিলে স্বয়ংক্রিয়ভাবে বাংলা অঙ্কে রূপান্তরকারী ফরম্যাটার।
class BengaliDigitInputFormatter extends TextInputFormatter {
  const BengaliDigitInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // স্মার্ট পেস্ট হ্যান্ডলিং: পুরো কেস নম্বর (যেমন ৭০৯১/IX-I/২০২৬-২০২৭) পেস্ট করলে কেবল ক্রমিক আলাদা করে নেওয়া
    var textToProcess = newValue.text;
    if (textToProcess.contains('/')) {
      final parsed = CaseNumberFormatter.tryParse(textToProcess);
      if (parsed != null) {
        final serialBn = BengaliDigits.toBengali(parsed.serial);
        return TextEditingValue(
          text: serialBn,
          selection: TextSelection.collapsed(offset: serialBn.length),
        );
      }
    }

    final buffer = StringBuffer();
    int newCursorPos = 0;
    final targetSelectionIndex = newValue.selection.end;

    for (int i = 0; i < textToProcess.length; i++) {
      final char = textToProcess[i];
      if (RegExp(r'[0-9০-৯]').hasMatch(char)) {
        buffer.write(BengaliDigits.toBengali(char));
        if (i < targetSelectionIndex) {
          newCursorPos++;
        }
      }
    }

    final newString = buffer.toString();
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(
        offset: newCursorPos.clamp(0, newString.length),
      ),
    );
  }
}

/// বাংলাদেশের নামজারি কেস নম্বর (`[ক্রমিক]/[রেজিস্টার]/[অর্থবছর]`) ইনপুট ফিল্ড।
///
/// - ব্যবহারকারী কেবল ক্রমিক নম্বর (যেমন `৭০৯১`) ইনপুট করবেন।
/// - ইংরেজি বা বাংলা যেকোনো অঙ্কে লিখলে স্বয়ংক্রিয়ভাবে বাংলা অঙ্কে রূপান্তর হয়।
/// - `/IX-I/অর্থবছর` ফরম্যাট অংশটি ইনপুট ফিল্ডের ভেতরেই ফিক্সড অনুসর্গ (Suffix) হিসেবে দৃশ্যমান থাকে।
/// - [controller]-এ সর্বদা পূর্ণ আদর্শ রূপ (যেমন `৭০৯১/IX-I/২০২৬-২০২৭`) সংরক্ষিত হয়।
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
  late final TextEditingController _serialController;
  final FocusNode _focusNode = FocusNode();
  bool _isSyncing = false;

  String _registerCode = CaseNumberFormatter.defaultRegisterCode;
  late String _fiscalYear;

  DateTime get _effectiveDate => widget.referenceDate ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _fiscalYear = CaseNumberFormatter.fiscalYearForDate(_effectiveDate);
    _serialController = TextEditingController();

    _syncFromExternalController(initial: true);

    _serialController.addListener(_onSerialChanged);
    widget.controller.addListener(_onExternalControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CaseNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onExternalControllerChanged);
      widget.controller.addListener(_onExternalControllerChanged);
      _syncFromExternalController();
    }

    if (oldWidget.referenceDate != widget.referenceDate) {
      _fiscalYear = CaseNumberFormatter.fiscalYearForDate(_effectiveDate);
      _syncToExternalController();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onExternalControllerChanged);
    _serialController.removeListener(_onSerialChanged);
    _serialController.dispose();
    super.dispose();
  }

  /// বহিঃস্থ [widget.controller] থেকে সিরিয়াল ও ফরম্যাট পড়ে নেওয়া।
  void _syncFromExternalController({bool initial = false}) {
    if (_isSyncing) return;
    final full = widget.controller.text.trim();

    if (full.isEmpty) {
      if (_serialController.text.isNotEmpty) {
        _isSyncing = true;
        _serialController.text = '';
        _isSyncing = false;
      }
      return;
    }

    final parsed = CaseNumberFormatter.tryParse(full, referenceDate: _effectiveDate);
    if (parsed != null) {
      _registerCode = parsed.registerCode;
      _fiscalYear =
          '${BengaliDigits.toBengali(parsed.fiscalStartYear)}-${BengaliDigits.toBengali(parsed.fiscalEndYear)}';

      final serialBn = BengaliDigits.toBengali(parsed.serial);
      if (_serialController.text != serialBn) {
        _isSyncing = true;
        _serialController.text = serialBn;
        _isSyncing = false;
      }
    } else {
      // যদি শুধু ক্রমিক নম্বর দিয়ে থাকে
      final en = BengaliDigits.toEnglish(full);
      final serialOnly = int.tryParse(en);
      if (serialOnly != null) {
        final serialBn = BengaliDigits.toBengali(serialOnly);
        if (_serialController.text != serialBn) {
          _isSyncing = true;
          _serialController.text = serialBn;
          _isSyncing = false;
        }
      }
    }

    if (!initial && mounted) {
      setState(() {});
    }
  }

  /// সিরিয়াল ইনপুট থেকে পূর্ণ কেস নম্বর তৈরি করে [widget.controller]-এ লেখা।
  void _onSerialChanged() {
    if (_isSyncing) return;
    _syncToExternalController();
  }

  void _syncToExternalController() {
    _isSyncing = true;
    try {
      final serial = _serialController.text.trim();
      final String fullCaseNumber;
      if (serial.isEmpty) {
        fullCaseNumber = '';
      } else {
        fullCaseNumber = '$serial/$_registerCode/$_fiscalYear';
      }

      if (widget.controller.text != fullCaseNumber) {
        widget.controller.text = fullCaseNumber;
        widget.onChanged?.call(fullCaseNumber);
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _onExternalControllerChanged() {
    if (_isSyncing) return;
    _syncFromExternalController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(
          label: widget.label,
          isRequired: widget.isRequired,
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        TextFormField(
          controller: _serialController,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            const BengaliDigitInputFormatter(),
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              if (widget.isRequired) {
                return 'কেস নম্বর আবশ্যক';
              }
              return null;
            }
            final en = BengaliDigits.toEnglish(trimmed);
            final num = int.tryParse(en);
            if (num == null || num <= 0) {
              return 'সঠিক ক্রমিক নম্বর দিন (যেমন: ৭০৯১)';
            }
            return null;
          },
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            hintText: 'যেমন: ৭০৯১',
            prefixIcon: const Icon(
              Icons.gavel_outlined,
              size: 18,
              color: AppColors.slate400,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.slate200,
                    width: 1,
                  ),
                ),
                child: Text(
                  '/$_registerCode/$_fiscalYear',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
