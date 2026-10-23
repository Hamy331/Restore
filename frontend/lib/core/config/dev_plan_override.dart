import 'package:flutter/foundation.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';

import 'app_environment.dart';

/// Gói đang giả lập khi chạy dữ liệu mẫu, để đổi nhanh giữa Cá nhân / Bán
/// chuyên / Cửa hàng mà không cần đăng ký thật. Khi có API, gói lấy từ tài
/// khoản và nút đổi gói ở trang chủ tự ẩn.
class DevPlanOverride {
  DevPlanOverride._();

  /// Chỉ hiện nút đổi gói khi chạy dữ liệu mẫu
  static bool get enabled => AppEnvironment.useMockData;

  static final ValueNotifier<SubscriptionPlan> plan = ValueNotifier(
    SubscriptionPlan.personal,
  );

  /// Chuyển sang gói kế tiếp, hết vòng thì quay lại Cá nhân
  static void next() {
    const plans = SubscriptionPlan.values;
    plan.value = plans[(plan.value.index + 1) % plans.length];
  }
}
