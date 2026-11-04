import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import '../data/location_mock_data.dart';
import '../models/address_info.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Nguồn dữ liệu địa chỉ hành chính Việt Nam (2 cấp: tỉnh/thành - phường/xã)
abstract class LocationRepository {
  Future<List<AdministrativeUnitModel>> getProvinces();
  Future<List<AdministrativeUnitModel>> getWards(String provinceCode);

  /// Đổi toạ độ GPS thành tỉnh/thành + phường/xã gần nhất
  Future<AddressInfo?> reverseGeocode(GeoPoint point);
}

/// Đọc bộ dữ liệu địa chỉ thật đóng gói trong app (34 tỉnh, 3.321 phường/xã),
/// có độ trễ giả lập để UI xử lý được trạng thái tải
class MockLocationRepository implements LocationRepository {
  MockLocationRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  /// GPS xa tâm phường gần nhất quá mức này thì coi như ngoài Việt Nam.
  /// Bản mock chỉ có tâm phường (không có ranh giới như backend) nên lấy phường gần nhất.
  static const double _maxReverseDistanceKm = 30;

  @override
  Future<List<AdministrativeUnitModel>> getProvinces() async {
    await Future<void>.delayed(latency);
    return (await LocationMockData.load()).provinces;
  }

  @override
  Future<List<AdministrativeUnitModel>> getWards(String provinceCode) async {
    await Future<void>.delayed(latency);
    return (await LocationMockData.load()).wardsByProvince[provinceCode] ??
        const [];
  }

  @override
  Future<AddressInfo?> reverseGeocode(GeoPoint point) async {
    await Future<void>.delayed(latency);
    final data = await LocationMockData.load();
    AdministrativeUnitModel? nearest;
    var nearestDistance = double.infinity;
    for (final ward in data.allWards) {
      final distance = ward.center?.distanceTo(point) ?? double.infinity;
      if (distance < nearestDistance) {
        nearest = ward;
        nearestDistance = distance;
      }
    }
    if (nearest == null || nearestDistance > _maxReverseDistanceKm) return null;

    final province = data.provinceOf(nearest.parentCode!);
    if (province == null) return null;
    return AddressInfo(
      province: province,
      ward: nearest,
      geoPoint: point,
      isGeoPointFromDevice: true,
    );
  }
}

/// Gọi backend. Hợp đồng API xem tài liệu listing-api-contract.md.
class ApiLocationRepository implements LocationRepository {
  ApiLocationRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<AdministrativeUnitModel>> getProvinces() =>
      _getUnits('/catalog/locations/provinces');

  @override
  Future<List<AdministrativeUnitModel>> getWards(String provinceCode) =>
      _getUnits('/catalog/locations/provinces/$provinceCode/wards');

  @override
  Future<AddressInfo?> reverseGeocode(GeoPoint point) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/catalog/locations/reverse-geocode',
        queryParameters: point.toJson(),
      );
      final data = response.data?['data'];
      if (data is! Map) return null;
      return AddressInfo.fromJson({
        ...Map<String, dynamic>.from(data),
        'geoPoint': point.toJson(),
        'isGeoPointFromDevice': true,
      });
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<AdministrativeUnitModel>> _getUnits(String path) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(path);
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Missing response data');
    return [
      for (final item in data)
        AdministrativeUnitModel.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
    ];
  }
}
