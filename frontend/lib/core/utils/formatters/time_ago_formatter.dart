import 'package:restore/l10n/app_localizations.dart';

/// Hiển thị thời gian tương đối: "Vừa xong", "5 phút trước", "2 ngày trước"
class TimeAgoFormatter {
  TimeAgoFormatter._();

  static String format(DateTime time, AppLocalizations l10n, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}
