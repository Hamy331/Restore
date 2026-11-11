import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';

/// Gói tài khoản bán được (API `GET /stores/packages`), giá trả bằng xu
/// (1 xu = 1.000 đ), mỗi lần mua dùng 30 ngày.
class PlanPackage extends Equatable {
  const PlanPackage({
    required this.id,
    required this.tier,
    required this.name,
    required this.priceCredits,
    required this.priorityLevel,
    this.dailyListingLimit = 0,
    this.activeListingLimit = 0,
    this.draftLimit = 0,
    this.monthlyPromotionQuota = 0,
    this.boostDiscountPercent = 0,
  });

  final String id;

  /// PERSONAL, BASIC (Bán chuyên) hoặc PRO (Cửa hàng)
  final String tier;
  final String name;
  final int priceCredits;
  final int priorityLevel;
  final int dailyListingLimit;
  final int activeListingLimit;
  final int draftLimit;
  final int monthlyPromotionQuota;
  final int boostDiscountPercent;

  /// Gói tương ứng trong app (Cá nhân / Bán chuyên / Cửa hàng)
  SubscriptionPlan get plan => switch (tier) {
    'BASIC' => SubscriptionPlan.pro,
    'PRO' => SubscriptionPlan.shop,
    _ => SubscriptionPlan.personal,
  };

  bool get isPersonal => plan == SubscriptionPlan.personal;

  factory PlanPackage.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return PlanPackage(
      id: '${json['id']}',
      tier: '${json['tier']}',
      name: '${json['name'] ?? ''}',
      priceCredits: read('priceCredits'),
      priorityLevel: read('priorityLevel'),
      dailyListingLimit: read('dailyListingLimit'),
      activeListingLimit: read('activeListingLimit'),
      draftLimit: read('draftLimit'),
      monthlyPromotionQuota: read('monthlyPromotionQuota'),
      boostDiscountPercent: read('boostDiscountPercent'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    tier,
    name,
    priceCredits,
    priorityLevel,
    dailyListingLimit,
    activeListingLimit,
    draftLimit,
    monthlyPromotionQuota,
    boostDiscountPercent,
  ];
}

/// Gói đang dùng (API `GET /stores/me`): Cá nhân thì [endsAt] null
class CurrentPlan extends Equatable {
  const CurrentPlan({required this.package, this.endsAt, this.categoryId});

  final PlanPackage package;
  final DateTime? endsAt;

  /// Chuyên mục chính của gói trả phí
  final String? categoryId;

  /// Gói trả phí còn hạn
  bool isActiveAt(DateTime now) =>
      !package.isPersonal && endsAt != null && endsAt!.isAfter(now);

  factory CurrentPlan.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return CurrentPlan(
      package: PlanPackage.fromJson(
        Map<String, dynamic>.from(json['package'] as Map),
      ),
      endsAt: DateTime.tryParse('${json['endsAt']}')?.toLocal(),
      categoryId: category is Map ? '${category['id']}' : null,
    );
  }

  @override
  List<Object?> get props => [package, endsAt, categoryId];
}

/// Cách đổi sang gói mới: mua mới, gia hạn đúng gói, hoặc nâng gói giữa kỳ
enum PlanChangeMode {
  newPlan,
  renew,
  upgrade;

  static PlanChangeMode fromApi(Object? value) => switch (value) {
    'RENEW' => renew,
    'UPGRADE' => upgrade,
    _ => newPlan,
  };
}

/// Báo giá (API `GET /stores/quote`): [credit] là phần còn lại của gói cũ
/// được trừ khi nâng gói, [amount] là số xu phải trả.
class PlanQuote extends Equatable {
  const PlanQuote({
    required this.packageId,
    required this.mode,
    required this.price,
    required this.credit,
    required this.amount,
    required this.endsAt,
    required this.available,
  });

  final String packageId;
  final PlanChangeMode mode;
  final int price;
  final int credit;
  final int amount;
  final DateTime endsAt;
  final int available;

  bool get enough => available >= amount;

  factory PlanQuote.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return PlanQuote(
      packageId: '${json['packageId']}',
      mode: PlanChangeMode.fromApi(json['mode']),
      price: read('price'),
      credit: read('credit'),
      amount: read('amount'),
      endsAt:
          DateTime.tryParse('${json['endsAt']}')?.toLocal() ?? DateTime.now(),
      available: read('available'),
    );
  }

  @override
  List<Object?> get props => [
    packageId,
    mode,
    price,
    credit,
    amount,
    endsAt,
    available,
  ];
}

/// Backend từ chối mua gói (409 / 400): [code] như `NOT_ENOUGH_CREDITS`,
/// `STORE_DOWNGRADE_NOT_ALLOWED`, `STORE_CATEGORY_REQUIRED`
class PlanActionException implements Exception {
  const PlanActionException(this.code, {this.message, this.details = const {}});

  final String code;
  final String? message;
  final Map<String, dynamic> details;

  static const notEnoughCredits = 'NOT_ENOUGH_CREDITS';
  static const downgradeNotAllowed = 'STORE_DOWNGRADE_NOT_ALLOWED';

  @override
  String toString() => 'PlanActionException($code)';
}
