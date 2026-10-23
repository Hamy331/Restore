import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';
import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/modules/listings/data/mock_favorite_store.dart';
import 'package:restore/shared/data/listing_filter_mock_data.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../data/search_mock_data.dart';
import '../models/search_history_entry.dart';

/// Nguồn dữ liệu cho trang tìm kiếm và trang kết quả
abstract class SearchRepository {
  /// Số tin tối đa mỗi lượt tải
  static const int pageSize = 10;

  /// Số từ khoá gợi ý tối đa khi đang gõ
  static const int suggestionLimit = 8;

  /// Từ khoá gợi ý tìm nhanh khi chưa gõ gì
  Future<List<String>> getTrending();

  /// Từ khoá gợi ý theo nội dung đang gõ
  Future<List<String>> getSuggestions(String query);

  /// Lịch sử tìm kiếm, mới nhất trước
  Future<List<SearchHistoryEntry>> getHistory();
  Future<void> deleteHistory(String id);
  Future<void> clearHistory();

  /// Tin khớp [query] theo [filter], [page] bắt đầu từ 1.
  /// Server tự lưu [query] vào lịch sử khi tải trang đầu.
  Future<PagedResult<ListingCardItem>> search(
    String query,
    ListingFilter filter, {
    int page = 1,
  });

  Future<void> setFavorite(String listingId, bool favorite);
}

/// Đọc dữ liệu mẫu, có độ trễ giả lập để UI xử lý trạng thái tải.
/// Lịch sử giữ trong bộ nhớ nên còn nguyên khi mở lại trang tìm kiếm.
class MockSearchRepository implements SearchRepository {
  MockSearchRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  static const int _historyLimit = 10;
  static List<SearchHistoryEntry>? _history;
  static int _nextHistoryId = 100;

  List<SearchHistoryEntry> get _store => _history ??= [
    for (final json in SearchMockData.history(DateTime.now()))
      SearchHistoryEntry.fromJson(json),
  ];

  @override
  Future<List<String>> getTrending() async {
    await Future<void>.delayed(latency);
    return SearchMockData.trending;
  }

  @override
  Future<List<String>> getSuggestions(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return SearchMockData.keywords
        .where((keyword) => VietnameseText.matches(keyword, query))
        .take(SearchRepository.suggestionLimit)
        .toList();
  }

  @override
  Future<List<SearchHistoryEntry>> getHistory() async => List.of(_store);

  @override
  Future<void> deleteHistory(String id) async =>
      _store.removeWhere((entry) => entry.id == id);

  @override
  Future<void> clearHistory() async => _store.clear();

  @override
  Future<PagedResult<ListingCardItem>> search(
    String query,
    ListingFilter filter, {
    int page = 1,
  }) async {
    await Future<void>.delayed(latency);
    if (page == 1) _remember(query);

    // Khớp khi tiêu đề chứa đủ mọi từ đã gõ (không phân biệt dấu)
    final words = VietnameseText.normalize(query).split(' ');
    final matches = <ListingCardItem>[];
    for (final json in HomeMockData.listings(DateTime.now())) {
      final item = ListingCardItem.fromJson(json);
      final listing = item.listing;
      final title = VietnameseText.normalize(listing.title);
      if (!words.every(title.contains)) continue;
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

    // Phù hợp nhất: tiêu đề bắt đầu bằng từ khoá lên trước, sau đó tin mới
    final normalizedQuery = VietnameseText.normalize(query);
    int byRelevance(ListingCardItem a, ListingCardItem b) {
      bool starts(ListingCardItem item) => VietnameseText.normalize(
        item.listing.title,
      ).startsWith(normalizedQuery);
      final diff = (starts(b) ? 1 : 0) - (starts(a) ? 1 : 0);
      return diff != 0 ? diff : byNewest(a, b);
    }

    matches.sort(switch (filter.sort) {
      ListingSort.relevance => byRelevance,
      ListingSort.newest || ListingSort.nearest => byNewest,
      ListingSort.priceLow => byPrice,
      ListingSort.priceHigh => (a, b) => byPrice(a, b, desc: true),
    });

    const size = SearchRepository.pageSize;
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

  /// Đưa từ khoá lên đầu lịch sử, bỏ bản trùng (không phân biệt dấu)
  void _remember(String query) {
    final keyword = query.trim();
    if (keyword.isEmpty) return;
    final key = VietnameseText.normalize(keyword);
    _store
      ..removeWhere((entry) => VietnameseText.normalize(entry.keyword) == key)
      ..insert(
        0,
        SearchHistoryEntry(
          id: 'search-${_nextHistoryId++}',
          keyword: keyword,
          searchedAt: DateTime.now(),
        ),
      );
    if (_store.length > _historyLimit) _store.removeLast();
  }
}

/// Gọi backend:
/// - `GET /search/trending` → `{ data: [string] }`
/// - `GET /search/suggestions?q=&limit=` → `{ data: [string] }`
/// - `GET /search/history` → `{ data: [{ id, keyword, searchedAt }] }`
/// - `DELETE /search/history/:id`, `DELETE /search/history`
/// - `GET /listings?q=&deal=&sort=&categoryId=&minPrice=&maxPrice=
///   &condition=&page=&pageSize=`
///   → `{ data: [Listing + areaLabel, distanceKm, isFavorite], meta: { hasMore } }`
class ApiSearchRepository implements SearchRepository {
  ApiSearchRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<String>> getTrending() async =>
      _strings(await _get('/search/trending'));

  @override
  Future<List<String>> getSuggestions(String query) async => _strings(
    await _get(
      '/search/suggestions',
      query: {'q': query, 'limit': SearchRepository.suggestionLimit},
    ),
  );

  @override
  Future<List<SearchHistoryEntry>> getHistory() async {
    final data = (await _get('/search/history'))['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [
      for (final item in data)
        SearchHistoryEntry.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  @override
  Future<void> deleteHistory(String id) =>
      _apiClient.dio.delete<void>('/search/history/$id');

  @override
  Future<void> clearHistory() => _apiClient.dio.delete<void>('/search/history');

  @override
  Future<PagedResult<ListingCardItem>> search(
    String query,
    ListingFilter filter, {
    int page = 1,
  }) async {
    final json = await _get(
      '/listings',
      query: {
        'q': query,
        ...filter.toQuery(),
        'page': page,
        'pageSize': SearchRepository.pageSize,
      },
    );
    return PagedResult.fromJson(
      json,
      ListingCardItem.fromJson,
      page: page,
      pageSize: SearchRepository.pageSize,
    );
  }

  @override
  Future<void> setFavorite(String listingId, bool favorite) async {
    final path = '/listings/$listingId/favorite';
    favorite
        ? await _apiClient.dio.put<void>(path)
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

  List<String> _strings(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [for (final item in data) '$item'];
  }
}
