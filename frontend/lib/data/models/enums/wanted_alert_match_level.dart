import 'package:restore/l10n/app_localizations.dart';

/// Mức độ giống tối thiểu để một tin mới được coi là khớp thông báo
/// "Báo khi có hàng". [threshold] là điểm giống (0..1) backend so với
/// kết quả chấm điểm, xem `backend/docs/wanted-alerts.md`.
enum WantedAlertMatchLevel {
  /// Báo cả tin chỉ hơi giống (nhiều thông báo hơn)
  broad('BROAD', 0.3),

  /// Mặc định: đa số từ khoá phải khớp, chấp nhận gõ sai nhẹ
  balanced('BALANCED', 0.45),

  /// Gần như đúng tên món đã nhập
  strict('STRICT', 0.6);

  const WantedAlertMatchLevel(this.apiValue, this.threshold);

  final String apiValue;
  final double threshold;

  static WantedAlertMatchLevel fromApi(String? value) {
    for (final level in values) {
      if (level.apiValue == value) return level;
    }
    return balanced;
  }

  String label(AppLocalizations l10n) => switch (this) {
    broad => l10n.wantedAlertLevelBroad,
    balanced => l10n.wantedAlertLevelBalanced,
    strict => l10n.wantedAlertLevelStrict,
  };

  String description(AppLocalizations l10n) => switch (this) {
    broad => l10n.wantedAlertLevelBroadDesc,
    balanced => l10n.wantedAlertLevelBalancedDesc,
    strict => l10n.wantedAlertLevelStrictDesc,
  };
}
