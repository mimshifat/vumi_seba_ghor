import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/bengali_digits.dart';

class StepItem {
  final String title;
  final IconData icon;

  const StepItem({
    required this.title,
    required this.icon,
  });
}

class FormStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<StepItem> steps;
  final ValueChanged<int>? onStepTapped;

  const FormStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / steps.length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.md,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: Row(
              children: List.generate(steps.length * 2 - 1, (index) {
                // Connecting lines
                if (index.isOdd) {
                  final prevStep = index ~/ 2;
                  final isPassed = currentStep > prevStep;
                  return Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isPassed ? AppColors.emerald : AppColors.slate200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }

                // Step nodes
                final stepIndex = index ~/ 2;
                final isCompleted = currentStep > stepIndex;
                final isActive = currentStep == stepIndex;
                final item = steps[stepIndex];

                return InkWell(
                  onTap: (isCompleted && onStepTapped != null)
                      ? () => onStepTapped!(stepIndex)
                      : null,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.emerald
                                : (isActive ? AppColors.primary : Colors.white),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.emerald
                                  : (isActive ? AppColors.primary : AppColors.slate300),
                              width: isActive ? 2.5 : 1.5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 18, color: Colors.white)
                                : Text(
                                    BengaliDigits.toBengali('${stepIndex + 1}'),
                                    style: TextStyle(
                                      color: isActive ? Colors.white : AppColors.slate500,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppTypography.fontFamily,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : (isCompleted ? FontWeight.w600 : FontWeight.w500),
                            color: isActive
                                ? AppColors.primary
                                : (isCompleted ? AppColors.emeraldDark : AppColors.slate500),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // Subtle Progress Bar indicator at bottom of step header
          Stack(
            children: [
              Container(
                height: 3,
                width: double.infinity,
                color: AppColors.slate100,
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                widthFactor: progress.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        isCompletedStep(currentStep, steps.length)
                            ? AppColors.emerald
                            : AppColors.primaryLight,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isCompletedStep(int current, int total) => current >= total - 1;
}
