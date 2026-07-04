import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A [TextInputFormatter] that groups the integer part with thousands
/// separators as the user types, e.g. `1234567` -> `1,234,567`.
///
/// Kept as a standalone formatter so it can be reused and unit-tested in
/// isolation from the widget.
class _ThousandsFormatter extends TextInputFormatter {
  final RegExp _nonDigit = RegExp(r'[^0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(_nonDigit, '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final String formatted = buffer.toString();

    // Keep the caret at the end — simplest correct behaviour for amount entry.
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// A reusable, secure text field for the banking UI.
///
/// Three modes via named constructors:
/// - [CustomTextField]         : standard labelled input.
/// - [CustomTextField.password]: obscured input with a visibility toggle.
/// - [CustomTextField.currency]: numeric input with a `$` prefix and live
///   thousands grouping.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.isObscurable = false,
    this.prefixText,
  });

  /// Obscured password field with a built-in show/hide toggle.
  const CustomTextField.password({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.validator,
    this.onChanged,
    this.prefixIcon = Icons.lock_outline,
  })  : keyboardType = TextInputType.visiblePassword,
        isObscurable = true,
        prefixText = null,
        inputFormatters = null;

  /// Numeric, obscured PIN-setup field limited to [length] digits, with a
  /// visibility toggle. Used to choose a transaction PIN.
  CustomTextField.pin({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.validator,
    this.onChanged,
    int length = 6,
  })  : keyboardType = TextInputType.number,
        prefixIcon = Icons.password_outlined,
        prefixText = null,
        isObscurable = true,
        inputFormatters = <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ];

  /// Currency amount field: numeric keyboard, `$` prefix, thousands grouping.
  CustomTextField.currency({
    super.key,
    required this.label,
    this.controller,
    this.hintText = '0',
    this.validator,
    this.onChanged,
  })  : keyboardType = const TextInputType.numberWithOptions(decimal: true),
        prefixIcon = null,
        prefixText = r'$ ',
        isObscurable = false,
        inputFormatters = <TextInputFormatter>[_ThousandsFormatter()];

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? prefixText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  /// When true the field starts obscured and shows a visibility toggle.
  final bool isObscurable;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscured = widget.isObscurable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(widget.label, style: AppTypography.bodyStrong),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          style: AppTypography.title,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTypography.title.copyWith(color: AppColors.disabled),
            prefixText: widget.prefixText,
            prefixStyle: AppTypography.title,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon, color: AppColors.textSecondary),
            suffixIcon: widget.isObscurable ? _buildVisibilityToggle() : null,
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityToggle() {
    return IconButton(
      icon: Icon(
        _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textSecondary,
      ),
      tooltip: _obscured ? 'Show' : 'Hide',
      onPressed: () => setState(() => _obscured = !_obscured),
    );
  }
}
