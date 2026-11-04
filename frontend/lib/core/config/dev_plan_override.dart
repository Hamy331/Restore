import 'package:flutter/foundation.dart';
import 'package:restore/data/models/enums/subscription_plan.dart';

import 'app_environment.dart';

/// Gói đang giả lập, để đổi nhanh giữa Cá nhân / Bán chuyên / Cửa hàng mà
/// không cần đăng ký thật. Đang mở cho cả khi gọi API để demo giao diện;
/// đổi gói ở đây chỉ đổi giao diện trong app, backend vẫn tính theo gói
/// thật. Tắt khi build phát hành: `--dart-define=DEV_PLAN_SWITCH=false`.
/// Khi có API gói đăng ký, gói lấy từ tài khoản và nút này tắt hẳn.
class DevPlanOverride {
  DevPlanOverride._();

  static const bool _switchDefine = bool.fromEnvironment(
    'DEV_PLAN_SWITCH',
    defaultValue: true,
  );

  /// Hiện nút TEST đổi gói ở trang chủ
  static bool get enabled => _switchDefine || AppEnvironment.useMockData;

  static final ValueNotifier<SubscriptionPlan> plan = ValueNotifier(
    SubscriptionPlan.personal,
  );

  /// Chuyển sang gói kế tiếp, hết vòng thì quay lại Cá nhân
  static void next() {
    const plans = SubscriptionPlan.values;
    plan.value = plans[(plan.value.index + 1) % plans.length];
  }
}
