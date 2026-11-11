import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';

import '../models/plan_package.dart';
import '../repositories/plans_repository.dart';

/// Giữ gói đang dùng cho toàn app (menu nút giữa, lời chào trang chủ, hạn mức
/// mẫu) theo gói thật của tài khoản. Dùng chung [DevPlanOverride.plan].
class PlanSession {
  PlanSession._();

  static void apply(CurrentPlan current) {
    DevPlanOverride.plan.value = current.isActiveAt(DateTime.now())
        ? current.package.plan
        : SubscriptionPlan.personal;
  }

  /// Tải gói đang dùng; lỗi (chưa đăng nhập, mất mạng) thì giữ nguyên.
  /// Chạy dữ liệu mẫu thì giữ gói đang chọn bằng nút TEST.
  static Future<void> refresh([PlansRepository? repository]) async {
    if (repository == null && AppEnvironment.useMockData) return;
    try {
      apply(await (repository ?? PlansRepository()).current());
    } catch (_) {}
  }
}
