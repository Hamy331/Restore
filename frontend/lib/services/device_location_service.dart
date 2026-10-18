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
    timeLimit: Duration(seconds: 10),
  );

  /// Vị trí đã biết gần đây vẫn đủ tốt cho việc gợi ý phường/xã
  static const Duration _maxLastKnownAge = Duration(minutes: 5);

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

    // Có vị trí mới đây thì trả ngay, không phải chờ GPS bắt tín hiệu
    final lastKnown = await _lastKnownPosition();
    if (lastKnown != null &&
        DateTime.now().difference(lastKnown.timestamp) < _maxLastKnownAge) {
      return GeoPoint(lastKnown.latitude, lastKnown.longitude);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      // Hết thời gian chờ (thường gặp trong nhà hoặc máy ảo chưa đặt vị trí):
      // dùng vị trí cũ nếu có
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
