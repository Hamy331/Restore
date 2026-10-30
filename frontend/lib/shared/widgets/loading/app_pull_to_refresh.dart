import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

import 'app_loading_indicator.dart';

/// Kéo xuống để làm mới, dùng được cho mọi trang có danh sách cuộn.
///
/// Thay vòng xoay Material bằng viên thuốc trắng chứa [AppLoadingIndicator]
/// cho đồng bộ giao diện. Có hai cách đặt viên loading:
///
/// - Mặc định: nổi đè lên nội dung, cách mép trên [indicatorTop] (hợp với
///   trang có ảnh lớn ở đầu như trang chi tiết).
/// - [AppPullToRefresh.inline]: chèn ô [indicator] vào đúng chỗ trong danh
///   sách (VD ngay dưới ô tìm kiếm ghim), ô mở ra đẩy nội dung xuống nên
///   không bị header che và cũng không đè lên nút nào.
///
/// ```dart
/// AppPullToRefresh(
///   onRefresh: cubit.refresh,
///   child: CustomScrollView(...),
/// )
///
/// AppPullToRefresh.inline(
///   onRefresh: cubit.refresh,
///   builder: (context, indicator) => CustomScrollView(
///     slivers: [header, SliverToBoxAdapter(child: indicator), ...],
///   ),
/// )
/// ```
class AppPullToRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget? child;
  final Widget Function(BuildContext context, Widget indicator)? builder;

  /// Khoảng cách từ mép trên tới viên loading khi nổi đè lên nội dung
  final double indicatorTop;

  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required Widget this.child,
    this.indicatorTop = 12,
  }) : builder = null;

  const AppPullToRefresh.inline({
    super.key,
    required this.onRefresh,
    required Widget Function(BuildContext context, Widget indicator)
    this.builder,
  }) : child = null,
       indicatorTop = 0;

  /// Chiều cao ô chứa viên loading khi mở ở chế độ [AppPullToRefresh.inline]
  static const double inlineExtent = 56;

  @override
  State<AppPullToRefresh> createState() => _AppPullToRefreshState();
}

class _AppPullToRefreshState extends State<AppPullToRefresh> {
  RefreshIndicatorStatus? _status;

  static const Duration _duration = Duration(milliseconds: 220);

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

  Widget get _pill => AnimatedOpacity(
    opacity: _visible ? (_status == RefreshIndicatorStatus.drag ? 0.6 : 1) : 0,
    duration: const Duration(milliseconds: 180),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        animating: _busy || _status == RefreshIndicatorStatus.armed,
      ),
    ),
  );

  /// Ô mở ra trong danh sách để chứa viên loading
  Widget get _inlineSlot => AnimatedContainer(
    duration: _duration,
    curve: Curves.easeOutCubic,
    height: _visible ? AppPullToRefresh.inlineExtent : 0,
    clipBehavior: Clip.hardEdge,
    decoration: const BoxDecoration(),
    child: OverflowBox(
      minHeight: AppPullToRefresh.inlineExtent,
      maxHeight: AppPullToRefresh.inlineExtent,
      alignment: Alignment.bottomCenter,
      child: Center(child: _pill),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final indicator = RefreshIndicator.noSpinner(
      onRefresh: widget.onRefresh,
      onStatusChange: (status) {
        if (mounted && status != _status) setState(() => _status = status);
      },
      child: widget.child ?? widget.builder!(context, _inlineSlot),
    );
    if (widget.child == null) return indicator;

    return Stack(
      children: [
        indicator,
        Positioned(
          top: widget.indicatorTop,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -0.6),
                duration: _duration,
                curve: Curves.easeOutCubic,
                child: _pill,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
