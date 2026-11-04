import 'package:restore/modules/listings/repositories/category_repository.dart';
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

/// Danh mục lấy từ `GET /catalog/categories` (dùng chung cache với luồng
/// đăng tin), mức giá gợi ý cố định trong app.
/// Backend không có `GET /listings/filter-options`: gọi đường đó sẽ rơi vào
/// `GET /listings/:id` và trả 404 "Không tìm thấy tin đăng".
class ApiListingFilterOptionsRepository
    implements ListingFilterOptionsRepository {
  ApiListingFilterOptionsRepository({CategoryRepository? categoryRepository})
    : _categoryRepository = categoryRepository ?? ApiCategoryRepository();

  final CategoryRepository _categoryRepository;

  @override
  Future<ListingFilterOptions> getOptions() async => ListingFilterOptions(
    categories: await _categoryRepository.getCategories(),
    priceRanges: ListingFilterOptions.defaultPriceRanges,
  );
}
