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

/// Đọc dữ liệu mẫu, có độ trễ giả lập để UI xử lý được trạng thái tải
class MockLocationRepository implements LocationRepository {
  MockLocationRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  /// Toạ độ cách tâm phường gần nhất quá xa thì coi như ngoài vùng dữ liệu mẫu
  static const double _maxReverseDistanceKm = 30;

  @override
  Future<List<AdministrativeUnitModel>> getProvinces() async {
    await Future<void>.delayed(latency);
    return LocationMockData.provinces.map(AdministrativeUnitModel.fromJson).toList();
  }

  @override
  Future<List<AdministrativeUnitModel>> getWards(String provinceCode) async {
    await Future<void>.delayed(latency);
    final wards = LocationMockData.wardsByProvince[provinceCode] ?? const [];
    return wards.map(AdministrativeUnitModel.fromJson).toList();
  }

  @override
  Future<AddressInfo?> reverseGeocode(GeoPoint point) async {
    await Future<void>.delayed(latency);
    AdministrativeUnitModel? nearest;
    var nearestDistance = double.infinity;
    for (final json in LocationMockData.wardsByProvince.values.expand(
      (w) => w,
    )) {
      final ward = AdministrativeUnitModel.fromJson(json);
      final distance = ward.center?.distanceTo(point) ?? double.infinity;
      if (distance < nearestDistance) {
        nearest = ward;
        nearestDistance = distance;
      }
    }
    if (nearest == null || nearestDistance > _maxReverseDistanceKm) return null;

    final province = (await getProvinces()).firstWhere(
      (province) => province.code == nearest!.parentCode,
    );
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
      _getUnits('/locations/provinces');

  @override
  Future<List<AdministrativeUnitModel>> getWards(String provinceCode) =>
      _getUnits('/locations/provinces/$provinceCode/wards');

  @override
  Future<AddressInfo?> reverseGeocode(GeoPoint point) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/locations/reverse-geocode',
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
        AdministrativeUnitModel.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
