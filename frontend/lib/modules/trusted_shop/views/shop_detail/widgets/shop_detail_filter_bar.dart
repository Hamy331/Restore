import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';

/// Hàng lọc sản phẩm của shop, ghim dưới hàng tên shop khi cuộn tới.
/// Chưa ghim thì nền trắng liền phần nội dung, đã ghim thì thành kính mờ
/// như các phần đầu ghim khác ([AppPinnedHeaderSurface]).
class ShopDetailFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget filterBar;

  ShopDetailFilterBarDelegate({required this.filterBar});

  static const double _verticalPadding = 10;
  static const double height = _verticalPadding * 2 + AppFilterChip.height;

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
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
      child: filterBar,
    );
    return overlapsContent || shrinkOffset > 0
        ? AppPinnedHeaderSurface(pinned: true, child: content)
        : ColoredBox(color: AppColors.surface, child: content);
  }

  @override
  bool shouldRebuild(ShopDetailFilterBarDelegate oldDelegate) =>
      oldDelegate.filterBar != filterBar;
}
