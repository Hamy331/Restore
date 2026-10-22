import 'dart:math' as math;

import 'package:restore/modules/home/data/home_mock_data.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Dữ liệu mẫu cho trang Gần bạn, đúng cấu trúc JSON của
/// `GET /listings/nearby` (bản ghi Listing + `location`, `areaLabel`...).
class NearbyMockData {
  NearbyMockData._();

  /// Khu vực mặc định của tài khoản mẫu (`GET /users/me/location`)
  static const Map<String, dynamic> defaultOrigin = {
    'label': 'Phường Bến Thành, TP. Hồ Chí Minh',
    'latitude': 10.7725,
    'longitude': 106.6980,
  };

  /// Dùng lại tin mẫu của trang chủ, đặt mỗi tin quanh [origin] đúng bằng
  /// `distanceKm` có sẵn (mỗi tin một hướng). Nhờ vậy máy ảo đặt vị trí ở
  /// đâu cũng có tin để thử, còn API thật trả toạ độ thật của tin.
  static List<Map<String, dynamic>> listings(DateTime now, GeoPoint origin) {
    final items = HomeMockData.listings(now);
    return [
      for (var i = 0; i < items.length; i++)
        {
          ...items[i],
          'location': _offset(
            origin,
            items[i]['distanceKm'] as double,
            // Góc vàng (~137.5°) để các tin rải đều quanh điểm gốc
            bearingDegree: i * 137.5,
          ),
        },
    ];
  }

  /// Toạ độ cách [origin] một đoạn [km] theo hướng [bearingDegree]
  static Map<String, dynamic> _offset(
    GeoPoint origin,
    double km, {
    required double bearingDegree,
  }) {
    const kmPerDegreeLat = 111.32;
    final bearing = bearingDegree * math.pi / 180;
    final dLat = km * math.cos(bearing) / kmPerDegreeLat;
    final dLng =
        km *
        math.sin(bearing) /
        (kmPerDegreeLat * math.cos(origin.latitude * math.pi / 180));
    return {
      'latitude': origin.latitude + dLat,
      'longitude': origin.longitude + dLng,
    };
  }
}
