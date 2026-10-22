import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../../models/shop_banner_item.dart';
import '../../models/trusted_shop_item.dart';

enum ShopDetailStatus {
  /// Đang tải trang đầu (lần đầu hoặc vừa đổi bộ lọc)
  loading,
  ready,
  failure,
}

class ShopDetailState extends Equatable {
  /// Cách sắp xếp trang hỗ trợ (không có từ khoá và vị trí)
  static const List<ListingSort> sortOptions = [
    ListingSort.newest,
    ListingSort.priceLow,
    ListingSort.priceHigh,
  ];

  /// Bộ lọc mặc định: mọi tin của shop, mới nhất trước
  static const ListingFilter defaultFilter = ListingFilter();

  final String shopId;

  /// null khi mở bằng đường dẫn và chưa tải xong thông tin shop
  final TrustedShopItem? shop;

  /// Banner sự kiện đang chạy của shop
  final List<ShopBannerItem> banners;
  final ShopDetailStatus status;
  final ListingFilter filter;
  final List<ListingCardItem> items;

  /// Trang cuối đã tải của [items]
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const ShopDetailState({
    required this.shopId,
    this.shop,
    this.banners = const [],
    this.status = ShopDetailStatus.loading,
    this.filter = defaultFilter,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  bool get hasActiveFilters => filter.activeCount(defaultFilter) > 0;

  ShopDetailState copyWith({
    TrustedShopItem? shop,
    List<ShopBannerItem>? banners,
    ShopDetailStatus? status,
    ListingFilter? filter,
    List<ListingCardItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => ShopDetailState(
    shopId: shopId,
    shop: shop ?? this.shop,
    banners: banners ?? this.banners,
    status: status ?? this.status,
    filter: filter ?? this.filter,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    shopId,
    shop,
    banners,
    status,
    filter,
    items,
    page,
    hasMore,
    isLoadingMore,
  ];
}
