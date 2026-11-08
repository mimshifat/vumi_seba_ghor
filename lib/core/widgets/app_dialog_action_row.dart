import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import 'app_button.dart';

class AppDialogActionRow extends StatelessWidget {
  final String cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final bool isDestructive;
  final bool isLoading;
  final IconData? confirmIcon;
  final double height;

  const AppDialogActionRow({
    super.key,
    this.cancelText = 'বাতিল',
    required this.confirmText,
    this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
    this.isLoading = false,
    this.confirmIcon,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: cancelText,
              variant: ButtonVariant.outline,
              height: height,
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              text: confirmText,
              variant: isDestructive ? ButtonVariant.danger : ButtonVariant.primary,
              height: height,
              icon: confirmIcon,
              isLoading: isLoading,
              onPressed: onConfirm,
            ),
          ),
        ],
      ),
    );
  }
}

