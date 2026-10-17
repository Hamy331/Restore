import 'package:equatable/equatable.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Một khu vực (tỉnh/thành hoặc phường/xã) để chọn làm điểm gốc khi xem
/// tin quanh đó. Trả về từ `GET /locations/search`.
class AreaOption extends Equatable {
  final String code;
  final String name;
  final AdministrativeLevel level;

  /// Tên tỉnh/thành chứa phường/xã này (null với cấp tỉnh)
  final String? parentName;

  /// Tâm khu vực, dùng làm toạ độ tính khoảng cách
  final GeoPoint center;

  const AreaOption({
    required this.code,
    required this.name,
    required this.level,
    required this.center,
    this.parentName,
  });

  /// Nhãn đầy đủ, VD "Phường Bến Thành, TP. Hồ Chí Minh"
  String get label => parentName == null ? name : '$name, $parentName';

  factory AreaOption.fromJson(Map<String, dynamic> json) => AreaOption(
    code: '${json['code']}',
    name: json['name'] as String,
    level: AdministrativeLevel.values.byName(json['level'] as String),
    parentName: json['parentName'] as String?,
    center: GeoPoint.fromJson(Map<String, dynamic>.from(json['center'] as Map)),
  );

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'level': level.name,
    'parentName': parentName,
    'center': center.toJson(),
  };

  @override
  List<Object?> get props => [code, name, level, parentName, center];
}

/// Kết quả trang chọn khu vực: một khu vực cụ thể, hoặc dùng vị trí GPS
/// của máy ("Gần tôi") khi [area] là null.
class AreaPickResult {
  final AreaOption? area;

  const AreaPickResult.area(AreaOption this.area);

  const AreaPickResult.myLocation() : area = null;

  bool get useMyLocation => area == null;
}
