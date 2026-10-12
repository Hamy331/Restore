import 'package:intl/intl.dart';

/// Định dạng số tiền VND dùng chung cho toàn app (VD: 15.000.000 đ)
class CurrencyFormatter {
  CurrencyFormatter._();

  static const String vndSymbol = 'đ';

  static String formatNumber(num value, {String? locale}) =>
      NumberFormat.decimalPattern(locale).format(value);

  static String formatVnd(num value, {String? locale}) =>
      '${formatNumber(value, locale: locale)} $vndSymbol';
}
