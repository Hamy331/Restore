import 'package:equatable/equatable.dart';
import 'package:restore/data/models/shop_model.dart';

/// Số liệu nhanh của shop trên trang Quản lý shop
class MyShopStats extends Equatable {
  const MyShopStats({
    this.followerCount = 0,
    this.listingCount = 0,
    this.runningPosters = 0,
    this.pendingPosters = 0,
  });

  final int followerCount;
  final int listingCount;
  final int runningPosters;
  final int pendingPosters;

  factory MyShopStats.fromJson(Map<String, dynamic> json) => MyShopStats(
    followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    listingCount: (json['listingCount'] as num?)?.toInt() ?? 0,
    runningPosters: (json['runningPosters'] as num?)?.toInt() ?? 0,
    pendingPosters: (json['pendingPosters'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [
    followerCount,
    listingCount,
    runningPosters,
    pendingPosters,
  ];
}

/// `GET /shops/me`: shop của mình (null nếu chưa mở), gói Cửa hàng còn hạn
/// không, có được mở shop không, tên có bị khoá (shop đã xác minh) không
class MyShopOverview extends Equatable {
  const MyShopOverview({
    this.shop,
    this.storePlan = false,
    this.planEndsAt,
    this.canCreate = false,
    this.nameLocked = false,
    this.stats,
  });

  final ShopModel? shop;
  final bool storePlan;
  final DateTime? planEndsAt;
  final bool canCreate;
  final bool nameLocked;
  final MyShopStats? stats;

  factory MyShopOverview.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'], stats = json['stats'];
    return MyShopOverview(
      shop: shop is Map
          ? ShopModel.fromJson(Map<String, dynamic>.from(shop))
          : null,
      storePlan: json['storePlan'] == true,
      planEndsAt: DateTime.tryParse('${json['planEndsAt']}')?.toLocal(),
      canCreate: json['canCreate'] == true,
      nameLocked: json['nameLocked'] == true,
      stats: stats is Map
          ? MyShopStats.fromJson(Map<String, dynamic>.from(stats))
          : null,
    );
  }

  @override
  List<Object?> get props => [
    shop,
    storePlan,
    planEndsAt,
    canCreate,
    nameLocked,
    stats,
  ];
}
