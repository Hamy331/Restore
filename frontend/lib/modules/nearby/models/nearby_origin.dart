import 'package:equatable/equatable.dart';
import 'package:restore/services/device_location_service.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Điểm gốc để tính "gần bạn": vị trí GPS của máy, hoặc khu vực mặc định của
/// tài khoản khi chưa lấy được GPS.
class NearbyOrigin extends Equatable {
  final GeoPoint point;

  /// Tên khu vực, VD "Phường Bến Thành, TP. Hồ Chí Minh".
  /// null khi chưa đổi được toạ độ ra tên (UI hiện "Vị trí hiện tại").
  final String? label;
  final bool isFromDevice;

  /// Lý do không dùng được GPS (chỉ có khi [isFromDevice] là false)
  final DeviceLocationError? locationError;

  const NearbyOrigin({
    required this.point,
    this.label,
    this.isFromDevice = false,
    this.locationError,
  });

  factory NearbyOrigin.fromJson(Map<String, dynamic> json) => NearbyOrigin(
    point: GeoPoint.fromJson(json),
    label: json['label'] as String?,
  );

  NearbyOrigin withError(DeviceLocationError? error) => NearbyOrigin(
    point: point,
    label: label,
    isFromDevice: isFromDevice,
    locationError: error,
  );

  @override
  List<Object?> get props => [point, label, isFromDevice, locationError];
}
