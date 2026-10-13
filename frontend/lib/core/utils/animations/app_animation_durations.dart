import 'package:flutter/animation.dart';

/// Thông số animation dùng chung để mọi màn hình chuyển động đồng nhất
class AppAnimationDurations {
  AppAnimationDurations._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  /// Độ trễ giữa các phần tử khi xuất hiện lần lượt (stagger)
  static const Duration staggerStep = Duration(milliseconds: 60);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
}
