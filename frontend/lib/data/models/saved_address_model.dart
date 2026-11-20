import 'package:equatable/equatable.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Một dòng của bảng SavedAddress (prisma/schema.prisma): địa chỉ đã lưu để
/// chọn lại khi đăng tin. Mỗi người tối đa 5, tự lưu khi đăng / sửa tin.
class SavedAddressModel extends Equatable {
  static const int maxPerUser = 5;
  static const int maxLabelLength = 40;

  final String id;

  /// Tên tự đặt, VD "Nhà", "Cửa hàng"; null = chưa đặt
  final String? label;
  final AdministrativeUnitModel province;
  final AdministrativeUnitModel ward;
  final String streetAddress;
  final GeoPoint geoPoint;

  /// true khi toạ độ lấy từ GPS của máy (geoSource = device)
  final bool isGeoPointFromDevice;
  final DateTime? lastUsedAt;

  const SavedAddressModel({
    required this.id,
    this.label,
    required this.province,
    required this.ward,
    this.streetAddress = '',
    required this.geoPoint,
    this.isGeoPointFromDevice = false,
    this.lastUsedAt,
  });

  /// `{ id, label, provinceCode, wardCode, province, ward, streetAddress,
  /// latitude, longitude, geoSource, lastUsedAt }`
  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    final lastUsedAt = json['lastUsedAt'];
    return SavedAddressModel(
      id: json['id'] as String,
      label: json['label'] as String?,
      province: AdministrativeUnitModel.fromJson(
        Map<String, dynamic>.from(json['province'] as Map),
      ),
      ward: AdministrativeUnitModel.fromJson(
        Map<String, dynamic>.from(json['ward'] as Map),
      ),
      streetAddress: json['streetAddress'] as String? ?? '',
      geoPoint: GeoPoint(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      isGeoPointFromDevice: json['geoSource'] == 'device',
      lastUsedAt: lastUsedAt is String ? DateTime.tryParse(lastUsedAt) : null,
    );
  }

  /// Nhãn đầy đủ, VD "12 Nguyễn Huệ, Phường Sài Gòn, Thành phố Hồ Chí Minh"
  String get fullLabel {
    final street = streetAddress.trim();
    final area = '${ward.name}, ${province.name}';
    return street.isEmpty ? area : '$street, $area';
  }

  SavedAddressModel copyWith({String? Function()? label}) => SavedAddressModel(
    id: id,
    label: label != null ? label() : this.label,
    province: province,
    ward: ward,
    streetAddress: streetAddress,
    geoPoint: geoPoint,
    isGeoPointFromDevice: isGeoPointFromDevice,
    lastUsedAt: lastUsedAt,
  );

  @override
  List<Object?> get props => [
    id,
    label,
    province,
    ward,
    streetAddress,
    geoPoint,
    isGeoPointFromDevice,
    lastUsedAt,
  ];
}
