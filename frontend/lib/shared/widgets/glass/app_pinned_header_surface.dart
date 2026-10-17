import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/core/theme/app_header_palette.dart';

/// Nền cho phần đầu trang được ghim khi cuộn (ô tìm kiếm, hàng lọc...).
/// Bình thường liền màu với đầu trang ([AppHeaderPalette.bottom]); khi đã
/// ghim ([pinned]) thì chuyển sang kính mờ trắng với một đường mảnh phía dưới.
class AppPinnedHeaderSurface extends StatelessWidget {
  final bool pinned;
  final Widget child;

  const AppPinnedHeaderSurface({
    super.key,
    required this.pinned,
    required this.child,
  });

  /// Nền kính khi đã ghim, dùng chung với dải thanh trạng thái phía trên
  static final Color pinnedColor = Colors.white.withValues(alpha: 0.86);

  @override
  Widget build(BuildContext context) {
    // Giữ nguyên cấu trúc cây ở cả hai trạng thái, chỉ bật/tắt hiệu ứng
    return ClipRect(
      child: BackdropFilter(
        enabled: pinned,
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurSigma,
          sigmaY: AppGlass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: pinned ? pinnedColor : AppHeaderPalette.bottom,
            border: Border(
              bottom: BorderSide(
                color: pinned
                    ? AppColors.border.withValues(alpha: 0.8)
                    : AppHeaderPalette.bottom,
                width: 0.6,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Phần đầu ghim cao cố định [height], nền đổi theo trạng thái ghim
/// ([AppPinnedHeaderSurface]). Dùng cho ô tìm kiếm + hàng lọc ở các trang
/// danh sách:
///
/// ```dart
/// SliverPersistentHeader(
///   pinned: true,
///   delegate: AppPinnedHeaderDelegate(height: 112, child: ...),
/// )
/// ```
class AppPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  AppPinnedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return AppPinnedHeaderSurface(
      pinned: overlapsContent || shrinkOffset > 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(AppPinnedHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}
