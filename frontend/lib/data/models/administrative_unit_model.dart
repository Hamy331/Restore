import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Cấp hành chính theo mô hình 2 cấp áp dụng từ 01/07/2025:
/// tỉnh/thành phố trực thuộc trung ương và phường/xã/đặc khu (không còn quận/huyện).
enum AdministrativeLevel { province, ward }

/// Một đơn vị hành chính (tỉnh/thành hoặc phường/xã)
class AdministrativeUnitModel extends Equatable {
  /// Mã đơn vị, backend dùng mã chuẩn của Tổng cục Thống kê
  final String code;

  /// Tên đầy đủ, VD "Thành phố Hồ Chí Minh", "Phường Sài Gòn"
  final String name;

  /// Tên ngắn không kèm cấp, VD "Hồ Chí Minh" (null thì dùng [name])
  final String? shortName;
  final AdministrativeLevel level;

  /// Mã tỉnh/thành chứa phường/xã này
  final String? parentCode;

  /// Tâm hành chính, dùng làm toạ độ gần đúng khi người dùng chọn thủ công
  final GeoPoint? center;

  const AdministrativeUnitModel({
    required this.code,
    required this.name,
    this.shortName,
    required this.level,
    this.parentCode,
    this.center,
  });

  factory AdministrativeUnitModel.fromJson(Map<String, dynamic> json) {
    final center = json['center'];
    return AdministrativeUnitModel(
      code: '${json['code']}',
      name: json['name'] as String,
      shortName: json['shortName'] as String?,
      level: AdministrativeLevel.values.byName(json['level'] as String),
      parentCode: json['parentCode'] as String?,
      center: center is Map<String, dynamic> ? GeoPoint.fromJson(center) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    if (shortName != null) 'shortName': shortName,
    'level': level.name,
    'parentCode': parentCode,
    'center': center?.toJson(),
  };

  /// Tên hiển thị gọn (nút khu vực trang chủ...)
  String get displayName => shortName ?? name;

  @override
  List<Object?> get props => [code, name, shortName, level, parentCode, center];
}
