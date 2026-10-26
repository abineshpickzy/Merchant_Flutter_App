import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactInr = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(num amount) => _inrFormat.format(amount);
  static String formatCompact(num amount) => _compactInr.format(amount);
}
