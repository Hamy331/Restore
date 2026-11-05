import 'package:restore/data/models/enums/listing_condition.dart';
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

/// Đọc danh mục hiện tại mỗi lần mở luồng, để áp dụng cấu hình admin mới.
class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  Future<Map<ListingCondition, String>> getActiveConditions() async {
    final data =
        (await _apiClient.dio.get<Map<String, dynamic>>(
              '/catalog/conditions',
            )).data!['data']
            as List;
    return {
      for (final row in data)
        if (ListingCondition.fromApi(row['condition']) case final value?)
          value: row['name'] as String,
    };
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/catalog/categories',
      queryParameters: const {'include': 'attributes'},
    );
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [
      for (final item in data)
        CategoryModel.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
