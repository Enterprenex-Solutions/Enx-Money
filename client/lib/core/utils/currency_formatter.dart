import 'package:intl/intl.dart';

/// Formatter utilities for ENX Money balances and numbers
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 2,
  );

  static final NumberFormat _inrNoDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '\u20B9',
    decimalDigits: 0,
  );

  /// Formats amount e.g. ₹1,24,500.00
  static String format(double amount, {bool showDecimals = true}) {
    if (showDecimals) {
      return _inrFormatter.format(amount);
    }
    return _inrNoDecimals.format(amount);
  }

  /// Compact formatting e.g. ₹1.25 L or ₹45.2 K
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return '\u20B9${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '\u20B9${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '\u20B9${(amount / 1000).toStringAsFixed(1)} K';
    }
    return format(amount, showDecimals: false);
  }
}
