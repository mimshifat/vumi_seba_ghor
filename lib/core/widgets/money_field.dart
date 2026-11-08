import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../utils/bengali_digits.dart';
import 'app_field_label.dart';

class MoneyField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isRequired;
  final bool showQuickChips;
  final void Function(int amountInTaka)? onAmountChanged;
  final String? Function(String?)? validator;

  const MoneyField({
    super.key,
    required this.label,
    this.hint = '০',
    this.controller,
    this.isRequired = false,
    this.showQuickChips = false,
    this.onAmountChanged,
    this.validator,
  });

  @override
  State<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<MoneyField> {
  late final TextEditingController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _internalController = true;
    }
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _addQuickAmount(int amount) {
    final currentEng = BengaliDigits.toEnglish(_controller.text.replaceAll(',', '').trim());
    final current = int.tryParse(currentEng) ?? 0;
    final updated = current + amount;
    _controller.text = updated.toString();
    widget.onAmountChanged?.call(updated);
    setState(() {});
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
          controller: _controller,
          keyboardType: TextInputType.number,
          validator: widget.validator,
          style: AppTypography.headingMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
          onChanged: (val) {
            final eng = BengaliDigits.toEnglish(val.replaceAll(',', '').trim());
            final amount = int.tryParse(eng) ?? 0;
            widget.onAmountChanged?.call(amount);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Container(
              width: 44,
              alignment: Alignment.center,
              child: const Text(
                '৳',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.slate400),
                    onPressed: () {
                      _controller.clear();
                      widget.onAmountChanged?.call(0);
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        if (widget.showQuickChips) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip(500),
                const SizedBox(width: AppSpacing.sm),
                _buildQuickChip(1000),
                const SizedBox(width: AppSpacing.sm),
                _buildQuickChip(2000),
                const SizedBox(width: AppSpacing.sm),
                _buildQuickChip(5000),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickChip(int amount) {
    return InkWell(
      onTap: () => _addQuickAmount(amount),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: AppColors.primaryLight, width: 1),
        ),
        child: Text(
          '+৳${BengaliDigits.toBengali(amount)}',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.primary,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }
}

