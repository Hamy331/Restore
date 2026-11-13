import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';
import '../data/mock_posting_quota_store.dart';
import '../data/posting_quota_mock_data.dart';
import '../models/posting_quota.dart';

/// Hạn mức đăng tin của người dùng hiện tại
abstract class PostingQuotaRepository {
  Future<PostingQuota> getQuota();
}

/// Đọc dữ liệu mẫu (cùng cấu trúc JSON với API)
class MockPostingQuotaRepository implements PostingQuotaRepository {
  MockPostingQuotaRepository({
    this.latency = const Duration(milliseconds: 300),
  });

  final Duration latency;

  @override
  Future<PostingQuota> getQuota() async {
    await Future<void>.delayed(latency);
    // Loại tài khoản và giới hạn đi theo gói đang chọn ở nút test đổi gói
    final plan = DevPlanOverride.plan.value;
    final totalUsed = MockPostingQuotaStore.used.values.fold(
      0,
      (a, b) => a + b,
    );
    return PostingQuota.fromJson({
      ...PostingQuotaMockData.quota,
      'tier': switch (plan) {
        SubscriptionPlan.personal => 'PERSONAL',
        SubscriptionPlan.pro => 'BASIC',
        SubscriptionPlan.shop => 'PRO',
      },
      if (plan != SubscriptionPlan.personal) ...{
        'accountType': 'business',
        'defaultLimit': plan == SubscriptionPlan.shop
            ? PostingQuotaMockData.shopLimit
            : PostingQuotaMockData.proLimit,
      },
      'total': {
        'used': totalUsed,
        if (plan == SubscriptionPlan.personal)
          'limit': PostingQuotaMockData.personalTotal,
      },
      'categories': [
        for (final entry in MockPostingQuotaStore.used.entries)
          {
            'categoryId': entry.key,
            'used': entry.value,
            'limit': MockPostingQuotaStore.limitOf(entry.key),
            'extraCredits': MockPostingQuotaStore.extraCreditsOf(entry.key),
            'blockedBy': entry.value >= MockPostingQuotaStore.limitOf(entry.key)
                ? 'CATEGORY'
                : (plan == SubscriptionPlan.personal &&
                          totalUsed >= PostingQuotaMockData.personalTotal
                      ? 'TOTAL'
                      : null),
          },
      ],
    });
  }
}

/// Gọi `GET /listings/posting-quota`. Không giữ cache vì số tin thay đổi mỗi lần
/// đăng, ẩn hoặc bán tin.
class ApiPostingQuotaRepository implements PostingQuotaRepository {
  ApiPostingQuotaRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<PostingQuota> getQuota() async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      '/listings/posting-quota',
    );
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return PostingQuota.fromJson(Map<String, dynamic>.from(data));
  }
}
