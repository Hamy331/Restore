import 'package:flutter/foundation.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/modules/account/repositories/profile_repository.dart';

/// Tài khoản đã đăng ký lên Cửa hàng chưa (kể cả đang chờ duyệt), cho menu
/// nút giữa. Đi theo trạng thái cửa hàng, không theo gói tài khoản.
class ShopSession {
  ShopSession._();

  static final ValueNotifier<bool> hasShop = ValueNotifier(false);

  /// Tải từ /users/me; lỗi (chưa đăng nhập, mất mạng) thì giữ nguyên
  static Future<void> refresh() async {
    if (AppEnvironment.useMockData) return;
    try {
      hasShop.value = (await ApiProfileRepository().getMe()).shopStatus != null;
    } catch (_) {}
  }
}
