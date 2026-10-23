import 'package:restore/l10n/app_localizations.dart';

/// Gói đăng ký của tài khoản (đề xuất bảng subscriptions ở backend). Loại
/// tài khoản và quyền lợi đi theo gói, không hỏi lại khi đăng tin.
enum SubscriptionPlan {
  /// Miễn phí, hạn mức tin cá nhân
  personal('PERSONAL'),

  /// Bán chuyên: nhiều tin hơn mỗi chuyên mục, huy hiệu bán chuyên
  pro('PRO'),

  /// Cửa hàng: trang shop riêng, có thể xuất hiện ở Shop uy tín khi đã
  /// xác minh
  shop('SHOP');

  const SubscriptionPlan(this.apiValue);

  final String apiValue;

  static SubscriptionPlan fromApi(String? value) {
    for (final plan in values) {
      if (plan.apiValue == value) return plan;
    }
    return personal;
  }

  String label(AppLocalizations l10n) => switch (this) {
    personal => l10n.planPersonal,
    pro => l10n.planPro,
    shop => l10n.planShop,
  };
}
