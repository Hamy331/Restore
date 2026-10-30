import 'package:equatable/equatable.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/data/models/enums/wanted_alert_match_level.dart';
import 'package:restore/shared/models/listing_filter.dart';

/// Một dòng của bảng WantedAlert (đề xuất, xem `backend/docs/wanted-alerts.md`):
/// người dùng đặt trước món muốn mua, có tin mới gần giống thì backend gửi
/// thông báo kèm đường dẫn tới tin đó. Xoá dòng là dừng thông báo.
class WantedAlertModel extends Equatable {
  final String id;
  final String userId;

  /// Mô tả món cần tìm, VD "máy ảnh film Canon"
  final String keywords;
  final String? categoryId;

  /// Khoảng giá VND, mỗi đầu null là không giới hạn
  final int? minPrice;
  final int? maxPrice;

  /// Rỗng là mọi tình trạng / mọi kiểu giao dịch
  final Set<ListingCondition> conditions;
  final Set<ListingDealType> dealTypes;

  /// Khu vực (tỉnh/thành hoặc phường/xã), null là toàn quốc
  final String? areaCode;
  final AdministrativeLevel? areaLevel;

  /// Nhãn khu vực lưu kèm để hiện ngay, VD "Phường Bến Thành, TP. Hồ Chí Minh"
  final String? areaLabel;
  final WantedAlertMatchLevel matchLevel;
  final DateTime? createdAt;

  /// Lần gần nhất có tin khớp
  final DateTime? lastMatchedAt;

  const WantedAlertModel({
    required this.id,
    required this.keywords,
    this.userId = '',
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.conditions = const {},
    this.dealTypes = const {},
    this.areaCode,
    this.areaLevel,
    this.areaLabel,
    this.matchLevel = WantedAlertMatchLevel.balanced,
    this.createdAt,
    this.lastMatchedAt,
  });

  /// Tiêu chí lọc dưới dạng [ListingFilter] để dùng lại hàng chip, sheet
  /// Bộ lọc và bộ lọc tin mẫu
  ListingFilter get filter => ListingFilter(
    categoryId: categoryId,
    minPrice: minPrice,
    maxPrice: maxPrice,
    conditions: conditions,
    dealTypes: dealTypes,
  );

  factory WantedAlertModel.fromJson(Map<String, dynamic> json) {
    final area = json['area'];
    return WantedAlertModel(
      id: '${json['id']}',
      userId: '${json['userId'] ?? ''}',
      keywords: json['keywords'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      minPrice: (json['minPrice'] as num?)?.toInt(),
      maxPrice: (json['maxPrice'] as num?)?.toInt(),
      conditions: {
        for (final value in json['conditions'] as List? ?? const [])
          ?ListingCondition.fromApi('$value'),
      },
      dealTypes: {
        for (final type in ListingDealType.values)
          if ((json['dealTypes'] as List? ?? const []).contains(type.apiValue))
            type,
      },
      areaCode: area is Map ? '${area['code']}' : null,
      areaLevel: area is Map
          ? AdministrativeLevel.values.asNameMap()[area['level']]
          : null,
      areaLabel: area is Map ? area['label'] as String? : null,
      matchLevel: WantedAlertMatchLevel.fromApi(json['matchLevel'] as String?),
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      lastMatchedAt: DateTime.tryParse('${json['lastMatchedAt']}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'keywords': keywords,
    'categoryId': categoryId,
    'minPrice': minPrice,
    'maxPrice': maxPrice,
    'conditions': [for (final item in conditions) item.apiValue],
    'dealTypes': [for (final type in dealTypes) type.apiValue],
    'area': areaCode == null
        ? null
        : {'code': areaCode, 'level': areaLevel?.name, 'label': areaLabel},
    'matchLevel': matchLevel.apiValue,
    'createdAt': createdAt?.toIso8601String(),
    'lastMatchedAt': lastMatchedAt?.toIso8601String(),
  };

  WantedAlertModel copyWith({DateTime? lastMatchedAt}) => WantedAlertModel(
    id: id,
    userId: userId,
    keywords: keywords,
    categoryId: categoryId,
    minPrice: minPrice,
    maxPrice: maxPrice,
    conditions: conditions,
    dealTypes: dealTypes,
    areaCode: areaCode,
    areaLevel: areaLevel,
    areaLabel: areaLabel,
    matchLevel: matchLevel,
    createdAt: createdAt,
    lastMatchedAt: lastMatchedAt ?? this.lastMatchedAt,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    keywords,
    categoryId,
    minPrice,
    maxPrice,
    conditions,
    dealTypes,
    areaCode,
    areaLevel,
    areaLabel,
    matchLevel,
    createdAt,
    lastMatchedAt,
  ];
}
