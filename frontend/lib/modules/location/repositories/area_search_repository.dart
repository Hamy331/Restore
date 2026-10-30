import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/utils/helpers/vietnamese_text.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/geo_point.dart';

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

/// Đọc dữ liệu mẫu của LocationMockData (6 thành phố lớn).
/// Danh sách gần đây giữ trong bộ nhớ nên còn khi mở lại trang.
class MockAreaSearchRepository implements AreaSearchRepository {
  MockAreaSearchRepository({this.latency = const Duration(milliseconds: 200)});

  final Duration latency;

  static const int _recentLimit = 8;
  static final List<AreaOption> _recent = [];

  /// Mọi khu vực mẫu; tâm tỉnh/thành lấy trung bình tâm các phường
  static final List<AreaOption> _areas = () {
    final areas = <AreaOption>[];
    for (final json in LocationMockData.provinces) {
      final province = AdministrativeUnitModel.fromJson(json);
      final wards = [
        for (final ward
            in LocationMockData.wardsByProvince[province.code] ??
                const <Map<String, dynamic>>[])
          AdministrativeUnitModel.fromJson(ward),
      ];
      final centers = [
        for (final ward in wards)
          if (ward.center != null) ward.center!,
      ];
      if (centers.isEmpty) continue;
      areas.add(
        AreaOption(
          code: province.code,
          name: province.name,
          level: AdministrativeLevel.province,
          center: GeoPoint(
            centers.map((c) => c.latitude).reduce((a, b) => a + b) /
                centers.length,
            centers.map((c) => c.longitude).reduce((a, b) => a + b) /
                centers.length,
          ),
        ),
      );
      for (final ward in wards) {
        final center = ward.center;
        if (center == null) continue;
        areas.add(
          AreaOption(
            code: ward.code,
            name: ward.name,
            level: AdministrativeLevel.ward,
            parentName: province.name,
            center: center,
          ),
        );
      }
    }
    return areas;
  }();

  @override
  Future<List<AreaOption>> search(String query) async {
    await Future<void>.delayed(latency);
    // Khớp tên trước, khớp tên tỉnh/thành chứa nó sau
    final byName = _areas.where(
      (area) => VietnameseText.matches(area.name, query),
    );
    final byParent = _areas.where(
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
/// - `GET /locations/search?q=&limit=` → `{ data: [{ code, name, level, parentName, center }] }`
/// - `GET /users/me/recent-areas` → cùng cấu trúc, mới nhất trước
/// - `POST /users/me/recent-areas` `{ code }`
/// - `DELETE /users/me/recent-areas/:code`
class ApiAreaSearchRepository implements AreaSearchRepository {
  ApiAreaSearchRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<AreaOption>> search(String query) => _getAreas(
    '/locations/search',
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
