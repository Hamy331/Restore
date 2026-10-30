import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/wanted_alert_match_level.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/shared/models/listing_filter.dart';

/// Nội dung thông báo đang soạn ở trang tạo: từ khoá, tiêu chí lọc dùng
/// chung với sheet Bộ lọc ([filter]), khu vực và mức độ giống.
/// Dùng cho cả xem trước tin khớp lẫn lưu thông báo.
class WantedAlertDraft extends Equatable {
  static const int keywordsMinLength = 2;
  static const int keywordsMaxLength = 80;

  final String keywords;

  /// Danh mục, khoảng giá, tình trạng, kiểu giao dịch (bỏ qua sắp xếp)
  final ListingFilter filter;

  /// null là toàn quốc
  final AreaOption? area;
  final WantedAlertMatchLevel matchLevel;

  const WantedAlertDraft({
    this.keywords = '',
    this.filter = const ListingFilter(),
    this.area,
    this.matchLevel = WantedAlertMatchLevel.balanced,
  });

  String get trimmedKeywords => keywords.trim();

  bool get hasKeywords => trimmedKeywords.length >= keywordsMinLength;

  WantedAlertDraft copyWith({
    String? keywords,
    ListingFilter? filter,
    AreaOption? Function()? area,
    WantedAlertMatchLevel? matchLevel,
  }) => WantedAlertDraft(
    keywords: keywords ?? this.keywords,
    filter: filter ?? this.filter,
    area: area == null ? this.area : area(),
    matchLevel: matchLevel ?? this.matchLevel,
  );

  /// Body gửi `POST /wanted-alerts` và `POST /wanted-alerts/preview`
  Map<String, dynamic> toJson() => {
    'keywords': trimmedKeywords,
    'categoryId': filter.categoryId,
    'minPrice': filter.minPrice,
    'maxPrice': filter.maxPrice,
    'conditions': [for (final item in filter.conditions) item.apiValue],
    'dealTypes': [for (final type in filter.dealTypes) type.apiValue],
    'area': area == null
        ? null
        : {'code': area!.code, 'level': area!.level.name, 'label': area!.label},
    'matchLevel': matchLevel.apiValue,
  };

  @override
  List<Object?> get props => [keywords, filter, area, matchLevel];
}
