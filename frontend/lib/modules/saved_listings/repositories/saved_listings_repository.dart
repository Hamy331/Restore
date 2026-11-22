import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/paged_result.dart';

/// Nguồn dữ liệu trang Tin đã lưu
abstract class SavedListingsRepository {
  static const int pageSize = 20;

  factory SavedListingsRepository() => AppEnvironment.useMockData
      ? MockSavedListingsRepository()
      : ApiSavedListingsRepository();

  /// Nguồn cho trang Xem gần đây (cùng giao diện với Tin đã lưu)
  factory SavedListingsRepository.recentlyViewed() => AppEnvironment.useMockData
      ? MockRecentlyViewedRepository()
      : ApiSavedListingsRepository(path: '/listings/recently-viewed');

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
/// - `GET [path]?page=&limit=` → `{ data: [Listing + isFavorite], meta }`, chỉ tin còn
///   hiển thị: `/listings/favorites` (mới lưu trước) hoặc `/listings/recently-viewed`
///   (30 tin vừa xem, mới xem trước; backend ghi khi mở `GET /listings/:id`)
/// - `PUT|DELETE /listings/:id/favorite`
class ApiSavedListingsRepository implements SavedListingsRepository {
  ApiSavedListingsRepository({
    ApiClient? apiClient,
    this.path = '/listings/favorites',
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final String path;

  @override
  Future<PagedResult<ListingCardItem>> getPage({int page = 1}) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      path,
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

/// Trang Xem gần đây khi chạy dữ liệu mẫu: 4 tin mẫu đầu tiên
class MockRecentlyViewedRepository extends MockSavedListingsRepository {
  MockRecentlyViewedRepository({super.latency});

  @override
  Future<PagedResult<ListingCardItem>> getPage({int page = 1}) async {
    await Future<void>.delayed(latency);
    return PagedResult(
      items: [
        for (final json in HomeMockData.listings(DateTime.now()).take(4))
          ListingCardItem.fromJson(
            json,
          ).copyWith(isFavorite: MockFavoriteStore.contains('${json['id']}')),
      ],
      page: 1,
      hasMore: false,
    );
  }
}
