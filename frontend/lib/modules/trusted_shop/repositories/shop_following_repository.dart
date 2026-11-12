import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/trusted_shop_mock_data.dart';
import '../models/followed_shop.dart';
import '../models/trusted_shop_item.dart';

/// Shop mình đang theo dõi, tin mới của các shop đó và người theo dõi shop
/// của mình.
abstract class ShopFollowingRepository {
  static const int pageSize = 20;

  /// Mock khi chạy với dữ liệu mẫu, còn lại gọi API
  factory ShopFollowingRepository() => AppEnvironment.useMockData
      ? MockShopFollowingRepository()
      : ApiShopFollowingRepository();

  /// Shop uy tín đang theo dõi, theo dõi gần nhất trước. [page] từ 1.
  Future<PagedResult<FollowedShop>> followedShops({int page = 1});

  /// Tin mới nhất của các shop đang theo dõi
  Future<PagedResult<ListingCardItem>> followedListings({int page = 1});

  /// Người đang theo dõi shop của mình (trang Quản lý shop)
  Future<PagedResult<ShopFollower>> myFollowers({int page = 1});

  /// Shop gợi ý theo dõi, hợp sở thích trước
  Future<List<ShopSuggestion>> suggestions({int limit = 10});

  /// Tin mới nhất của một shop (lọc theo shop ở trang Đang theo dõi)
  Future<PagedResult<ListingCardItem>> shopListings(
    String shopId, {
    int page = 1,
  });

  Future<void> setFollowing(String shopId, bool following);

  Future<void> setFavorite(String listingId, bool favorite);
}

/// Đọc [TrustedShopMockData], dùng chung tập shop đang theo dõi với trang
/// Shop uy tín.
class MockShopFollowingRepository implements ShopFollowingRepository {
  MockShopFollowingRepository({
    this.latency = const Duration(milliseconds: 350),
  });

  final Duration latency;

  /// Người theo dõi mẫu của shop mình
  static const _followers = [
    ('u_mai', 'Nguyễn Thị Mai', 'maing'),
    ('u_khoa', 'Trần Minh Khoa', 'khoatm'),
    ('u_linh', 'Phạm Thuỳ Linh', 'linhpham'),
    ('u_duc', 'Lê Anh Đức', 'ducle'),
  ];

  PagedResult<T> _page<T>(List<T> items, int page) {
    const size = ShopFollowingRepository.pageSize;
    final start = (page - 1) * size;
    return PagedResult(
      items: items.skip(start).take(size).toList(),
      page: page,
      hasMore: start + size < items.length,
      totalItems: items.length,
    );
  }

  List<Map<String, dynamic>> _followedListings(DateTime now) => [
    for (final json in TrustedShopMockData.listings(now))
      if (TrustedShopMockData.followingShopIds.contains(json['shopId'])) json,
  ];

  @override
  Future<PagedResult<FollowedShop>> followedShops({int page = 1}) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    final fresh = <String, int>{};
    for (final json in _followedListings(now)) {
      final created = DateTime.parse(json['createdAt'] as String);
      if (now.difference(created).inDays < 7) {
        fresh.update(json['shopId'] as String, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final ids = TrustedShopMockData.followingShopIds.toList().reversed;
    final shops = [
      for (final id in ids)
        for (final json in TrustedShopMockData.shops)
          if (json['id'] == id)
            FollowedShop.fromJson({
              ...TrustedShopMockData.shopJson(json),
              'newListingCount': fresh[id] ?? 0,
            }),
    ];
    return _page(shops, page);
  }

  @override
  Future<PagedResult<ListingCardItem>> followedListings({int page = 1}) async {
    await Future<void>.delayed(latency);
    return _page(_cards(_followedListings(DateTime.now())), page);
  }

  List<ListingCardItem> _cards(Iterable<Map<String, dynamic>> listings) {
    final items = [
      for (final json in listings)
        ListingCardItem.fromJson(
          json,
        ).copyWith(isFavorite: MockFavoriteStore.contains('${json['id']}')),
    ];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return items..sort(
      (a, b) => (b.listing.createdAt ?? epoch).compareTo(
        a.listing.createdAt ?? epoch,
      ),
    );
  }

  @override
  Future<List<ShopSuggestion>> suggestions({int limit = 10}) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    final shops = [
      for (final json in TrustedShopMockData.shops)
        if (!TrustedShopMockData.followingShopIds.contains(json['id'])) json,
    ];
    return [
      for (var i = 0; i < shops.length && i < limit; i++)
        ShopSuggestion(
          item: TrustedShopItem.fromJson(
            TrustedShopMockData.shopJson(shops[i]),
          ),
          // Mẫu: hai shop đầu hợp sở thích, shop chính hãng là đối tác
          reason: i < 2
              ? ShopSuggestionReason.matchesInterest
              : shops[i]['verificationType'] == 'OFFICIAL_BRAND'
              ? ShopSuggestionReason.partner
              : ShopSuggestionReason.popular,
          isPartner: shops[i]['verificationType'] == 'OFFICIAL_BRAND',
          previews: _cards([
            for (final json in TrustedShopMockData.listings(now))
              if (json['shopId'] == shops[i]['id']) json,
          ]).take(3).toList(),
        ),
    ];
  }

  @override
  Future<PagedResult<ListingCardItem>> shopListings(
    String shopId, {
    int page = 1,
  }) async {
    await Future<void>.delayed(latency);
    return _page(
      _cards([
        for (final json in TrustedShopMockData.listings(DateTime.now()))
          if (json['shopId'] == shopId) json,
      ]),
      page,
    );
  }

  @override
  Future<PagedResult<ShopFollower>> myFollowers({int page = 1}) async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    return _page([
      for (var i = 0; i < _followers.length; i++)
        ShopFollower(
          id: _followers[i].$1,
          fullName: _followers[i].$2,
          username: _followers[i].$3,
          followedAt: now.subtract(Duration(days: i * 3 + 1)),
        ),
    ], page);
  }

  @override
  Future<void> setFollowing(String shopId, bool following) async {
    following
        ? TrustedShopMockData.followingShopIds.add(shopId)
        : TrustedShopMockData.followingShopIds.remove(shopId);
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async =>
      MockFavoriteStore.set(listingId, favorite);
}

/// Gọi backend:
/// - `GET /shops/following?page=&limit=` → `{ data: [Shop + isFollowing +
///   followedAt + newListingCount], pagination }`
/// - `GET /shops/following/listings?page=&limit=` → thẻ tin như trang chủ
/// - `GET /shops/following/suggestions?limit=` → `{ data: [Shop +
///   isFollowing + isPartner + reason + previews] }`
/// - `GET /shops/:id/listings?page=&limit=` → tin mới nhất của một shop
/// - `GET /shops/me/followers?page=&limit=` → `{ data: [{ id, fullName,
///   username, avatarUrl, followedAt }], pagination }`
/// - `POST|DELETE /shops/:id/follow`, `POST|DELETE /listings/:id/favorite`
class ApiShopFollowingRepository implements ShopFollowingRepository {
  ApiShopFollowingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PagedResult<T>> _get<T>(
    String path,
    int page,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    const size = ShopFollowingRepository.pageSize;
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {'page': page, 'limit': size},
    );
    return PagedResult.fromJson(
      response.data ?? const {},
      fromJson,
      page: page,
      pageSize: size,
    );
  }

  @override
  Future<PagedResult<FollowedShop>> followedShops({int page = 1}) =>
      _get('/shops/following', page, FollowedShop.fromJson);

  @override
  Future<PagedResult<ListingCardItem>> followedListings({int page = 1}) =>
      _get('/shops/following/listings', page, ListingCardItem.fromJson);

  @override
  Future<PagedResult<ShopFollower>> myFollowers({int page = 1}) =>
      _get('/shops/me/followers', page, ShopFollower.fromJson);

  @override
  Future<List<ShopSuggestion>> suggestions({int limit = 10}) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/shops/following/suggestions',
      queryParameters: {'limit': limit},
    );
    return [
      for (final json in response.data?['data'] as List? ?? const [])
        ShopSuggestion.fromJson(Map<String, dynamic>.from(json as Map)),
    ];
  }

  @override
  Future<PagedResult<ListingCardItem>> shopListings(
    String shopId, {
    int page = 1,
  }) => _get('/shops/$shopId/listings', page, ListingCardItem.fromJson);

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
