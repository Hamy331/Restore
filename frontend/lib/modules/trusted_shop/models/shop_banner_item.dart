import 'package:equatable/equatable.dart';
import 'package:restore/data/models/shop_banner_model.dart';
import 'package:restore/data/models/shop_model.dart';

/// Banner kèm shop đăng nó (logo, tên, màu) để vẽ và mở trang shop khi bấm.
/// API trả về bản ghi ShopBanner cùng khoá `shop`.
class ShopBannerItem extends Equatable {
  final ShopBannerModel banner;
  final ShopModel shop;

  const ShopBannerItem({required this.banner, required this.shop});

  factory ShopBannerItem.fromJson(Map<String, dynamic> json) => ShopBannerItem(
    banner: ShopBannerModel.fromJson(json),
    shop: ShopModel.fromJson(Map<String, dynamic>.from(json['shop'] as Map)),
  );

  @override
  List<Object?> get props => [banner, shop];
}
