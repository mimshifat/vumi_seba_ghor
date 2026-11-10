import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../utils/case_number_formatter.dart';

/// Interactive chip that copies a value to the clipboard and provides
/// elegant inline visual feedback (transitions to '✓ কপি হয়েছে') without
/// triggering disruptive snackbars or blocking bottom navigation.
class CopyChip extends StatefulWidget {
  final String label;
  final String value;
  final String? copyText;
  final IconData? prefixIcon;

  const CopyChip({
    super.key,
    required this.label,
    required this.value,
    this.copyText,
    this.prefixIcon,
  });

  @override
  State<CopyChip> createState() => _CopyChipState();
}

class _CopyChipState extends State<CopyChip> {
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _resolvedDisplayValue {
    final raw = widget.value.trim();
    if (widget.label.contains('কেস')) {
      return CaseNumberFormatter.formatDisplay(raw);
    }
    return raw;
  }

  void _handleCopy() {
    final textToCopy = widget.copyText ?? _resolvedDisplayValue;
    Clipboard.setData(ClipboardData(text: textToCopy));

    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = _resolvedDisplayValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleCopy,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _copied ? AppColors.emeraldSurface : AppColors.slate50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            border: Border.all(
              color: _copied
                  ? AppColors.emerald.withValues(alpha: 0.4)
                  : AppColors.slate200,
              width: 0.9,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _copied
                ? Row(
                    key: const ValueKey('copied'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: AppColors.emerald,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'কপি হয়েছে!',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('normal'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.prefixIcon != null) ...[
                        Icon(widget.prefixIcon, size: 11, color: AppColors.slate500),
                        const SizedBox(width: 3.5),
                      ],
                      Text(
                        '${widget.label}: ',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        displayValue,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4.5),
                      const Icon(
                        Icons.copy_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

