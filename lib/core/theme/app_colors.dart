import 'package:flutter/material.dart';

/// Central color palette for the banking app's Design System.
///
/// Never hard-code a [Color] anywhere in the widget tree — always reference a
/// token from here so the brand stays consistent and re-theming is a one-file
/// change.
abstract final class AppColors {
  const AppColors._();

  // --- Brand ---------------------------------------------------------------
  /// Primary brand color, used for primary CTAs, active states and headers.
  static const Color primary = Color(0xFF1A2E5A); // deep trust-blue
  static const Color primaryLight = Color(0xFF2E4A8A);
  static const Color accent = Color(0xFF3D7EFF); // interactive blue

  // --- Balance card gradient ----------------------------------------------
  static const List<Color> cardGradient = <Color>[
    Color(0xFF1A2E5A),
    Color(0xFF3D5AA9),
  ];

  // --- Semantic / financial ------------------------------------------------
  /// Incoming money (credits).
  static const Color income = Color(0xFF1BA672);
  static const Color incomeSurface = Color(0xFFE6F6EF);

  /// Outgoing money (debits).
  static const Color expense = Color(0xFFE5484D);
  static const Color expenseSurface = Color(0xFFFDECEC);

  // --- Neutrals ------------------------------------------------------------
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E6EF);

  static const Color textPrimary = Color(0xFF0E1526);
  static const Color textSecondary = Color(0xFF6B7488);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color disabled = Color(0xFFB4BAC7);
}
