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
