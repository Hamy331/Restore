import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';

import 'posting_quota_mock_data.dart';

/// Số tin đã dùng của từng chuyên mục khi chạy dữ liệu mẫu, giữ trong bộ
/// nhớ suốt phiên. Đăng tin mẫu xong thì tăng lên để giao diện hạn mức
/// cập nhật giống khi có API.
class MockPostingQuotaStore {
  MockPostingQuotaStore._();

  static List<Map> get _seed =>
      (PostingQuotaMockData.quota['categories'] as List).cast<Map>();

  static final Map<String, int> used = {
    for (final item in _seed) item['categoryId'] as String: item['used'] as int,
  };

  /// Giới hạn theo gói đang test: Bán chuyên 15, Cửa hàng 30 tin mỗi
  /// chuyên mục; Cá nhân theo bảng từng chuyên mục
  static int limitOf(String categoryId) {
    switch (DevPlanOverride.plan.value) {
      case SubscriptionPlan.pro:
        return PostingQuotaMockData.proLimit;
      case SubscriptionPlan.shop:
        return PostingQuotaMockData.shopLimit;
      case SubscriptionPlan.personal:
        break;
    }
    for (final item in _seed) {
      if (item['categoryId'] == categoryId) return item['limit'] as int;
    }
    return PostingQuotaMockData.personalLimit;
  }

  /// Giá xu một tin vượt hạn mức của chuyên mục
  static int? extraCreditsOf(String categoryId) {
    if (DevPlanOverride.plan.value != SubscriptionPlan.personal) return null;
    for (final item in _seed) {
      if (item['categoryId'] == categoryId) return item['extraCredits'] as int?;
    }
    return 5;
  }

  static void recordPublished(String categoryId) =>
      used[categoryId] = (used[categoryId] ?? 0) + 1;
}
