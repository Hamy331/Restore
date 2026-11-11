import 'package:equatable/equatable.dart';
import 'package:restore/core/network/media_url.dart';

/// Một tin đang hiển thị trên trang Boost, kèm quảng bá đang chạy
class PromotionHubItem extends Equatable {
  const PromotionHubItem({
    required this.id,
    required this.title,
    this.price,
    this.image,
    this.categoryId,
    this.viewCount = 0,
    this.expiresAt,
    this.autoExtend = false,
    this.boostCredits,
    this.bumpUntil,
    this.featuredUntil,
  });

  final String id;
  final String title;
  final int? price;
  final String? image;
  final String? categoryId;
  final int viewCount;
  final DateTime? expiresAt;
  final bool autoExtend;

  /// Giá đẩy tin khi hết lượt tặng (đã giảm theo gói), null khi không rõ
  final int? boostCredits;
  final DateTime? bumpUntil;
  final DateTime? featuredUntil;

  bool isBumpedAt(DateTime now) => bumpUntil?.isAfter(now) ?? false;
  bool isFeaturedAt(DateTime now) => featuredUntil?.isAfter(now) ?? false;
  bool isPromotedAt(DateTime now) => isBumpedAt(now) || isFeaturedAt(now);

  /// Hết hạn trong [PromotionHub.expiringDays] ngày tới và không tự gia hạn
  bool isExpiringAt(DateTime now) {
    final end = expiresAt;
    if (end == null || autoExtend || !end.isAfter(now)) return false;
    return end.difference(now) <=
        const Duration(days: PromotionHub.expiringDays);
  }

  factory PromotionHubItem.fromJson(Map<String, dynamic> json) =>
      PromotionHubItem(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        price: num.tryParse('${json['price']}')?.toInt(),
        image: json['image'] is String
            ? resolveMediaUrl(json['image'] as String)
            : null,
        categoryId: json['categoryId'] as String?,
        viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
        expiresAt: _date(json['expiresAt']),
        autoExtend: json['autoExtend'] == true,
        boostCredits: (json['boostCredits'] as num?)?.toInt(),
        bumpUntil: _date(json['bumpUntil']),
        featuredUntil: _date(json['featuredUntil']),
      );

  @override
  List<Object?> get props => [
    id,
    title,
    price,
    image,
    categoryId,
    viewCount,
    expiresAt,
    autoExtend,
    boostCredits,
    bumpUntil,
    featuredUntil,
  ];
}

/// Trang Boost (`GET /listings/promotions`): ví, lượt đẩy tặng, số lượt đã
/// dùng tháng này và các tin đang hiển thị (sắp hết hạn trước)
class PromotionHub extends Equatable {
  const PromotionHub({
    required this.available,
    this.discountPercent = 0,
    this.freeLeft = 0,
    this.freePerMonth = 0,
    this.boostsThisMonth = 0,
    this.featuresThisMonth = 0,
    this.items = const [],
  });

  /// Tin hết hạn trong số ngày này được xếp vào "Sắp hết hạn"
  static const int expiringDays = 7;

  final int available;
  final int discountPercent;
  final int freeLeft;
  final int freePerMonth;
  final int boostsThisMonth;
  final int featuresThisMonth;
  final List<PromotionHubItem> items;

  bool get boostFree => freeLeft > 0;

  /// Số xu cho lượt đẩy tiếp theo của [item] (0 khi còn lượt tặng)
  int boostCostOf(PromotionHubItem item) =>
      boostFree ? 0 : (item.boostCredits ?? 0);

  factory PromotionHub.fromJson(Map<String, dynamic> json) {
    final boost = Map<String, dynamic>.from(json['boost'] as Map? ?? const {});
    final month = Map<String, dynamic>.from(
      json['thisMonth'] as Map? ?? const {},
    );
    return PromotionHub(
      available: (json['available'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      freeLeft: (boost['freeLeft'] as num?)?.toInt() ?? 0,
      freePerMonth: (boost['freePerMonth'] as num?)?.toInt() ?? 0,
      boostsThisMonth: (month['boosts'] as num?)?.toInt() ?? 0,
      featuresThisMonth: (month['features'] as num?)?.toInt() ?? 0,
      items: [
        for (final item in json['items'] as List? ?? const [])
          if (item is Map)
            PromotionHubItem.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  @override
  List<Object?> get props => [
    available,
    discountPercent,
    freeLeft,
    freePerMonth,
    boostsThisMonth,
    featuresThisMonth,
    items,
  ];
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();
