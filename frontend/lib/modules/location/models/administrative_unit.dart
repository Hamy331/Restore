import 'package:equatable/equatable.dart';
import 'geo_point.dart';

/// Cấp hành chính theo mô hình 2 cấp áp dụng từ 01/07/2025:
/// tỉnh/thành phố trực thuộc trung ương và phường/xã/đặc khu (không còn quận/huyện).
enum AdministrativeLevel { province, ward }

/// Một đơn vị hành chính (tỉnh/thành hoặc phường/xã), dữ liệu lấy từ API
class AdministrativeUnit extends Equatable {
  /// Mã đơn vị, backend dùng mã chuẩn của Tổng cục Thống kê
  final String code;
  final String name;
  final AdministrativeLevel level;

  /// Mã tỉnh/thành chứa phường/xã này (null với cấp tỉnh)
  final String? parentCode;

  /// Tâm hành chính, dùng làm toạ độ gần đúng khi người dùng chọn thủ công
  final GeoPoint? center;

  const AdministrativeUnit({
    required this.code,
    required this.name,
    required this.level,
    this.parentCode,
    this.center,
  });

  factory AdministrativeUnit.fromJson(Map<String, dynamic> json) {
    final center = json['center'];
    return AdministrativeUnit(
      code: '${json['code']}',
      name: json['name'] as String,
      level: AdministrativeLevel.values.byName(json['level'] as String),
      parentCode: json['parentCode'] as String?,
      center: center is Map<String, dynamic> ? GeoPoint.fromJson(center) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'level': level.name,
    'parentCode': parentCode,
    'center': center?.toJson(),
  };

  @override
  List<Object?> get props => [code, name, level, parentCode, center];
}
