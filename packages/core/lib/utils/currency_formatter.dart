import 'package:intl/intl.dart';

/// ZAR currency formatting utilities for SpazaLink.
///
/// All monetary values in SpazaLink are stored as integers (cents) to avoid
/// floating-point precision issues. These helpers convert cents → display string.
///
/// Example:  CurrencyFormatter.format(2056) → 'R2,056.00'
///           CurrencyFormatter.format(2500) → 'R25.00'  (25 cents? No — R25 = 2500 cents)
abstract final class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'en_ZA',
    symbol: 'R',
    decimalDigits: 2,
  );

  static final _formatterNoDecimals = NumberFormat.currency(
    locale: 'en_ZA',
    symbol: 'R',
    decimalDigits: 0,
  );

  /// Format [cents] as a ZAR currency string with symbol and 2 decimal places.
  ///
  /// Example: 204500 → 'R2,045.00'
  static String format(int cents) {
    return _formatter.format(cents / 100);
  }

  /// Format [cents] as ZAR without decimal places (for whole-rand amounts).
  ///
  /// Example: 200000 → 'R2,000'
  static String formatNoDecimals(int cents) {
    return _formatterNoDecimals.format(cents ~/ 100);
  }

  /// Format [cents] as a compact string (e.g. for product prices).
  ///
  /// Strips trailing zeros: 2450 → 'R24.50', 2000 → 'R20.00'
  static String formatPrice(int cents) => format(cents);

  /// Returns 'FREE' if [cents] is zero, otherwise formats normally.
  static String formatDeliveryFee(int cents) {
    if (cents == 0) return 'FREE';
    return format(cents);
  }

  /// Returns '+R—' formatted savings string (e.g. for "You save R340.00").
  static String formatSavings(int cents) {
    if (cents <= 0) return '';
    return 'You save ${format(cents)}';
  }

  /// Parse a formatted currency string back to cents.
  ///
  /// Strips 'R', commas, spaces then converts to int cents.
  static int parse(String formatted) {
    final cleaned = formatted
        .replaceAll('R', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    final value = double.tryParse(cleaned) ?? 0.0;
    return (value * 100).round();
  }

  /// Convert a rand double value to cents integer.
  static int randsToCents(double rands) => (rands * 100).round();

  /// Convert cents integer to rand double.
  static double centsToRands(int cents) => cents / 100;
}
