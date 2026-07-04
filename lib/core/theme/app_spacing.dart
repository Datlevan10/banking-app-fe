import 'package:flutter/widgets.dart';

/// Spacing, radius and sizing scale for the Design System.
///
/// A single 4-pt based scale keeps vertical rhythm and gutters consistent
/// across every screen. Prefer these tokens over magic numbers.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Default horizontal screen gutter.
  static const double screenPadding = 20;

  // Common EdgeInsets shortcuts ------------------------------------------
  static const EdgeInsets screenInsets = EdgeInsets.symmetric(
    horizontal: screenPadding,
  );

  // Border radii ----------------------------------------------------------
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;

  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
}
