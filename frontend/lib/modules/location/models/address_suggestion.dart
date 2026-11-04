import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/geo_point.dart';

/// Một gợi ý số nhà / tên đường khi nhập địa chỉ.
/// Trả về từ `GET /catalog/locations/address-suggest`.
class AddressSuggestion extends Equatable {
  /// Dòng điền vào ô số nhà, tên đường, VD "12 Nguyễn Huệ"
  final String label;

  /// Mô tả phụ để phân biệt, VD "Phường Sài Gòn, Thành phố Hồ Chí Minh"
  final String description;

  /// Phường/tỉnh chứa địa chỉ (có khi nguồn gợi ý trả tọa độ)
  final String? provinceCode;
  final String? wardCode;
  final GeoPoint? point;

  const AddressSuggestion({
    required this.label,
    this.description = '',
    this.provinceCode,
    this.wardCode,
    this.point,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    final latitude = json['latitude'], longitude = json['longitude'];
    return AddressSuggestion(
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      provinceCode: json['provinceCode'] as String?,
      wardCode: json['wardCode'] as String?,
      point: latitude is num && longitude is num
          ? GeoPoint(latitude.toDouble(), longitude.toDouble())
          : null,
    );
  }

  @override
  List<Object?> get props => [
    label,
    description,
    provinceCode,
    wardCode,
    point,
  ];
}
