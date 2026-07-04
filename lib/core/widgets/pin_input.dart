import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A row of dots visualising secure code entry (PIN or OTP).
///
/// Purely presentational: it renders [filledCount] filled dots out of [length]
/// and never holds the code itself — the value lives in the owning BLoC.
class PinInput extends StatelessWidget {
  const PinInput({
    super.key,
    required this.length,
    required this.filledCount,
    this.hasError = false,
  });

  final int length;
  final int filledCount;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = hasError ? AppColors.expense : AppColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(length, (int index) {
        final bool isFilled = index < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          height: 18,
          width: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? activeColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? activeColor : AppColors.border,
              width: 1.6,
            ),
          ),
        );
      }),
    );
  }
}
