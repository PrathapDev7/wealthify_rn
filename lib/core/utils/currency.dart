import 'package:intl/intl.dart';

/// Currency formatter ported from `legacy_rn/src/utils/currency.ts`.
/// Uses Indian digit grouping (1,00,000) to match the INR default.
String formatCurrency(
  num? value, {
  String symbol = '₹',
  int maximumFractionDigits = 2,
  bool showSymbol = true,
}) {
  final v = (value ?? 0).toDouble();
  final sign = v < 0 ? '-' : '';
  final formatter = NumberFormat.decimalPattern('en_IN')
    ..maximumFractionDigits = maximumFractionDigits
    ..minimumFractionDigits = 0;
  return '$sign${showSymbol ? symbol : ''}${formatter.format(v.abs())}';
}
