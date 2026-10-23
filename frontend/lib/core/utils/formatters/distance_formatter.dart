import 'package:intl/intl.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Hiển thị khoảng cách: dưới 1 km tính bằng mét ("850 m"),
/// từ 1 km trở lên lấy 1 chữ số thập phân ("1,2 km" / "1.2 km")
class DistanceFormatter {
  DistanceFormatter._();

  static String format(double km, AppLocalizations l10n, {String? locale}) {
    if (km < 1) {
      // Làm tròn tới 10 m, tối thiểu 10 m cho đỡ hiện "0 m"
      final meters = ((km * 1000) / 10).round().clamp(1, 99) * 10;
      return l10n.distanceMeters(meters);
    }
    final value = NumberFormat('#,##0.#', locale).format(km);
    return l10n.distanceKm(value);
  }
}
