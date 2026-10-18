import 'package:flutter/material.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';

/// Ẩn/hiện [child] bằng cách thu gọn kích thước kèm mờ dần (cả hai chiều).
/// Dùng cho các phần phụ cần gọn lại khi cuộn, VD nhãn của thanh bước.
class AppCollapsible extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Axis axis;
  final Duration duration;

  const AppCollapsible({
    super.key,
    required this.visible,
    required this.child,
    this.axis = Axis.vertical,
    this.duration = AppAnimationDurations.normal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppAnimationDurations.enterCurve,
      switchOutCurve: AppAnimationDurations.exitCurve,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axis: axis,
          // Giữ axisAlignment để chạy được cả Flutter 3.35 (alignment mới có từ 3.41)
          // ignore: deprecated_member_use
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: visible
          ? KeyedSubtree(key: const ValueKey(true), child: child)
          : SizedBox(
              key: const ValueKey(false),
              width: axis == Axis.vertical ? double.infinity : 0,
              height: axis == Axis.vertical ? 0 : null,
            ),
    );
  }
}
