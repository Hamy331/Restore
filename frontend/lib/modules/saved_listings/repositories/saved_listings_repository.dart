import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/recently_viewed_store.dart';

/// Nguồn dữ liệu trang Tin đã lưu
abstract class SavedListingsRepository {
  static const int pageSize = 20;

  factory SavedListingsRepository() => AppEnvironment.useMockData
      ? MockSavedListingsRepository()
      : ApiSavedListingsRepository();

  /// Nguồn cho trang Xem gần đây (cùng giao diện với Tin đã lưu)
  factory SavedListingsRepository.recentlyViewed() => AppEnvironment.useMockData
      ? MockRecentlyViewedRepository()
      : ApiRecentlyViewedRepository();

  /// Trang [page] (từ 1) của các tin đã lưu, mới lưu trước
  Future<PagedResult<ListingCardItem>> getPage({int page = 1});

  Future<void> setFavorite(String listingId, bool favorite);
}

/// Tin mẫu trang chủ có id nằm trong MockFavoriteStore
class MockSavedListingsRepository implements SavedListingsRepository {
  MockSavedListingsRepository({
    this.latency = const Duration(milliseconds: 300),
  });

  final Duration latency;

  @override
  Future<PagedResult<ListingCardItem>> getPage({int page = 1}) async {
    await Future<void>.delayed(latency);
    final saved = [
      for (final json in HomeMockData.listings(DateTime.now()))
        if (MockFavoriteStore.contains('${json['id']}'))
          ListingCardItem.fromJson(json).copyWith(isFavorite: true),
    ];
    const size = SavedListingsRepository.pageSize;
    final start = (page - 1) * size;
    return PagedResult(
      items: saved.skip(start).take(size).toList(),
      page: page,
      hasMore: start + size < saved.length,
    );
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async =>
      MockFavoriteStore.set(listingId, favorite);
}

/// Gọi backend:
/// - `GET /listings/favorites?page=&limit=` → `{ data: [Listing + isFavorite], meta }`
///   (chỉ tin còn hiển thị, mới lưu trước)
/// - `PUT|DELETE /listings/:id/favorite`
class ApiSavedListingsRepository implements SavedListingsRepository {
  ApiSavedListingsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<PagedResult<ListingCardItem>> getPage({int page = 1}) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/favorites',
      queryParameters: {
        'page': page,
        'limit': SavedListingsRepository.pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data ?? const {},
      ListingCardItem.fromJson,
      page: page,
      pageSize: SavedListingsRepository.pageSize,
    );
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/${Uri.encodeComponent(listingId)}/favorite';
    favorite
        ? await _apiClient.dio.put<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }
}

/// Trang Xem gần đây: mã tin lấy từ [RecentlyViewedStore], dữ liệu tin tải mới
/// qua `GET /listings/batch?ids=` (tin đã ẩn / bán / xoá tự bỏ). Một trang duy nhất.
class ApiRecentlyViewedRepository extends ApiSavedListingsRepository {
  ApiRecentlyViewedRepository({super.apiClient});

  @override
  Future<PagedResult<ListingCardItem>> getPage({int page = 1}) async {
    final ids = await RecentlyViewedStore.ids();
    if (ids.isEmpty) {
      return const PagedResult(items: [], page: 1, hasMore: false);
    }
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/batch',
      queryParameters: {'ids': ids.join(',')},
    );
    return PagedResult(
      items: [
        for (final item in response.data?['data'] as List? ?? const [])
          ListingCardItem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      page: 1,
      hasMore: false,
    );
  }
}

/// Tin mẫu trang chủ theo thứ tự trong [RecentlyViewedStore]
class MockRecentlyViewedRepository extends MockSavedListingsRepository {
  MockRecentlyViewedRepository({super.latency});

  @override
  Future<PagedResult<ListingCardItem>> getPage({int page = 1}) async {
    await Future<void>.delayed(latency);
    final ids = await RecentlyViewedStore.ids();
    final byId = {
      for (final json in HomeMockData.listings(DateTime.now()))
        '${json['id']}': json,
    };
    return PagedResult(
      items: [
        for (final id in ids)
          if (byId[id] case final json?)
            ListingCardItem.fromJson(
              json,
            ).copyWith(isFavorite: MockFavoriteStore.contains(id)),
      ],
      page: 1,
      hasMore: false,
    );
  }
}
