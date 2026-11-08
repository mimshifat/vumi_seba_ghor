import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Reusable form field label component that adheres to the application's
/// required and optional indicator standard:
/// - Mandatory fields display a prominent red '*' symbol (e.g. `নাম *`).
/// - Optional fields display no asterisk and never display the word 'ঐচ্ছিক'.
class AppFieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final TextStyle? style;
  final bool _inline;

  const AppFieldLabel({
    super.key,
    required this.label,
    this.isRequired = false,
    this.style,
  }) : _inline = false;

  /// Use this constructor inside InputDecoration.label or similar inline contexts
  /// where the ambient/theme label style should be inherited.
  const AppFieldLabel.inline({
    super.key,
    required this.label,
    this.isRequired = false,
    this.style,
  }) : _inline = true;

  /// Helper to build a [TextSpan] for custom RichText or InputDecoration label widgets.
  static TextSpan buildSpan(
    String label, {
    bool isRequired = false,
    TextStyle? style,
    Color asteriskColor = AppColors.rose,
  }) {
    return TextSpan(
      text: label,
      style: style,
      children: [
        if (isRequired)
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: asteriskColor,
              fontWeight: FontWeight.bold,
              fontSize: style?.fontSize != null ? (style!.fontSize! + 0.5) : 14,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = _inline
        ? style
        : (style ??
            AppTypography.titleMedium.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ));

    return Text.rich(
      buildSpan(
        label,
        isRequired: isRequired,
        style: effectiveStyle,
      ),
    );
  }
}

