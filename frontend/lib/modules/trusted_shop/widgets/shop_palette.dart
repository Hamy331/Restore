import 'package:flutter/material.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/data/models/shop_model.dart';

import 'shop_logo.dart';

/// Màu điểm nhấn trên trang shop lấy theo màu nhận diện (cột accentColor):
/// nút, ô số liệu, link. Đầu trang vẫn giữ màu chung của app cho đồng bộ.
/// Chưa có thông tin shop thì dùng màu kem chung.
class ShopPalette {
  /// Màu nhận diện, null khi chưa tải xong shop
  final Color? accent;

  const ShopPalette._(this.accent);

  factory ShopPalette.of(ShopModel? shop) =>
      ShopPalette._(shop == null ? null : ShopLogo.accentOf(shop));

  /// Nền nhạt cho thẻ / khối trong trang
  Color get soft => accent == null
      ? AppHeaderPalette.top
      : Color.lerp(Colors.white, accent, 0.07)!;
}
