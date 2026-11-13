import 'package:equatable/equatable.dart';

import 'shop_poster.dart';

/// Hạn mức poster theo gói và lượt đã dùng
class PosterLimits extends Equatable {
  const PosterLimits({
    required this.activeLimit,
    required this.monthlyLimit,
    required this.usedThisMonth,
    required this.slotsInUse,
    this.minDays = 3,
    this.maxDays = 14,
    this.maxLeadDays = 14,
    this.cooldownUntil,
  });

  /// Poster chạy hoặc chờ duyệt cùng lúc; 0 = gói không được đăng poster
  final int activeLimit;

  /// Poster gửi mỗi tháng
  final int monthlyLimit;
  final int usedThisMonth;

  /// Poster đang giữ suất (chờ duyệt hoặc đã duyệt, chưa kết thúc)
  final int slotsInUse;
  final int minDays;
  final int maxDays;

  /// Hẹn ngày bắt đầu trước tối đa bao nhiêu ngày
  final int maxLeadDays;

  /// Bị từ chối nhiều lần: khóa gửi tới lúc này
  final DateTime? cooldownUntil;

  bool get allowed => activeLimit > 0;
  int get monthlyLeft =>
      (monthlyLimit - usedThisMonth).clamp(0, monthlyLimit).toInt();

  factory PosterLimits.fromJson(Map<String, dynamic> json) => PosterLimits(
    activeLimit: (json['activeLimit'] as num?)?.toInt() ?? 0,
    monthlyLimit: (json['monthlyLimit'] as num?)?.toInt() ?? 0,
    usedThisMonth: (json['usedThisMonth'] as num?)?.toInt() ?? 0,
    slotsInUse: (json['slotsInUse'] as num?)?.toInt() ?? 0,
    minDays: (json['minDays'] as num?)?.toInt() ?? 3,
    maxDays: (json['maxDays'] as num?)?.toInt() ?? 14,
    maxLeadDays: (json['maxLeadDays'] as num?)?.toInt() ?? 14,
    cooldownUntil: DateTime.tryParse('${json['cooldownUntil']}')?.toLocal(),
  );

  @override
  List<Object?> get props => [
    activeLimit,
    monthlyLimit,
    usedThisMonth,
    slotsInUse,
    minDays,
    maxDays,
    maxLeadDays,
    cooldownUntil,
  ];
}

/// Shop của tài khoản (null khi chưa có trang shop)
class PosterShop extends Equatable {
  const PosterShop({
    required this.id,
    required this.name,
    this.verified = true,
  });

  final String id;
  final String name;

  /// Shop chưa xác minh thì poster được duyệt cũng chưa hiện công khai
  final bool verified;

  factory PosterShop.fromJson(Map<String, dynamic> json) => PosterShop(
    id: '${json['id']}',
    name: json['name'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, name, verified];
}

/// Dữ liệu trang quản lý poster
class ShopPosterOverview extends Equatable {
  const ShopPosterOverview({
    required this.shop,
    required this.limits,
    required this.posters,
  });

  final PosterShop? shop;
  final PosterLimits limits;
  final List<ShopPoster> posters;

  factory ShopPosterOverview.fromJson(Map<String, dynamic> json) =>
      ShopPosterOverview(
        shop: json['shop'] is Map
            ? PosterShop.fromJson(
                Map<String, dynamic>.from(json['shop'] as Map),
              )
            : null,
        limits: PosterLimits.fromJson(
          Map<String, dynamic>.from(json['limits'] as Map? ?? const {}),
        ),
        posters: [
          for (final item in json['posters'] as List? ?? const [])
            ShopPoster.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );

  ShopPosterOverview copyWith({
    List<ShopPoster>? posters,
    PosterLimits? limits,
  }) => ShopPosterOverview(
    shop: shop,
    limits: limits ?? this.limits,
    posters: posters ?? this.posters,
  );

  @override
  List<Object?> get props => [shop, limits, posters];
}
