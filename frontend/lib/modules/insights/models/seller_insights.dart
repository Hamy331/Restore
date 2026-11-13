import 'package:equatable/equatable.dart';
import 'package:restore/core/network/media_url.dart';

/// Lượt xem và lượt lưu của một ngày (giờ Việt Nam)
class InsightDay extends Equatable {
  const InsightDay({required this.date, this.views = 0, this.saves = 0});

  final DateTime date;
  final int views;
  final int saves;

  factory InsightDay.fromJson(Map<String, dynamic> json) => InsightDay(
    date: DateTime.tryParse('${json['date']}') ?? DateTime(2000),
    views: (json['views'] as num?)?.toInt() ?? 0,
    saves: (json['saves'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [date, views, saves];
}

/// Một tin trong "Tin được xem nhiều": số liệu trong kỳ và quảng bá đang chạy
class InsightListing extends Equatable {
  const InsightListing({
    required this.id,
    required this.title,
    this.price,
    this.image,
    this.views = 0,
    this.saves = 0,
    this.totalViews = 0,
    this.expiresAt,
    this.bumpUntil,
    this.featuredUntil,
  });

  final String id;
  final String title;
  final int? price;
  final String? image;

  /// Lượt xem / lưu trong kỳ đang chọn
  final int views;
  final int saves;
  final int totalViews;
  final DateTime? expiresAt;
  final DateTime? bumpUntil;
  final DateTime? featuredUntil;

  bool isPromotedAt(DateTime now) =>
      (bumpUntil?.isAfter(now) ?? false) ||
      (featuredUntil?.isAfter(now) ?? false);

  factory InsightListing.fromJson(Map<String, dynamic> json) => InsightListing(
    id: '${json['id']}',
    title: '${json['title'] ?? ''}',
    price: num.tryParse('${json['price']}')?.toInt(),
    image: json['image'] is String
        ? resolveMediaUrl(json['image'] as String)
        : null,
    views: (json['views'] as num?)?.toInt() ?? 0,
    saves: (json['saves'] as num?)?.toInt() ?? 0,
    totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
    expiresAt: _date(json['expiresAt']),
    bumpUntil: _date(json['bumpUntil']),
    featuredUntil: _date(json['featuredUntil']),
  );

  @override
  List<Object?> get props => [
    id,
    title,
    price,
    image,
    views,
    saves,
    totalViews,
    expiresAt,
    bumpUntil,
    featuredUntil,
  ];
}

/// Một chỉ số kèm giá trị kỳ trước để so sánh
class InsightMetric extends Equatable {
  const InsightMetric(this.value, this.previous);

  final int value;
  final int previous;

  /// Phần trăm thay đổi so với kỳ trước (làm tròn), null khi kỳ trước bằng 0
  int? get changePercent =>
      previous == 0 ? null : ((value - previous) * 100 / previous).round();

  @override
  List<Object?> get props => [value, previous];
}

/// Trang Thống kê (`GET /listings/insights?days=`)
class SellerInsights extends Equatable {
  const SellerInsights({
    required this.days,
    this.views = const InsightMetric(0, 0),
    this.saves = const InsightMetric(0, 0),
    this.chats = const InsightMetric(0, 0),
    this.active = 0,
    this.pending = 0,
    this.hidden = 0,
    this.sold = 0,
    this.expiringSoon = 0,
    this.boosts = 0,
    this.features = 0,
    this.daily = const [],
    this.top = const [],
  });

  final int days;
  final InsightMetric views;
  final InsightMetric saves;
  final InsightMetric chats;
  final int active;
  final int pending;
  final int hidden;
  final int sold;

  /// Tin đang bán hết hạn trong 7 ngày tới (không tự gia hạn)
  final int expiringSoon;
  final int boosts;
  final int features;
  final List<InsightDay> daily;
  final List<InsightListing> top;

  factory SellerInsights.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(String key) =>
        Map<String, dynamic>.from(json[key] as Map? ?? const {});
    int n(Map<String, dynamic> m, String key) => (m[key] as num?)?.toInt() ?? 0;
    final totals = map('totals');
    final listings = map('listings');
    final promotions = map('promotions');
    return SellerInsights(
      days: (json['days'] as num?)?.toInt() ?? 7,
      views: InsightMetric(n(totals, 'views'), n(totals, 'viewsPrev')),
      saves: InsightMetric(n(totals, 'saves'), n(totals, 'savesPrev')),
      chats: InsightMetric(n(totals, 'chats'), n(totals, 'chatsPrev')),
      active: n(listings, 'active'),
      pending: n(listings, 'pending'),
      hidden: n(listings, 'hidden'),
      sold: n(listings, 'sold'),
      expiringSoon: n(listings, 'expiringSoon'),
      boosts: n(promotions, 'boosts'),
      features: n(promotions, 'features'),
      daily: [
        for (final day in json['daily'] as List? ?? const [])
          if (day is Map) InsightDay.fromJson(Map<String, dynamic>.from(day)),
      ],
      top: [
        for (final item in json['top'] as List? ?? const [])
          if (item is Map)
            InsightListing.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  @override
  List<Object?> get props => [
    days,
    views,
    saves,
    chats,
    active,
    pending,
    hidden,
    sold,
    expiringSoon,
    boosts,
    features,
    daily,
    top,
  ];
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value')?.toLocal();
