import 'package:restore/shared/models/geo_point.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/home_mock_data.dart';
import '../models/home_banner.dart';
import '../models/home_listing_filter.dart';
import 'package:restore/shared/models/listing_card_item.dart';

/// Nguồn dữ liệu cho trang chủ (danh mục lấy từ CategoryRepository, khu vực
/// từ UserAreaCubit)
abstract class HomeRepository {
  /// Số tin tối đa mỗi lượt tải
  static const int pageSize = 10;

  Future<List<HomeBanner>> getBanners();

  /// Tin gợi ý riêng cho người dùng (tối đa [pageSize] tin)
  Future<List<ListingCardItem>> getRecommended();

  /// Tin theo bộ lọc, [page] bắt đầu từ 1
  Future<PagedResult<ListingCardItem>> getLatest(
    HomeListingFilter filter, {
    int page = 1,
    GeoPoint? origin,
  });
  Future<void> setFavorite(String listingId, bool favorite);
}

/// Đọc dữ liệu mẫu, có độ trễ giả lập để UI xử lý trạng thái tải
class MockHomeRepository implements HomeRepository {
  MockHomeRepository({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;

  List<ListingCardItem> _items() => [
    for (final json in HomeMockData.listings(DateTime.now()))
      ListingCardItem.fromJson(
        json,
      ).copyWith(isFavorite: MockFavoriteStore.contains('${json['id']}')),
  ];

  @override
  Future<List<HomeBanner>> getBanners() async {
    await Future<void>.delayed(latency);
    return HomeMockData.banners.map(HomeBanner.fromJson).toList();
  }

  @override
  Future<List<ListingCardItem>> getRecommended() async {
    await Future<void>.delayed(latency);
    return _items()
        .where((item) => item.isFeatured)
        .take(HomeRepository.pageSize)
        .toList();
  }

  @override
  Future<PagedResult<ListingCardItem>> getLatest(
    HomeListingFilter filter, {
    int page = 1,
    GeoPoint? origin,
  }) async {
    await Future<void>.delayed(latency);
    final matches = _items().where((item) {
      return switch (filter) {
        HomeListingFilter.forYou || HomeListingFilter.newest => true,
        HomeListingFilter.nearby => (item.distanceKm ?? double.infinity) <= 5,
        HomeListingFilter.certified => item.listing.isPartner,
        HomeListingFilter.free => item.listing.isFree,
        // Dữ liệu mẫu không có danh sách theo dõi
        HomeListingFilter.following => false,
      };
    }).toList();
    if (filter == HomeListingFilter.nearby) {
      matches.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    }
    if (filter == HomeListingFilter.newest) {
      matches.sort(
        (a, b) => (b.listing.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
          a.listing.createdAt?.millisecondsSinceEpoch ?? 0,
        ),
      );
    }
    const size = HomeRepository.pageSize;
    final start = (page - 1) * size;
    return PagedResult(
      items: matches.skip(start).take(size).toList(),
      page: page,
      hasMore: start + size < matches.length,
    );
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    MockFavoriteStore.set(listingId, favorite);
  }
}

/// Gọi backend; mỗi item là một bản ghi Listing kèm areaLabel, distanceKm,
/// isFeatured, isFavorite đã tính sẵn ở server.
class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Tin đang bán của [ownerId]; [query] lọc theo tiêu đề, [sort] theo giá
  /// (bỏ trống giữ thứ tự mới nhất)
  Future<PagedResult<ListingCardItem>> sellerListings(
    String ownerId,
    int page, {
    String query = '',
    String? sort,
    bool sold = false,
  }) async {
    final json = await _get(
      '/listings',
      query: {
        'ownerId': ownerId,
        'filter': 'recent',
        if (sold) 'sold': 'true',
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (sort != null) 'sort': sort,
        'page': page,
        'limit': HomeRepository.pageSize,
      },
    );
    return PagedResult.fromJson(
      json,
      ListingCardItem.fromJson,
      page: page,
      pageSize: HomeRepository.pageSize,
    );
  }

  @override
  Future<List<HomeBanner>> getBanners() async =>
      _list(await _get('/home/banners'), HomeBanner.fromJson);

  @override
  Future<List<ListingCardItem>> getRecommended() async => _list(
    await _get(
      '/listings/recommended',
      query: const {'limit': HomeRepository.pageSize},
    ),
    ListingCardItem.fromJson,
  );

  @override
  Future<PagedResult<ListingCardItem>> getLatest(
    HomeListingFilter filter, {
    int page = 1,
    GeoPoint? origin,
  }) async {
    final json = await _get(
      '/listings',
      query: {
        'filter': filter.apiValue,
        ...?origin?.toJson(),
        'page': page,
        'limit': HomeRepository.pageSize,
      },
    );
    return PagedResult.fromJson(
      json,
      ListingCardItem.fromJson,
      page: page,
      pageSize: HomeRepository.pageSize,
    );
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/$listingId/favorite';
    favorite
        ? await _apiClient.dio.post<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return response.data ?? const {};
  }

  List<T> _list<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = json['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [
      for (final item in data) fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
