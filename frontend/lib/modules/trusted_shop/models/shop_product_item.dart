import 'package:equatable/equatable.dart';
import 'package:restore/data/models/shop_model.dart';
import 'package:restore/shared/models/listing_card_item.dart';

/// Sản phẩm kèm shop bán nó, cho các thẻ lớn cần hiện logo và tên thương
/// hiệu (VD "Siêu phẩm mới ra mắt"). API trả về tin đăng cùng khoá `shop`.
class ShopProductItem extends Equatable {
  final ListingCardItem item;
  final ShopModel shop;

  const ShopProductItem({required this.item, required this.shop});

  factory ShopProductItem.fromJson(Map<String, dynamic> json) =>
      ShopProductItem(
        item: ListingCardItem.fromJson(json),
        shop: ShopModel.fromJson(
          Map<String, dynamic>.from(json['shop'] as Map),
        ),
      );

  ShopProductItem copyWith({ListingCardItem? item}) =>
      ShopProductItem(item: item ?? this.item, shop: shop);

  @override
  List<Object?> get props => [item, shop];
}
