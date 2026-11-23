import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';

import 'desktop_footer.dart';

/// Màn hình đủ rộng để dùng bố cục web desktop (header, footer, nội dung
/// 1200px ở giữa, hai bên để trống).
bool isDesktopLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AppDimesions.desktopWidth;

/// Trang gốc của menu Tài khoản trên desktop: vào bằng menu trái nên không
/// cần nút quay lại.
const _desktopSectionRoots = {
  '/account',
  '/account/my-reviews',
  '/account/ratings',
  '/settings',
  '/create-listing/drafts',
  '/boost',
  '/insights',
  '/my-shop',
  '/shop-posters',
  '/following',
  '/wanted-alerts',
  '/credits',
  '/plans',
};

/// Trang có cần nút quay lại không.
///
/// Điện thoại luôn cần. Trên desktop chỉ trang gốc của menu Tài khoản mở
/// bằng menu trái (`go`, không có trang phía dưới) là không cần; trang con
/// như Mua xu, Lịch sử, Tạo thông báo (mở chồng bằng `push`, hoặc không phải
/// trang gốc của menu) vẫn có nút quay lại để người dùng trở về.
bool needsBackButton(BuildContext context) {
  if (!isDesktopLayout(context)) return true;
  final router = GoRouter.maybeOf(context);
  if (router == null || router.canPop()) return true;
  // A page being removed can still build during a transition. Read the
  // active path directly instead of walking its nested navigators.
  return !_desktopSectionRoots.contains(router.state.uri.path);
}

/// Lề hai bên để nội dung rộng [content] nằm giữa màn hình
double desktopGutter(
  double width, {
  double content = AppDimesions.desktopContentWidth,
}) => math.max(24, (width - content) / 2);

/// Trang desktop cuộn dọc: nội dung căn giữa trong khung [contentWidth],
/// nền phủ hết màn hình, footer ở cuối trang.
class DesktopPage extends StatelessWidget {
  const DesktopPage({
    super.key,
    required this.slivers,
    this.controller,
    this.contentWidth = AppDimesions.desktopContentWidth,
    this.showFooter = true,
    this.padding = const EdgeInsets.only(top: 20, bottom: 40),
    this.onEndReached,
  });

  final List<Widget> slivers;
  final ScrollController? controller;
  final double contentWidth;
  final bool showFooter;
  final EdgeInsets padding;

  /// Gọi khi cuộn gần cuối trang (tải thêm tin)
  final VoidCallback? onEndReached;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _buildPage(constraints.maxWidth),
  );

  Widget _buildPage(double width) {
    final gutter = desktopGutter(width, content: contentWidth);
    final scroll = CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: padding.copyWith(left: gutter, right: gutter),
          sliver: SliverMainAxisGroup(slivers: slivers),
        ),
        if (showFooter && width >= AppDimesions.desktopWidth)
          const SliverToBoxAdapter(child: DesktopFooter()),
      ],
    );
    final end = onEndReached;
    return ColoredBox(
      color: AppColors.fill,
      child: end == null
          ? scroll
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical &&
                    n.metrics.extentAfter < 600) {
                  end();
                }
                return false;
              },
              child: scroll,
            ),
    );
  }
}

/// Khối nền trắng bo góc (giống các khối Danh mục, Flash sale của Shopee)
class DesktopBox extends StatelessWidget {
  const DesktopBox({
    super.key,
    required this.child,
    this.title,
    this.titleIcon,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.surface,
  });

  final Widget child;
  final String? title;
  final Widget? titleIcon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              child: Row(
                children: [
                  if (titleIcon != null) ...[
                    titleIcon!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Nút chữ "Xem tất cả >" ở góc phải tiêu đề khối
class DesktopSeeAll extends StatelessWidget {
  const DesktopSeeAll({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    iconAlignment: IconAlignment.end,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    icon: const Icon(Icons.chevron_right, size: 18),
    label: Text(label),
  );
}

/// Đặt nội dung trong khung [maxWidth] ở giữa, dùng cho widget không phải sliver
class DesktopCentered extends StatelessWidget {
  const DesktopCentered({
    super.key,
    required this.child,
    this.maxWidth = AppDimesions.desktopContentWidth,
  });
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
