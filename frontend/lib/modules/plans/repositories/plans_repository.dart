import 'package:dio/dio.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';

import '../models/plan_package.dart';

/// Gói tài khoản: xem gói, báo giá, mua / gia hạn / nâng cấp bằng xu.
/// Hợp đồng API: `/stores/packages`, `/stores/me`, `/stores/quote`,
/// `/stores/subscribe`.
abstract class PlansRepository {
  factory PlansRepository() =>
      AppEnvironment.useMockData ? MockPlansRepository() : ApiPlansRepository();

  Future<List<PlanPackage>> packages();

  Future<CurrentPlan> current();

  /// Lỗi 409 ném [PlanActionException]
  Future<PlanQuote> quote(String packageId);

  /// Trả xu và kích hoạt gói ngay. Lỗi 409 / 400 ném [PlanActionException]
  Future<void> subscribe(String packageId, {String? categoryId});
}

class ApiPlansRepository implements PlansRepository {
  ApiPlansRepository({ApiClient? apiClient})
    : _dio = (apiClient ?? ApiClient()).dio;

  final Dio _dio;

  Map<String, dynamic> _data(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<List<PlanPackage>> packages() async {
    final response = await _dio.get<Map<String, dynamic>>('/stores/packages');
    final data = response.data?['data'];
    return [
      for (final item in data is List ? data : const [])
        PlanPackage.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  @override
  Future<CurrentPlan> current() async => CurrentPlan.fromJson(
    _data(await _dio.get<Map<String, dynamic>>('/stores/me')),
  );

  @override
  Future<PlanQuote> quote(String packageId) => _conflicts(
    () async => PlanQuote.fromJson(
      _data(
        await _dio.get<Map<String, dynamic>>(
          '/stores/quote',
          queryParameters: {'packageId': packageId},
        ),
      ),
    ),
  );

  @override
  Future<void> subscribe(String packageId, {String? categoryId}) => _conflicts(
    () => _dio.post<void>(
      '/stores/subscribe',
      data: {
        'packageId': packageId,
        if (categoryId != null) 'categoryId': categoryId,
      },
    ),
  );

  /// Đổi lỗi nghiệp vụ (400 / 409 có mã) thành [PlanActionException]
  Future<T> _conflicts<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if ((status != 409 && status != 400) || data is! Map) rethrow;
      final details = data['details'];
      throw PlanActionException(
        '${data['code']}',
        message: data['error'] as String?,
        details: details is Map ? Map<String, dynamic>.from(details) : const {},
      );
    }
  }
}

/// Dữ liệu mẫu khi chạy không có backend
class MockPlansRepository implements PlansRepository {
  static const _personal = PlanPackage(
    id: 'personal',
    tier: 'PERSONAL',
    name: 'Cá nhân',
    priceCredits: 0,
    priorityLevel: 0,
    dailyListingLimit: 3,
    activeListingLimit: 5,
    draftLimit: 3,
  );
  static const _packages = [
    PlanPackage(
      id: 'basic',
      tier: 'BASIC',
      name: 'Bán chuyên',
      priceCredits: 99,
      priorityLevel: 1,
      dailyListingLimit: 10,
      activeListingLimit: 30,
      draftLimit: 10,
      monthlyPromotionQuota: 5,
      boostDiscountPercent: 20,
    ),
    PlanPackage(
      id: 'pro',
      tier: 'PRO',
      name: 'Cửa hàng',
      priceCredits: 299,
      priorityLevel: 2,
      dailyListingLimit: 30,
      activeListingLimit: 100,
      draftLimit: 30,
      monthlyPromotionQuota: 20,
      boostDiscountPercent: 30,
    ),
  ];

  CurrentPlan _current = const CurrentPlan(package: _personal);

  @override
  Future<List<PlanPackage>> packages() async => _packages;

  @override
  Future<CurrentPlan> current() async => _current;

  @override
  Future<PlanQuote> quote(String packageId) async {
    final target = _packages.firstWhere((item) => item.id == packageId);
    return PlanQuote(
      packageId: packageId,
      mode: PlanChangeMode.newPlan,
      price: target.priceCredits,
      credit: 0,
      amount: target.priceCredits,
      endsAt: DateTime.now().add(const Duration(days: 30)),
      available: 500,
    );
  }

  @override
  Future<void> subscribe(String packageId, {String? categoryId}) async {
    _current = CurrentPlan(
      package: _packages.firstWhere((item) => item.id == packageId),
      endsAt: DateTime.now().add(const Duration(days: 30)),
      categoryId: categoryId ?? _current.categoryId,
    );
  }
}
