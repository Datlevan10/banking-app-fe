import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A secure on-screen numeric keypad for PIN / OTP entry.
///
/// Banking apps prefer a custom keypad over the system keyboard to reduce
/// keylogging surface. The bottom-left slot optionally hosts the biometric
/// shortcut; the bottom-right is always backspace.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspace,
    this.onBiometricPressed,
    this.showBiometric = false,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspace;

  /// Invoked when the biometric shortcut is tapped (only if [showBiometric]).
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<String> row in _layout)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map(_buildKey).toList(),
            ),
          ),
      ],
    );
  }

  /// Grid layout; empty strings render placeholder / special keys.
  static const List<List<String>> _layout = <List<String>>[
    <String>['1', '2', '3'],
    <String>['4', '5', '6'],
    <String>['7', '8', '9'],
    <String>['bio', '0', 'del'],
  ];

  Widget _buildKey(String value) {
    return switch (value) {
      'del' => _KeypadButton(
          onTap: onBackspace,
          child: const Icon(
            Icons.backspace_outlined,
            color: AppColors.textPrimary,
          ),
        ),
      'bio' when showBiometric => _KeypadButton(
          onTap: onBiometricPressed,
          child: const Icon(
            Icons.fingerprint_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
      'bio' => const SizedBox(width: 72, height: 72), // empty placeholder
      _ => _KeypadButton(
          onTap: () => onDigitPressed(value),
          child: Text(value, style: AppTypography.headline),
        ),
    };
  }
}

/// A single circular, tappable keypad button.
class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(child: child),
        ),
      ),
    );
  }
}
