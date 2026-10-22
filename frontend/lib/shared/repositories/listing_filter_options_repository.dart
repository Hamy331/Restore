import 'package:restore/core/network/api_client.dart';
import 'package:restore/shared/data/listing_filter_mock_data.dart';
import 'package:restore/shared/models/listing_filter_options.dart';

/// Nguồn lựa chọn cho sheet Bộ lọc (danh mục, mức giá gợi ý)
abstract class ListingFilterOptionsRepository {
  Future<ListingFilterOptions> getOptions();
}

/// Đọc dữ liệu mẫu, có độ trễ giả lập để sheet xử lý trạng thái tải
class MockListingFilterOptionsRepository
    implements ListingFilterOptionsRepository {
  MockListingFilterOptionsRepository({
    this.latency = const Duration(milliseconds: 300),
  });

  final Duration latency;

  @override
  Future<ListingFilterOptions> getOptions() async {
    await Future<void>.delayed(latency);
    return ListingFilterOptions.fromJson(ListingFilterMockData.options);
  }
}

/// Gọi `GET /listings/filter-options`
/// → `{ data: { categories: [Category], priceRanges: [{ min?, max? }] } }`.
/// Ít thay đổi nên giữ trong bộ nhớ suốt phiên, mở sheet lần sau hiện ngay.
class ApiListingFilterOptionsRepository
    implements ListingFilterOptionsRepository {
  ApiListingFilterOptionsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  static ListingFilterOptions? _cache;

  @override
  Future<ListingFilterOptions> getOptions() async {
    final cached = _cache;
    if (cached != null) return cached;

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/filter-options',
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return _cache = ListingFilterOptions.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}
