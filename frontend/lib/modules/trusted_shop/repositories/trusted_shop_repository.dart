import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/data/models/enums/shop_verification_type.dart';
import 'package:restore/data/models/shop_banner_model.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/data/listing_filter_mock_data.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/trusted_shop_mock_data.dart';
import '../models/shop_banner_item.dart';
import '../models/shop_product_item.dart';
import '../models/trusted_shop_item.dart';
import '../models/trusted_shops_overview.dart';

/// Nguồn dữ liệu cho trang Shop uy tín và trang của từng shop
abstract class TrustedShopRepository {
  /// Số tin tối đa mỗi lượt tải
  static const int pageSize = 10;

  /// Số tin trong mỗi khối "sản phẩm tiêu biểu" của một shop
  static const int showcaseSize = 6;

  /// Mọi khu của trang Shop uy tín trừ lưới "Tất cả sản phẩm"
  Future<TrustedShopsOverview> getOverview();

  /// Tin của mọi shop uy tín theo [filter], [page] bắt đầu từ 1.
  /// [onSale] chỉ lấy tin đang giảm giá.
  Future<PagedResult<ListingCardItem>> getListings(
    ListingFilter filter, {
    int page = 1,
    bool onSale = false,
  });

  Future<TrustedShopItem> getShop(String shopId);

  /// Banner sự kiện đang chạy của shop [shopId]
  Future<List<ShopBannerItem>> getShopBanners(String shopId);

  /// Tin đang bán của shop [shopId] theo [filter], [page] bắt đầu từ 1
  Future<PagedResult<ListingCardItem>> getShopListings(
    String shopId,
    ListingFilter filter, {
    int page = 1,
  });

  Future<void> setFollowing(String shopId, bool following);

  Future<void> setFavorite(String listingId, bool favorite);
}

/// Đọc dữ liệu mẫu, có độ trễ giả lập để UI xử lý trạng thái tải
class MockTrustedShopRepository implements TrustedShopRepository {
  MockTrustedShopRepository({this.latency = const Duration(milliseconds: 450)});

  final Duration latency;

  /// Shop đã xác minh, thêm số tin và trạng thái theo dõi
  List<TrustedShopItem> _shops() => [
    for (final json in TrustedShopMockData.shops)
      TrustedShopItem.fromJson(TrustedShopMockData.shopJson(json)),
  ];

  /// Tin mẫu khớp [filter], của shop [shopId] nếu có, đã sắp xếp
  List<ListingCardItem> _listings(
    ListingFilter filter, {
    String? shopId,
    bool onSale = false,
  }) {
    final matches = <ListingCardItem>[];
    for (final json in TrustedShopMockData.listings(DateTime.now())) {
      if (shopId != null && json['shopId'] != shopId) continue;
      final item = ListingCardItem.fromJson(json);
      if (!filter.matches(item.listing)) continue;
      if (onSale && item.listing.discountPercent == null) continue;
      matches.add(
        item.copyWith(isFavorite: MockFavoriteStore.contains(item.listing.id)),
      );
    }

    int byPrice(ListingCardItem a, ListingCardItem b, {bool desc = false}) {
      final pa = a.listing.price ?? 0;
      final pb = b.listing.price ?? 0;
      return desc ? pb.compareTo(pa) : pa.compareTo(pb);
    }

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    int byNewest(ListingCardItem a, ListingCardItem b) =>
        (b.listing.createdAt ?? epoch).compareTo(a.listing.createdAt ?? epoch);

    return matches..sort(switch (filter.sort) {
      ListingSort.priceLow => byPrice,
      ListingSort.priceHigh => (a, b) => byPrice(a, b, desc: true),
      ListingSort.newest ||
      ListingSort.nearest ||
      ListingSort.relevance => byNewest,
    });
  }

  PagedResult<ListingCardItem> _page(List<ListingCardItem> items, int page) {
    const size = TrustedShopRepository.pageSize;
    final start = (page - 1) * size;
    return PagedResult(
      items: items.skip(start).take(size).toList(),
      page: page,
      hasMore: start + size < items.length,
    );
  }

  /// Shop mẫu theo id, đã kèm số tin và trạng thái theo dõi
  Map<String, TrustedShopItem> get _shopsById => {
    for (final item in _shops()) item.shop.id: item,
  };

  @override
  Future<TrustedShopsOverview> getOverview() async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    final shops = _shops();
    final byId = _shopsById;
    const filter = ListingFilter();
    final listings = _listings(filter);

    int byFollowers(TrustedShopItem a, TrustedShopItem b) =>
        b.shop.followerCount.compareTo(a.shop.followerCount);

    // Mới gia nhập: xác minh trong 6 tháng gần nhất, mới nhất trước
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final newShops = [
      for (final item in shops)
        if (now.difference(item.shop.verifiedAt ?? epoch).inDays <= 180) item,
    ]..sort((a, b) => b.shop.verifiedAt!.compareTo(a.shop.verifiedAt!));

    final deals =
        [
          for (final item in listings)
            if (item.listing.discountPercent != null) item,
        ]..sort(
          (a, b) =>
              b.listing.discountPercent!.compareTo(a.listing.discountPercent!),
        );

    final listingShop = {
      for (final json in TrustedShopMockData.listings(now))
        json['id'] as String: json['shopId'] as String,
    };

    return TrustedShopsOverview(
      shopCount: shops.length,
      listingCount: listings.length,
      categories: [
        for (final json in TrustedShopMockData.categories())
          CategoryModel.fromJson(json),
      ],
      banners: [
        for (final json in TrustedShopMockData.banners(now))
          ShopBannerItem(
            banner: ShopBannerModel.fromJson(json),
            shop: byId[json['shopId']]!.shop,
          ),
      ],
      famousShops: [
        for (final item in shops)
          if (item.shop.verificationType == ShopVerificationType.officialBrand)
            item,
      ]..sort(byFollowers),
      newShops: newShops,
      deals: deals.take(8).toList(),
      newReleases: [
        for (final item in listings)
          if (TrustedShopMockData.isNewRelease(item.listing.id))
            ShopProductItem(
              item: item,
              shop: byId[listingShop[item.listing.id]]!.shop,
            ),
      ],
      // Khối sản phẩm: 3 shop nhiều người theo dõi nhất
      showcases: [
        for (final item in ([...shops]..sort(byFollowers)).take(3))
          ShopShowcase(
            shop: item,
            listings: _listings(
              filter,
              shopId: item.shop.id,
            ).take(TrustedShopRepository.showcaseSize).toList(),
          ),
      ],
    );
  }

  @override
  Future<PagedResult<ListingCardItem>> getListings(
    ListingFilter filter, {
    int page = 1,
    bool onSale = false,
  }) async {
    await Future<void>.delayed(latency);
    return _page(_listings(filter, onSale: onSale), page);
  }

  @override
  Future<TrustedShopItem> getShop(String shopId) async {
    await Future<void>.delayed(latency);
    return _shops().firstWhere(
      (item) => item.shop.id == shopId,
      orElse: () => throw StateError('Shop $shopId not found'),
    );
  }

  @override
  Future<List<ShopBannerItem>> getShopBanners(String shopId) async {
    await Future<void>.delayed(latency);
    final shop = _shopsById[shopId]?.shop;
    if (shop == null) return const [];
    return [
      for (final json in TrustedShopMockData.banners(DateTime.now()))
        if (json['shopId'] == shopId)
          ShopBannerItem(banner: ShopBannerModel.fromJson(json), shop: shop),
    ];
  }

  @override
  Future<PagedResult<ListingCardItem>> getShopListings(
    String shopId,
    ListingFilter filter, {
    int page = 1,
  }) async {
    await Future<void>.delayed(latency);
    return _page(_listings(filter, shopId: shopId), page);
  }

  @override
  Future<void> setFollowing(String shopId, bool following) async {
    following
        ? TrustedShopMockData.followingShopIds.add(shopId)
        : TrustedShopMockData.followingShopIds.remove(shopId);
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    MockFavoriteStore.set(listingId, favorite);
  }
}

/// Gọi backend (chi tiết trong `backend/docs/trusted-shops.md`):
/// - `GET /shops/trusted/overview` → `{ data: { stats, categories,
///   banners: [ShopBanner + shop], famousShops, newShops: [Shop +
///   isFollowing], deals: [Listing], newReleases: [Listing + shop],
///   showcases: [{ shop, listings }] } }`
/// - `GET /listings?verifiedShop=true&onSale=&categoryId=&sort=&page=&limit=`
/// - `GET /shops/:id` → `{ data: Shop + isFollowing }`
/// - `GET /shops/:id/banners` → `{ data: [ShopBanner + shop] }`
/// - `GET /shops/:id/listings?categoryId=&deal=&sort=&minPrice=&maxPrice=
///   &condition=&page=&limit=`
/// - `POST /shops/:id/follow`, `DELETE /shops/:id/follow`
class ApiTrustedShopRepository implements TrustedShopRepository {
  ApiTrustedShopRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> _getData(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return Map<String, dynamic>.from(data);
  }

  Future<PagedResult<ListingCardItem>> _getPage(
    String path,
    Map<String, dynamic> query,
    int page,
  ) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {
        ...query,
        'page': page,
        'limit': TrustedShopRepository.pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data ?? const {},
      ListingCardItem.fromJson,
      page: page,
      pageSize: TrustedShopRepository.pageSize,
    );
  }

  @override
  Future<TrustedShopsOverview> getOverview() async =>
      TrustedShopsOverview.fromJson(await _getData('/shops/trusted/overview'));

  @override
  Future<PagedResult<ListingCardItem>> getListings(
    ListingFilter filter, {
    int page = 1,
    bool onSale = false,
  }) => _getPage('/listings', {
    ...filter.toQuery(),
    'verifiedShop': true,
    if (onSale) 'onSale': true,
  }, page);

  @override
  Future<TrustedShopItem> getShop(String shopId) async =>
      TrustedShopItem.fromJson(await _getData('/shops/$shopId'));

  @override
  Future<List<ShopBannerItem>> getShopBanners(String shopId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/shops/$shopId/banners',
    );
    return [
      for (final json in response.data?['data'] as List? ?? const [])
        ShopBannerItem.fromJson(Map<String, dynamic>.from(json as Map)),
    ];
  }

  @override
  Future<PagedResult<ListingCardItem>> getShopListings(
    String shopId,
    ListingFilter filter, {
    int page = 1,
  }) => _getPage('/shops/$shopId/listings', filter.toQuery(), page);

  @override
  Future<void> setFollowing(String shopId, bool following) async {
    final path = '/shops/$shopId/follow';
    following
        ? await _apiClient.dio.post<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/$listingId/favorite';
    favorite
        ? await _apiClient.dio.post<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }
}
