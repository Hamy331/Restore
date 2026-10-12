import 'package:restore/shared/models/geo_point.dart';

/// Vùng toạ độ gần đúng của Việt Nam (đất liền, Hoàng Sa, Trường Sa).
/// Chỉ dùng để phân biệt "đang ở nước ngoài" với "ở Việt Nam nhưng chưa
/// khớp được phường/xã", không dùng để xác định địa giới chính xác.
class VietnamBounds {
  VietnamBounds._();

  /// Mỗi vùng: (vĩ độ nhỏ nhất, vĩ độ lớn nhất, kinh độ nhỏ nhất, kinh độ lớn nhất)
  static const List<(double, double, double, double)> _areas = [
    (8.1, 23.4, 102.1, 109.5), // đất liền và đảo ven bờ
    (15.7, 17.2, 111.0, 113.0), // quần đảo Hoàng Sa
    (6.5, 11.5, 111.5, 117.9), // quần đảo Trường Sa
  ];

  static bool contains(GeoPoint point) => _areas.any(
    (area) =>
        point.latitude >= area.$1 &&
        point.latitude <= area.$2 &&
        point.longitude >= area.$3 &&
        point.longitude <= area.$4,
  );
}
