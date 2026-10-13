import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

import 'app_loading_indicator.dart';

/// Kéo xuống để làm mới, dùng được cho mọi trang có danh sách cuộn.
///
/// Bọc quanh ListView/CustomScrollView; thay vòng xoay Material bằng viên
/// thuốc trắng chứa [AppLoadingIndicator] cho đồng bộ giao diện.
///
/// ```dart
/// AppPullToRefresh(
///   onRefresh: cubit.refresh,
///   child: CustomScrollView(...),
/// )
/// ```
class AppPullToRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  /// Khoảng cách từ mép trên tới viên loading (VD dưới header ghim)
  final double indicatorTop;

  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.indicatorTop = 12,
  });

  @override
  State<AppPullToRefresh> createState() => _AppPullToRefreshState();
}

class _AppPullToRefreshState extends State<AppPullToRefresh> {
  RefreshIndicatorStatus? _status;

  bool get _visible => switch (_status) {
    RefreshIndicatorStatus.drag ||
    RefreshIndicatorStatus.armed ||
    RefreshIndicatorStatus.snap ||
    RefreshIndicatorStatus.refresh => true,
    _ => false,
  };

  bool get _busy =>
      _status == RefreshIndicatorStatus.snap ||
      _status == RefreshIndicatorStatus.refresh;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: (status) {
            if (mounted && status != _status) setState(() => _status = status);
          },
          child: widget.child,
        ),
        Positioned(
          top: widget.indicatorTop,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -0.6),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _visible
                      ? (_status == RefreshIndicatorStatus.drag ? 0.6 : 1)
                      : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AppLoadingIndicator(
                      dotSize: 7,
                      animating:
                          _busy || _status == RefreshIndicatorStatus.armed,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
