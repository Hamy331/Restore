import 'package:restore/l10n/app_localizations.dart';

/// Gói tài khoản. [tier] là giá trị `StoreTier` ở backend, tên hiển thị khớp
/// với gói đang bán:
/// - `PERSONAL`: Cá nhân / Personal (miễn phí)
/// - `BASIC`: Bán chuyên / Basic
/// - `PRO`: Cửa hàng Pro / Professional Shop
///
/// Mọi chỗ đổi tier sang gói trong app đi qua [fromTier], không tự so chuỗi.
enum SubscriptionPlan {
  /// Miễn phí, hạn mức tin cá nhân
  personal('PERSONAL'),

  /// Bán chuyên: nhiều tin hơn mỗi chuyên mục, không có trang cửa hàng
  basic('BASIC'),

  /// Cửa hàng Pro: trang cửa hàng riêng có ảnh bìa (hiện sau khi ReStore
  /// duyệt), xuất hiện ở Shop uy tín khi đã xác minh
  shop('PRO');

  const SubscriptionPlan(this.tier);

  /// Giá trị `StoreTier` ở backend
  final String tier;

  /// Tier không rõ hoặc null là gói Cá nhân
  static SubscriptionPlan fromTier(String? tier) {
    for (final plan in values) {
      if (plan.tier == tier) return plan;
    }
    return personal;
  }

  String label(AppLocalizations l10n) => switch (this) {
    personal => l10n.planPersonal,
    basic => l10n.planBasic,
    shop => l10n.planShop,
  };
}
