import 'package:intl/intl.dart';

/// Formats monetary amounts consistently across the app using `intl`.
///
/// Centralising this avoids scattered, inconsistent number formatting — a
/// common source of bugs in financial UIs.
abstract final class CurrencyFormatter {
  const CurrencyFormatter._();

  static final NumberFormat _usd = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 2,
  );

  /// e.g. `1234.5` -> `$1,234.50`.
  static String format(num amount) => _usd.format(amount);

  /// Signed format for transactions, e.g. `+$1,234.50` / `-$50.00`.
  static String formatSigned(num amount) {
    final String value = _usd.format(amount.abs());
    return amount < 0 ? '-$value' : '+$value';
  }

  /// Masks a balance while preserving the currency symbol, e.g. `$••••••`.
  static String masked({int dots = 6}) => '\$${'•' * dots}';
}
