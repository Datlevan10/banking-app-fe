import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Visual variants for [CustomButton].
enum ButtonVariant { primary, secondary }

/// A reusable button following the banking UI guidelines.
///
/// - [ButtonVariant.primary] : solid brand-colored CTA.
/// - [ButtonVariant.secondary]: outlined, lower-emphasis action.
///
/// Handles loading and disabled states internally so screens stay declarative.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;

  /// A `null` callback renders the button in its disabled state.
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  bool get _isPrimary => variant == ButtonVariant.primary;

  /// The button is non-interactive while loading or when [onPressed] is null.
  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final Color foreground = _isPrimary
        ? AppColors.textOnPrimary
        : AppColors.primary;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _resolveBackground(),
          borderRadius: AppSpacing.borderRadiusMd,
          border: _isPrimary
              ? null
              : Border.all(
                  color: _isEnabled ? AppColors.primary : AppColors.disabled,
                  width: 1.4,
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppSpacing.borderRadiusMd,
            onTap: _isEnabled ? onPressed : null,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(foreground),
                      ),
                    )
                  : _buildLabel(foreground),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(Color foreground) {
    final Text text = Text(
      label,
      style: AppTypography.button.copyWith(color: foreground),
    );

    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 20, color: foreground),
        const SizedBox(width: AppSpacing.sm),
        text,
      ],
    );
  }

  Color _resolveBackground() {
    if (!_isPrimary) return Colors.transparent;
    return _isEnabled ? AppColors.primary : AppColors.disabled;
  }
}
