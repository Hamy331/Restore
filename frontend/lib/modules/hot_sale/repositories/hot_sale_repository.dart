import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/paged_result.dart';

/// Nguồn dữ liệu trang Hot sale: các tin đang có tin ưu tiên (FEATURED)
abstract class HotSaleRepository {
  /// Số tin mỗi lượt tải (API cho tối đa 20)
  static const int pageSize = 20;

  factory HotSaleRepository() => AppEnvironment.useMockData
      ? MockHotSaleRepository()
      : ApiHotSaleRepository();

  /// Trang [page] (từ 1) của các tin Hot sale
  Future<PagedResult<ListingCardItem>> getPage({int page = 1});

  Future<void> setFavorite(String listingId, bool favorite);
}

/// Đọc dữ liệu mẫu: tin có isFeatured trong dữ liệu trang chủ
class MockHotSaleRepository implements HotSaleRepository {
  MockHotSaleRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  @override
  Future<PagedResult<ListingCardItem>> getPage({int page = 1}) async {
    await Future<void>.delayed(latency);
    final all = [
      for (final json in HomeMockData.listings(DateTime.now()))
        ListingCardItem.fromJson(json),
    ].where((item) => item.isFeatured).toList();
    const size = HotSaleRepository.pageSize;
    final start = (page - 1) * size;
    return PagedResult(
      items: [
        for (final item in all.skip(start).take(size))
          item.copyWith(
            isFavorite: MockFavoriteStore.contains(item.listing.id),
          ),
      ],
      page: page,
      hasMore: start + size < all.length,
    );
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    MockFavoriteStore.set(listingId, favorite);
  }
}

/// Gọi backend:
/// - `GET /listings/recommended?limit=&page=` → `{ data: [Listing] }`
/// - `POST|DELETE /listings/:id/favorite`
class ApiHotSaleRepository implements HotSaleRepository {
  ApiHotSaleRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<PagedResult<ListingCardItem>> getPage({int page = 1}) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/recommended',
      queryParameters: {'limit': HotSaleRepository.pageSize, 'page': page},
    );
    return PagedResult.fromJson(
      response.data ?? const {},
      ListingCardItem.fromJson,
      page: page,
      pageSize: HotSaleRepository.pageSize,
    );
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/$listingId/favorite';
    favorite
        ? await _apiClient.dio.post<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }
}
