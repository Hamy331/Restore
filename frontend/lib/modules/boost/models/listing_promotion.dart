import 'package:equatable/equatable.dart';
import 'package:restore/core/network/media_url.dart';

import '../../listings/repositories/listings_repository.dart'
    show FeatureOption;

/// Loại quảng bá: đẩy tin 24 giờ hoặc Hot sale (tin ưu tiên) nhiều ngày
enum PromotionKind { bump, featured }

/// Một lượt quảng bá đã mua / dùng lượt tặng của tin
class PromotionRecord extends Equatable {
  const PromotionRecord({
    required this.id,
    required this.kind,
    required this.durationDays,
    required this.free,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final PromotionKind kind;
  final int durationDays;

  /// Dùng lượt tặng của gói (không trừ xu)
  final bool free;
  final DateTime startsAt;
  final DateTime endsAt;

  bool isRunningAt(DateTime now) => endsAt.isAfter(now);

  factory PromotionRecord.fromJson(Map<String, dynamic> json) =>
      PromotionRecord(
        id: '${json['id']}',
        kind: json['kind'] == 'FEATURED'
            ? PromotionKind.featured
            : PromotionKind.bump,
        durationDays: (json['durationDays'] as num?)?.toInt() ?? 1,
        free: json['source'] == 'INCLUDED',
        startsAt: _date(json['startsAt']) ?? DateTime.now(),
        endsAt: _date(json['endsAt']) ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id, kind, durationDays, free, startsAt, endsAt];
}

/// Thông tin trang quảng bá một tin (`GET /listings/:id/promotion`):
/// giá đẩy tin và các gói Hot sale đã giảm theo gói tài khoản, lượt đẩy tặng
/// còn lại, số xu trong ví, hạn đang chạy và các lượt gần đây
class ListingPromotion extends Equatable {
  const ListingPromotion({
    required this.listingId,
    required this.title,
    this.price,
    this.image,
    required this.promotable,
    required this.available,
    this.discountPercent = 0,
    required this.boostCredits,
    this.boostFreeLeft = 0,
    this.boostFreePerMonth = 0,
    this.boostRunningUntil,
    this.featureRunningUntil,
    this.featureOptions = const [],
    this.history = const [],
  });

  final String listingId;
  final String title;
  final int? price;
  final String? image;

  /// Tin đang hiển thị nên đẩy / lên Hot sale được
  final bool promotable;

  /// Số xu đang dùng được trong ví
  final int available;
  final int discountPercent;

  /// Giá đẩy tin khi hết lượt tặng (đã giảm theo gói)
  final int boostCredits;
  final int boostFreeLeft;
  final int boostFreePerMonth;
  final DateTime? boostRunningUntil;
  final DateTime? featureRunningUntil;
  final List<FeatureOption> featureOptions;
  final List<PromotionRecord> history;

  /// Lượt đẩy tiếp theo miễn phí (còn lượt tặng của gói)
  bool get boostFree => boostFreeLeft > 0;

  /// Số xu phải trả cho lượt đẩy tiếp theo
  int get boostCost => boostFree ? 0 : boostCredits;

  factory ListingPromotion.fromJson(Map<String, dynamic> json) {
    final boost = Map<String, dynamic>.from(json['boost'] as Map? ?? const {});
    final feature = Map<String, dynamic>.from(
      json['feature'] as Map? ?? const {},
    );
    return ListingPromotion(
      listingId: '${json['listingId']}',
      title: '${json['title'] ?? ''}',
      price: num.tryParse('${json['price']}')?.toInt(),
      image: json['image'] is String
          ? resolveMediaUrl(json['image'] as String)
          : null,
      promotable: json['promotable'] == true,
      available: (json['available'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      boostCredits: (boost['credits'] as num?)?.toInt() ?? 0,
      boostFreeLeft: (boost['freeLeft'] as num?)?.toInt() ?? 0,
      boostFreePerMonth: (boost['freePerMonth'] as num?)?.toInt() ?? 0,
      boostRunningUntil: _date(boost['runningUntil']),
      featureRunningUntil: _date(feature['runningUntil']),
      featureOptions: [
        for (final option in feature['options'] as List? ?? const [])
          if (option is Map)
            FeatureOption.fromJson(Map<String, dynamic>.from(option)),
      ],
      history: [
        for (final item in json['history'] as List? ?? const [])
          if (item is Map)
            PromotionRecord.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  @override
  List<Object?> get props => [
    listingId,
    title,
    price,
    image,
    promotable,
    available,
    discountPercent,
    boostCredits,
    boostFreeLeft,
    boostFreePerMonth,
    boostRunningUntil,
    featureRunningUntil,
    featureOptions.map((o) => o.packageId).toList(),
    history,
  ];
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();
