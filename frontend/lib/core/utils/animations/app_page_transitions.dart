import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_animation_durations.dart';

/// Hiệu ứng chuyển trang dùng chung cho GoRoute (pageBuilder)
class AppPageTransitions {
  AppPageTransitions._();

  /// Trượt nhẹ từ phải sang kết hợp mờ dần, chỉ dùng transform/opacity nên không gây giật
  static CustomTransitionPage<T> fadeSlide<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppAnimationDurations.normal,
      reverseTransitionDuration: AppAnimationDurations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppAnimationDurations.enterCurve,
          reverseCurve: AppAnimationDurations.exitCurve,
        );
        // Trang phía dưới lùi nhẹ sang trái khi có trang mới đè lên
        final outgoing = CurvedAnimation(
          parent: secondaryAnimation,
          curve: AppAnimationDurations.enterCurve,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.08, 0),
          ).animate(outgoing),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.12, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          ),
        );
      },
    );
  }
}
