import 'package:equatable/equatable.dart';
import 'package:restore/data/models/shop_model.dart';

/// Shop kèm trạng thái người xem đang theo dõi hay chưa.
/// API trả về một bản ghi Shop cùng trường `isFollowing` đã tính sẵn.
class TrustedShopItem extends Equatable {
  final ShopModel shop;
  final bool isFollowing;

  const TrustedShopItem({required this.shop, this.isFollowing = false});

  factory TrustedShopItem.fromJson(Map<String, dynamic> json) =>
      TrustedShopItem(
        shop: ShopModel.fromJson(json),
        isFollowing: json['isFollowing'] as bool? ?? false,
      );

  /// Đổi trạng thái theo dõi, số người theo dõi tăng / giảm theo
  TrustedShopItem withFollowing(bool following) {
    if (following == isFollowing) return this;
    final count = shop.followerCount + (following ? 1 : -1);
    return TrustedShopItem(
      shop: shop.copyWith(followerCount: count < 0 ? 0 : count),
      isFollowing: following,
    );
  }

  @override
  List<Object?> get props => [shop, isFollowing];
}
