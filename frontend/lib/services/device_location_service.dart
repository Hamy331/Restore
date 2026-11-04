import 'package:geolocator/geolocator.dart';
import 'package:restore/shared/models/geo_point.dart';

enum DeviceLocationError {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class DeviceLocationException implements Exception {
  final DeviceLocationError error;
  const DeviceLocationException(this.error);
}

/// Lấy vị trí hiện tại của máy (bọc geolocator để dễ thay khi test)
class DeviceLocationService {
  /// Độ chính xác vừa phải đủ cho "gần bạn", nhanh và ít tốn pin hơn GPS cao
  static const LocationSettings _settings = LocationSettings(
    accuracy: LocationAccuracy.medium,
    timeLimit: Duration(seconds: 8),
  );

  Future<GeoPoint> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(DeviceLocationError.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(DeviceLocationError.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        DeviceLocationError.permissionDeniedForever,
      );
    }

    // Luôn xin vị trí mới: vị trí đã lưu của hệ điều hành có thể là chỗ cũ
    // (VD máy ảo vừa đổi vị trí nhưng vẫn trả tọa độ mặc định ở Mỹ)
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      // Hết thời gian chờ (thường gặp trong nhà hoặc máy ảo chưa đặt vị trí):
      // dùng vị trí cũ nếu có
      final lastKnown = await _lastKnownPosition();
      if (lastKnown != null) {
        return GeoPoint(lastKnown.latitude, lastKnown.longitude);
      }
      throw const DeviceLocationException(DeviceLocationError.unavailable);
    }
  }

  Future<Position?> _lastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      // Web không hỗ trợ vị trí đã lưu
      return null;
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
