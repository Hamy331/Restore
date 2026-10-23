import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/modules/listings/data/listing_mock_data.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/data/listing_filter_mock_data.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/models/paged_result.dart';

/// Nguồn dữ liệu cho trang chi tiết danh mục
abstract class CategoryListingsRepository {
  /// Số tin tối đa mỗi lượt tải
  static const int pageSize = 10;

  /// Thông tin danh mục, dùng khi mở trang bằng đường dẫn (chưa có sẵn
  /// danh mục từ trang trước)
  Future<CategoryModel> getCategory(String categoryId);

  /// Tin thuộc danh mục theo [filter] (đã chứa categoryId), [page] bắt đầu
  /// từ 1
  Future<PagedResult<ListingCardItem>> getListings(
    ListingFilter filter, {
    int page = 1,
  });

  Future<void> setFavorite(String listingId, bool favorite);
}

/// Đọc dữ liệu mẫu, có độ trễ giả lập để UI xử lý trạng thái tải
class MockCategoryListingsRepository implements CategoryListingsRepository {
  MockCategoryListingsRepository({
    this.latency = const Duration(milliseconds: 400),
  });

  final Duration latency;

  @override
  Future<CategoryModel> getCategory(String categoryId) async {
    await Future<void>.delayed(latency);
    final json = ListingMockData.categories.firstWhere(
      (category) => category['id'] == categoryId,
      orElse: () => throw StateError('Category $categoryId not found'),
    );
    return CategoryModel.fromJson(json);
  }

  @override
  Future<PagedResult<ListingCardItem>> getListings(
    ListingFilter filter, {
    int page = 1,
  }) async {
    await Future<void>.delayed(latency);

    final matches = <ListingCardItem>[];
    for (final json in HomeMockData.listings(DateTime.now())) {
      final item = ListingCardItem.fromJson(json);
      final listing = item.listing;
      if (!filter.matches(listing)) continue;
      matches.add(
        item.copyWith(isFavorite: MockFavoriteStore.contains(listing.id)),
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
    int byNewest(ListingCardItem a, ListingCardItem b) =>
        (b.listing.createdAt ?? epoch).compareTo(a.listing.createdAt ?? epoch);

    matches.sort(switch (filter.sort) {
      ListingSort.priceLow => byPrice,
      ListingSort.priceHigh => (a, b) => byPrice(a, b, desc: true),
      ListingSort.newest ||
      ListingSort.nearest ||
      ListingSort.relevance => byNewest,
    });

    const size = CategoryListingsRepository.pageSize;
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
/// - `GET /categories/:id` → `{ data: Category }`
/// - `GET /listings?categoryId=&deal=&sort=&minPrice=&maxPrice=&condition=
///   &page=&pageSize=`
///   → `{ data: [Listing + areaLabel, distanceKm, isFavorite], meta: { hasMore } }`
class ApiCategoryListingsRepository implements CategoryListingsRepository {
  ApiCategoryListingsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<CategoryModel> getCategory(String categoryId) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/categories',
    );
    final data = (response.data?['data'] as List).cast<Map>().firstWhere(
      (row) => row['id'] == categoryId,
    );
    return CategoryModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<PagedResult<ListingCardItem>> getListings(
    ListingFilter filter, {
    int page = 1,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings',
      queryParameters: {
        ...filter.toQuery(),
        'page': page,
        'pageSize': CategoryListingsRepository.pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data ?? const {},
      ListingCardItem.fromJson,
      page: page,
      pageSize: CategoryListingsRepository.pageSize,
    );
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/$listingId/favorite';
    favorite
        ? await _apiClient.dio.put<void>(path)
        : await _apiClient.dio.delete<void>(path);
  }
}
