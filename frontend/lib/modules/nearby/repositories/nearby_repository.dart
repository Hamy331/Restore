import 'package:restore/core/network/api_client.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/models/geo_point.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/nearby_mock_data.dart';
import '../models/nearby_origin.dart';

/// Nguồn dữ liệu cho trang Gần bạn
abstract class NearbyRepository {
  /// Số tin tối đa mỗi lượt tải
  static const int pageSize = 10;

  /// Khu vực mặc định của tài khoản, dùng khi chưa lấy được GPS
  Future<NearbyOrigin> getDefaultOrigin();

  /// Tin quanh [origin] theo [filter] (bán kính, kiểu giao dịch, sắp xếp),
  /// [page] bắt đầu từ 1. Mỗi tin có sẵn `distanceKm` tính từ [origin].
  Future<PagedResult<ListingCardItem>> getNearby(
    GeoPoint origin,
    ListingFilter filter, {
    int page = 1,
  });

  Future<void> setFavorite(String listingId, bool favorite);
}

/// Đọc dữ liệu mẫu, có độ trễ giả lập để UI xử lý trạng thái tải
class MockNearbyRepository implements NearbyRepository {
  MockNearbyRepository({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;

  @override
  Future<NearbyOrigin> getDefaultOrigin() async =>
      NearbyOrigin.fromJson(NearbyMockData.defaultOrigin);

  @override
  Future<PagedResult<ListingCardItem>> getNearby(
    GeoPoint origin,
    ListingFilter filter, {
    int page = 1,
  }) async {
    await Future<void>.delayed(latency);
    final radius = filter.radiusKm ?? double.infinity;
    final deals = filter.dealTypes;

    final matches = <ListingCardItem>[];
    for (final json in NearbyMockData.listings(DateTime.now(), origin)) {
      final item = ListingCardItem.fromJson(json);
      final listing = item.listing;
      final distance = listing.geoPoint?.distanceTo(origin);
      if (distance == null || distance > radius) continue;
      final dealMatches =
          deals.isEmpty ||
          (deals.contains(ListingDealType.buy) && listing.allowSale) ||
          (deals.contains(ListingDealType.exchange) && listing.allowExchange);
      if (!dealMatches) continue;
      matches.add(
        item.copyWith(
          distanceKm: distance,
          isFavorite: MockFavoriteStore.contains(listing.id),
        ),
      );
    }

    // Tin chỉ trao đổi (không có giá) xếp cuối khi sắp theo giá
    int byPrice(ListingCardItem a, ListingCardItem b, {bool desc = false}) {
      final pa = a.listing.price;
      final pb = b.listing.price;
      if (pa == null || pb == null) {
        return pa == null ? (pb == null ? 0 : 1) : -1;
      }
      return desc ? pb.compareTo(pa) : pa.compareTo(pb);
    }

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    matches.sort(switch (filter.sort) {
      ListingSort.nearest ||
      ListingSort.relevance => (a, b) => a.distanceKm!.compareTo(b.distanceKm!),
      ListingSort.newest => (a, b) => (b.listing.createdAt ?? epoch).compareTo(
        a.listing.createdAt ?? epoch,
      ),
      ListingSort.priceLow => byPrice,
      ListingSort.priceHigh => (a, b) => byPrice(a, b, desc: true),
    });

    const size = NearbyRepository.pageSize;
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

/// Gọi backend:
/// - `GET /users/me/location` → `{ data: { label, latitude, longitude } }`
/// - `GET /listings/nearby?latitude=&longitude=&radiusKm=&deal=&sort=&page=&limit=`
///   → `{ data: [Listing + areaLabel, distanceKm, isFavorite], meta: { hasMore } }`
class ApiNearbyRepository implements NearbyRepository {
  ApiNearbyRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<NearbyOrigin> getDefaultOrigin() async {
    final data = (await _get('/users/me/location'))['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return NearbyOrigin.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<PagedResult<ListingCardItem>> getNearby(
    GeoPoint origin,
    ListingFilter filter, {
    int page = 1,
  }) async {
    final json = await _get(
      '/listings/nearby',
      query: {
        ...origin.toJson(),
        ...filter.toQuery(),
        'page': page,
        'limit': NearbyRepository.pageSize,
      },
    );
    return PagedResult.fromJson(
      json,
      ListingCardItem.fromJson,
      page: page,
      pageSize: NearbyRepository.pageSize,
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
}
