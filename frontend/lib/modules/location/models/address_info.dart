import 'package:equatable/equatable.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Địa chỉ của tin đăng / người dùng.
/// Công khai: phường/xã + tỉnh/thành. Riêng tư: số nhà, đường và toạ độ chính xác.
class AddressInfo extends Equatable {
  final AdministrativeUnitModel province;
  final AdministrativeUnitModel ward;
  final String streetAddress;

  /// Toạ độ để tìm tin gần bạn: lấy từ GPS, nếu không có thì dùng tâm phường/xã
  final GeoPoint? geoPoint;

  /// true khi toạ độ lấy từ GPS của máy (chính xác hơn tâm phường/xã)
  final bool isGeoPointFromDevice;

  const AddressInfo({
    required this.province,
    required this.ward,
    this.streetAddress = '',
    this.geoPoint,
    this.isGeoPointFromDevice = false,
  });

  /// Nhãn hiển thị công khai, VD "Phường Bến Thành, TP. Hồ Chí Minh"
  String get areaLabel => '${ward.name}, ${province.name}';

  String get fullLabel {
    final street = streetAddress.trim();
    return street.isEmpty ? areaLabel : '$street, $areaLabel';
  }

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    final geo = json['geoPoint'];
    return AddressInfo(
      province: AdministrativeUnitModel.fromJson(
        Map<String, dynamic>.from(json['province'] as Map),
      ),
      ward: AdministrativeUnitModel.fromJson(
        Map<String, dynamic>.from(json['ward'] as Map),
      ),
      streetAddress: json['streetAddress'] as String? ?? '',
      geoPoint: geo is Map
          ? GeoPoint.fromJson(Map<String, dynamic>.from(geo))
          : null,
      isGeoPointFromDevice: json['isGeoPointFromDevice'] as bool? ?? false,
    );
  }

  /// Lưu nháp trên máy (giữ đủ tên để hiển thị lại không cần gọi API)
  Map<String, dynamic> toJson() => {
    'province': province.toJson(),
    'ward': ward.toJson(),
    'streetAddress': streetAddress,
    'geoPoint': geoPoint?.toJson(),
    'isGeoPointFromDevice': isGeoPointFromDevice,
  };

  /// Payload gửi API: backend lưu mã để lọc theo khu vực và toạ độ để tính khoảng cách
  Map<String, dynamic> toPayload() => {
    'provinceCode': province.code,
    'wardCode': ward.code,
    'streetAddress': streetAddress.trim(),
    'latitude': geoPoint?.latitude,
    'longitude': geoPoint?.longitude,
    'geoSource': isGeoPointFromDevice ? 'device' : 'ward_center',
  };

  @override
  List<Object?> get props => [
    province,
    ward,
    streetAddress,
    geoPoint,
    isGeoPointFromDevice,
  ];
}
