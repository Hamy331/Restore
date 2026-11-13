import 'package:restore/l10n/app_localizations.dart';

/// Thời gian còn lại gọn: dưới 1 ngày tính theo giờ (ít nhất 1), còn lại
/// tính theo ngày làm tròn lên
String hubRemaining(AppLocalizations l, Duration left) {
  if (left.inHours < 24) {
    return l.hubHours((left.inMinutes / 60).ceil().clamp(1, 24));
  }
  return l.hubDays((left.inHours / 24).ceil());
}
