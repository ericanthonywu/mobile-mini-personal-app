import 'package:intl/intl.dart';

/// Currency formatter for IDR (Indonesian Rupiah).
/// All amounts in the app are integers (no decimals).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Formats an integer amount to IDR string.
  /// e.g. 494614 → "Rp494.614"
  static String format(int amount) => _formatter.format(amount);

  /// Formats a compact version for charts / small widgets.
  /// e.g. 1500000 → "1.5jt", 500000 → "500rb"
  static String compact(int amount) {
    if (amount >= 1000000) {
      final juta = amount / 1000000;
      return 'Rp${juta % 1 == 0 ? juta.toInt() : juta.toStringAsFixed(1)}jt';
    }
    if (amount >= 1000) {
      final ribu = amount / 1000;
      return 'Rp${ribu % 1 == 0 ? ribu.toInt() : ribu.toStringAsFixed(0)}rb';
    }
    return format(amount);
  }
}
