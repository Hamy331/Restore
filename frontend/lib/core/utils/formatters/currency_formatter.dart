import 'package:intl/intl.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Định dạng số tiền VND dùng chung cho toàn app (VD: 15.000.000 đ)
class CurrencyFormatter {
  CurrencyFormatter._();

  static const String vndSymbol = 'đ';

  static String formatNumber(num value, {String? locale}) =>
      NumberFormat.decimalPattern(locale).format(value);

  static String formatVnd(num value, {String? locale}) =>
      '${formatNumber(value, locale: locale)} $vndSymbol';

  /// Dạng rút gọn cho chip, nhãn ngắn: "500 nghìn", "2,5 triệu"
  /// ("500K", "2.5M" khi dùng tiếng Anh). Dưới 1.000 đ thì để nguyên.
  static String formatCompact(
    num value,
    AppLocalizations l10n, {
    String? locale,
  }) {
    final format = NumberFormat('#,##0.#', locale);
    if (value >= 1000000) return l10n.priceMillions(format.format(value / 1e6));
    if (value >= 1000) return l10n.priceThousands(format.format(value / 1e3));
    return formatVnd(value, locale: locale);
  }
}
