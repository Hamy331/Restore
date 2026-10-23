import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class StoreCategory {
  const StoreCategory({required this.id, required this.name});
  final String id;
  final String name;

  factory StoreCategory.fromJson(Map<String, dynamic> json) =>
      StoreCategory(id: json['id'] as String, name: json['name'] as String);
}

class StorePackage {
  const StorePackage({
    required this.id,
    required this.tier,
    required this.name,
    required this.dailyListingLimit,
    required this.activeListingLimit,
    required this.monthlyPromotionQuota,
    required this.priorityLevel,
    required this.monthlyPrice,
  });

  final String id;
  final String tier;
  final String name;
  final int dailyListingLimit;
  final int activeListingLimit;
  final int monthlyPromotionQuota;
  final int priorityLevel;
  final String monthlyPrice;

  factory StorePackage.fromJson(Map<String, dynamic> json) => StorePackage(
    id: json['id'] as String,
    tier: json['tier'] as String,
    name: json['name'] as String,
    dailyListingLimit: json['dailyListingLimit'] as int,
    activeListingLimit: json['activeListingLimit'] as int,
    monthlyPromotionQuota: json['monthlyPromotionQuota'] as int,
    priorityLevel: json['priorityLevel'] as int,
    monthlyPrice: json['monthlyPrice'] as String,
  );
}

class StoreSummary {
  const StoreSummary({
    required this.package,
    required this.endsAt,
    required this.today,
    required this.active,
    required this.promotionsThisMonth,
    required this.category,
    required this.pendingOrderId,
  });

  final StorePackage package;
  final DateTime? endsAt;
  final int today;
  final int active;
  final int promotionsThisMonth;
  final StoreCategory? category;
  final String? pendingOrderId;

  int get remainingPromotions =>
      (package.monthlyPromotionQuota - promotionsThisMonth).clamp(0, 999999);

  factory StoreSummary.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>;
    return StoreSummary(
      package: StorePackage.fromJson(json['package'] as Map<String, dynamic>),
      endsAt: json['endsAt'] == null
          ? null
          : DateTime.parse(json['endsAt'] as String).toLocal(),
      today: usage['today'] as int,
      active: usage['active'] as int,
      promotionsThisMonth: usage['promotionsThisMonth'] as int,
      category: json['category'] == null
          ? null
          : StoreCategory.fromJson(json['category'] as Map<String, dynamic>),
      pendingOrderId:
          (json['pendingOrder'] as Map<String, dynamic>?)?['id'] as String?,
    );
  }
}

class PromotionPackage {
  const PromotionPackage({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.priority,
    required this.kind,
    required this.active,
  });

  final String id;
  final String name;
  final int durationDays;
  final String price;
  final int priority;
  final String kind;
  final bool active;

  factory PromotionPackage.fromJson(Map<String, dynamic> json) =>
      PromotionPackage(
        id: json['id'] as String,
        name: json['name'] as String,
        durationDays: json['durationDays'] as int,
        price: json['price'] as String,
        priority: json['priority'] as int,
        kind: json['kind'] as String,
        active: json['active'] as bool,
      );
}

class StoreRepository {
  StoreRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;
  final Dio _dio;

  Future<List<StoreCategory>> categories() async {
    final response = await _dio.get<Map<String, dynamic>>('/stores/categories');
    return (response.data!['data'] as List)
        .map((item) => StoreCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<StorePackage>> packages() async {
    final response = await _dio.get<Map<String, dynamic>>('/stores/packages');
    return (response.data!['data'] as List)
        .map((item) => StorePackage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StoreSummary> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/stores/me');
    return StoreSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<List<PromotionPackage>> promotionPackages() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/promotions/packages',
    );
    return (response.data!['data'] as List)
        .where((item) => (item as Map<String, dynamic>)['active'] == true)
        .map((item) => PromotionPackage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<PromotionPackage>> allPromotionPackages() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/promotions/packages',
    );
    return (response.data!['data'] as List)
        .map((item) => PromotionPackage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePromotionPackage({
    String? id,
    required String name,
    required String kind,
    required int durationDays,
    required String price,
    required int priority,
    required bool active,
  }) async {
    final data = {
      'name': name,
      'kind': kind,
      'durationDays': durationDays,
      'price': price,
      'priority': priority,
      'active': active,
    };
    if (id == null) {
      await _dio.post<Map<String, dynamic>>('/promotions/packages', data: data);
    } else {
      await _dio.put<Map<String, dynamic>>(
        '/promotions/packages/${Uri.encodeComponent(id)}',
        data: data,
      );
    }
  }

  Future<void> redeem({
    required String listingId,
    required String packageId,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/promotions/redeem',
      data: {'listingId': listingId, 'packageId': packageId},
    );
  }

  Future<String> orderStorePackage({
    required String packageId,
    required String categoryId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/stores/orders',
      data: {'packageId': packageId, 'categoryId': categoryId},
    );
    return (response.data!['data'] as Map<String, dynamic>)['id'] as String;
  }

  Future<String> orderPromotion({
    required String listingId,
    required String packageId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/promotions/orders',
      data: {'listingId': listingId, 'packageId': packageId},
    );
    return (response.data!['data'] as Map<String, dynamic>)['id'] as String;
  }

  Future<List<Map<String, dynamic>>> pendingOrders(String type) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/$type/admin/orders',
    );
    return (response.data!['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> decideOrder(
    String type,
    String id, {
    required bool confirm,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/$type/admin/orders/${Uri.encodeComponent(id)}/${confirm ? 'confirm' : 'reject'}',
    );
  }
}
