import 'package:restore/core/network/api_client.dart';
import '../data/listing_mock_data.dart';
import 'package:restore/data/models/category_model.dart';

/// Nguồn danh mục đăng tin kèm schema thuộc tính của từng danh mục
abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
}

/// Đọc dữ liệu mẫu (cùng cấu trúc JSON với API)
class MockCategoryRepository implements CategoryRepository {
  MockCategoryRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future<void>.delayed(latency);
    return ListingMockData.categories.map(CategoryModel.fromJson).toList();
  }
}

/// Gọi `GET /categories`. Danh mục ít thay đổi nên giữ lại trong bộ nhớ
/// suốt phiên làm việc, tránh tải lại mỗi lần mở luồng đăng tin.
class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  static List<CategoryModel>? _cache;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final cached = _cache;
    if (cached != null) return cached;

    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/categories',
      queryParameters: const {'include': 'attributes'},
    );
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return _cache = [
      for (final item in data)
        CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
