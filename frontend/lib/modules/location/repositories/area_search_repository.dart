import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';
import 'package:restore/data/models/administrative_unit_model.dart';

import '../data/location_mock_data.dart';
import '../models/area_option.dart';

/// Tìm khu vực theo tên và các khu vực đã chọn gần đây (trang chọn khu vực)
abstract class AreaSearchRepository {
  /// Số kết quả tối đa mỗi lần tìm
  static const int resultLimit = 20;

  /// Phường/xã, tỉnh/thành có tên khớp [query] (không phân biệt dấu)
  Future<List<AreaOption>> search(String query);

  /// Khu vực đã chọn gần đây, mới nhất trước
  Future<List<AreaOption>> getRecent();
  Future<void> saveRecent(AreaOption area);
  Future<void> deleteRecent(String code);
}

/// Tìm trong bộ dữ liệu địa chỉ thật đóng gói trong app (LocationMockData).
/// Danh sách gần đây giữ trong bộ nhớ nên còn khi mở lại trang.
class MockAreaSearchRepository implements AreaSearchRepository {
  MockAreaSearchRepository({this.latency = const Duration(milliseconds: 200)});

  final Duration latency;

  static const int _recentLimit = 8;
  static final List<AreaOption> _recent = [];
  static Future<List<AreaOption>>? _areas;

  /// Mọi khu vực, tỉnh/thành trước rồi tới phường/xã (dựng một lần)
  static Future<List<AreaOption>> _allAreas() => _areas ??= () async {
    final data = await LocationMockData.load();
    return [
      for (final province in data.provinces)
        if (data.provinceCenter(province.code) case final center?)
          AreaOption(
            code: province.code,
            name: province.name,
            shortName: province.shortName,
            level: AdministrativeLevel.province,
            center: center,
          ),
      for (final province in data.provinces)
        for (final ward in data.wardsByProvince[province.code] ?? const [])
          if (ward.center case final center?)
            AreaOption(
              code: ward.code,
              name: ward.name,
              shortName: ward.shortName,
              level: AdministrativeLevel.ward,
              parentName: province.name,
              center: center,
            ),
    ];
  }();

  @override
  Future<List<AreaOption>> search(String query) async {
    await Future<void>.delayed(latency);
    final areas = await _allAreas();
    // Khớp tên trước, khớp tên tỉnh/thành chứa nó sau
    final byName = areas.where(
      (area) => VietnameseText.matches(area.name, query),
    );
    final byParent = areas.where(
      (area) =>
          !VietnameseText.matches(area.name, query) &&
          VietnameseText.matches(area.label, query),
    );
    return [
      ...byName,
      ...byParent,
    ].take(AreaSearchRepository.resultLimit).toList();
  }

  @override
  Future<List<AreaOption>> getRecent() async => List.of(_recent);

  @override
  Future<void> saveRecent(AreaOption area) async {
    _recent
      ..removeWhere((item) => item.code == area.code)
      ..insert(0, area);
    if (_recent.length > _recentLimit) _recent.removeLast();
  }

  @override
  Future<void> deleteRecent(String code) async =>
      _recent.removeWhere((item) => item.code == code);
}

/// Gọi backend:
/// - `GET /catalog/locations/search?q=&limit=` → `{ data: [{ code, name, shortName, level, parentName, center }] }`
/// - `GET /users/me/recent-areas` → cùng cấu trúc, mới nhất trước (backend chưa có, lỗi thì ẩn phần gần đây)
/// - `POST /users/me/recent-areas` `{ code }`
/// - `DELETE /users/me/recent-areas/:code`
class ApiAreaSearchRepository implements AreaSearchRepository {
  ApiAreaSearchRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<AreaOption>> search(String query) => _getAreas(
    '/catalog/locations/search',
    query: {'q': query, 'limit': AreaSearchRepository.resultLimit},
  );

  @override
  Future<List<AreaOption>> getRecent() => _getAreas('/users/me/recent-areas');

  @override
  Future<void> saveRecent(AreaOption area) => _apiClient.dio.post<void>(
    '/users/me/recent-areas',
    data: {'code': area.code},
  );

  @override
  Future<void> deleteRecent(String code) =>
      _apiClient.dio.delete<void>('/users/me/recent-areas/$code');

  Future<List<AreaOption>> _getAreas(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [
      for (final item in data)
        AreaOption.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
