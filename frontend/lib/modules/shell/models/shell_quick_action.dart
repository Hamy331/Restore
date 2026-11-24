import 'package:flutter/widgets.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Nút tròn xoè ra quanh nút giữa thanh điều hướng của tài khoản có gói trả
/// phí hoặc đã lên Cửa hàng. Gói Cá nhân chưa có cửa hàng không có menu này,
/// nút giữa vẫn là dấu + mở luồng đăng tin.
enum ShellQuickAction {
  /// Đăng tin bán như nút + thường
  post,

  /// Đăng poster quảng bá shop lên banner trang chủ
  poster,

  /// Đẩy tin đang hiển thị lên đầu
  boost,

  /// Thống kê lượt xem, lượt quan tâm
  stats,

  /// Quản lý shop: thông tin, logo, ảnh bìa, màu nhận diện của shop mình
  shopManage;

  IconData get icon => switch (this) {
    post => AppIcons.add,
    poster => AppIcons.posterPromo,
    boost => AppIcons.boost,
    stats => AppIcons.stats,
    shopManage => AppIcons.shop,
  };

  String label(AppLocalizations l10n) => switch (this) {
    post => l10n.quickActionPost,
    poster => l10n.quickActionPoster,
    boost => l10n.quickActionBoost,
    stats => l10n.quickActionStats,
    shopManage => l10n.quickActionShopManage,
  };

  /// Nút nổi bật (tô cam) trong menu: quyền lợi chính của gói
  bool get highlighted => this == poster;

  /// Các nút xếp từ trái sang phải trên vòng cung. Cửa hàng (gói nào cũng
  /// được) có Poster shop và Quản lý shop; gói trả phí có Đẩy tin, Thống kê.
  /// Danh sách rỗng nghĩa là nút giữa chỉ là dấu + thường.
  static List<ShellQuickAction> forAccount(
    SubscriptionPlan plan, {
    bool hasShop = false,
  }) {
    if (hasShop) return const [post, poster, boost, shopManage];
    return plan == SubscriptionPlan.personal
        ? const []
        : const [post, boost, stats];
  }
}
