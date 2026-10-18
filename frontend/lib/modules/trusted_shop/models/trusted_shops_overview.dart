import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/shared/models/listing_card_item.dart';

import 'shop_banner_item.dart';
import 'shop_product_item.dart';
import 'trusted_shop_item.dart';

/// Một shop cùng vài sản phẩm tiêu biểu, hiện thành một khối trên trang
/// Shop uy tín
class ShopShowcase extends Equatable {
  final TrustedShopItem shop;
  final List<ListingCardItem> listings;

  const ShopShowcase({required this.shop, required this.listings});

  factory ShopShowcase.fromJson(Map<String, dynamic> json) => ShopShowcase(
    shop: TrustedShopItem.fromJson(
      Map<String, dynamic>.from(json['shop'] as Map),
    ),
    listings: [
      for (final listing in json['listings'] as List? ?? const [])
        ListingCardItem.fromJson(Map<String, dynamic>.from(listing as Map)),
    ],
  );

  ShopShowcase copyWith({
    TrustedShopItem? shop,
    List<ListingCardItem>? listings,
  }) => ShopShowcase(
    shop: shop ?? this.shop,
    listings: listings ?? this.listings,
  );

  @override
  List<Object?> get props => [shop, listings];
}

/// Mọi khu của trang Shop uy tín trừ lưới "Tất cả sản phẩm", nhận từ
/// `GET /shops/trusted/overview` trong một lần gọi.
class TrustedShopsOverview extends Equatable {
  /// Số shop đã xác minh và số sản phẩm đang bán của các shop đó
  final int shopCount;
  final int listingCount;

  /// Danh mục có ít nhất một shop uy tín, làm chip lọc lưới sản phẩm
  final List<CategoryModel> categories;

  /// Banner sự kiện shop gửi lên, đã được admin duyệt và đang chạy
  final List<ShopBannerItem> banners;

  /// "Thương hiệu nổi tiếng": shop chính hãng nhiều người theo dõi nhất
  final List<TrustedShopItem> famousShops;

  /// "Mới gia nhập": shop vừa được xác minh, mới nhất trước
  final List<TrustedShopItem> newShops;

  /// "Trải nghiệm hàng hiệu": sản phẩm của shop uy tín đang giảm giá
  final List<ListingCardItem> deals;

  /// "Siêu phẩm mới ra mắt": sản phẩm mới của các thương hiệu lớn
  final List<ShopProductItem> newReleases;

  /// "Sản phẩm theo nhãn hàng": vài sản phẩm tiêu biểu của từng shop
  final List<ShopShowcase> showcases;

  const TrustedShopsOverview({
    this.shopCount = 0,
    this.listingCount = 0,
    this.categories = const [],
    this.banners = const [],
    this.famousShops = const [],
    this.newShops = const [],
    this.deals = const [],
    this.newReleases = const [],
    this.showcases = const [],
  });

  factory TrustedShopsOverview.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) => [
      for (final item in json[key] as List? ?? const [])
        fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    final stats = json['stats'];
    return TrustedShopsOverview(
      shopCount: stats is Map ? (stats['shopCount'] as num?)?.toInt() ?? 0 : 0,
      listingCount: stats is Map
          ? (stats['listingCount'] as num?)?.toInt() ?? 0
          : 0,
      categories: list('categories', CategoryModel.fromJson),
      banners: list('banners', ShopBannerItem.fromJson),
      famousShops: list('famousShops', TrustedShopItem.fromJson),
      newShops: list('newShops', TrustedShopItem.fromJson),
      deals: list('deals', ListingCardItem.fromJson),
      newReleases: list('newReleases', ShopProductItem.fromJson),
      showcases: list('showcases', ShopShowcase.fromJson),
    );
  }

  bool get isEmpty =>
      famousShops.isEmpty && newShops.isEmpty && showcases.isEmpty;

  /// Cập nhật trạng thái theo dõi của shop [shopId] ở mọi khu
  TrustedShopsOverview withFollowing(String shopId, bool following) {
    TrustedShopItem update(TrustedShopItem item) =>
        item.shop.id == shopId ? item.withFollowing(following) : item;
    return copyWith(
      famousShops: [for (final item in famousShops) update(item)],
      newShops: [for (final item in newShops) update(item)],
      showcases: [
        for (final showcase in showcases)
          showcase.copyWith(shop: update(showcase.shop)),
      ],
    );
  }

  /// Cập nhật trạng thái lưu tin ở mọi khu có thẻ sản phẩm
  TrustedShopsOverview withFavorite(String listingId, bool favorite) {
    ListingCardItem update(ListingCardItem item) => item.listing.id == listingId
        ? item.copyWith(isFavorite: favorite)
        : item;
    return copyWith(
      deals: [for (final item in deals) update(item)],
      newReleases: [
        for (final product in newReleases)
          product.copyWith(item: update(product.item)),
      ],
      showcases: [
        for (final showcase in showcases)
          showcase.copyWith(
            listings: [for (final item in showcase.listings) update(item)],
          ),
      ],
    );
  }

  TrustedShopsOverview copyWith({
    List<TrustedShopItem>? famousShops,
    List<TrustedShopItem>? newShops,
    List<ListingCardItem>? deals,
    List<ShopProductItem>? newReleases,
    List<ShopShowcase>? showcases,
  }) => TrustedShopsOverview(
    shopCount: shopCount,
    listingCount: listingCount,
    categories: categories,
    banners: banners,
    famousShops: famousShops ?? this.famousShops,
    newShops: newShops ?? this.newShops,
    deals: deals ?? this.deals,
    newReleases: newReleases ?? this.newReleases,
    showcases: showcases ?? this.showcases,
  );

  @override
  List<Object?> get props => [
    shopCount,
    listingCount,
    categories,
    banners,
    famousShops,
    newShops,
    deals,
    newReleases,
    showcases,
  ];
}
