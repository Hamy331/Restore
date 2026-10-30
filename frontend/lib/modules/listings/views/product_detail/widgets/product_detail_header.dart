import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/gallery/app_image_gallery.dart';

import 'product_detail_circle_button.dart';

/// Ảnh sản phẩm chiếm phần đầu trang, thu lại thành thanh tiêu đề khi cuộn.
/// Nút quay lại / lưu tin / thêm luôn nổi phía trên ảnh.
class ProductDetailHeader extends StatelessWidget {
  /// null khi chưa có dữ liệu (hiện khung trống)
  final List<String>? images;
  final String heroTag;
  final String title;

  /// Đã cuộn qua ảnh, hiện tiêu đề trên thanh
  final bool collapsed;

  /// null thì ẩn nút lưu tin (đang tải hoặc tin của chính mình)
  final bool? isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback? onMore;

  const ProductDetailHeader({
    super.key,
    required this.images,
    required this.heroTag,
    required this.title,
    required this.collapsed,
    required this.isFavorite,
    required this.onBack,
    required this.onFavorite,
    this.onMore,
  });

  /// Ảnh vuông theo chiều rộng màn hình, giới hạn trên màn hình lớn
  static double galleryHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width.clamp(0, size.height * 0.6).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;
    final favorite = isFavorite;

    Widget slot(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(child: child),
    );

    return SliverAppBar(
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: galleryHeight(context) - topPadding,
      shape: collapsed
          ? const Border(bottom: BorderSide(color: AppColors.border))
          : null,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: slot(
          ProductDetailCircleButton(
            icon: AppIcons.back,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
          ),
        ),
      ),
      titleSpacing: 4,
      title: AnimatedOpacity(
        opacity: collapsed ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      actions: [
        if (favorite != null)
          slot(
            ProductDetailCircleButton(
              icon: favorite ? AppIcons.favoriteActive : AppIcons.favorite,
              color: favorite ? AppColors.error : AppColors.textPrimary,
              tooltip: favorite ? l10n.homeUnsaveListing : l10n.homeSaveListing,
              onPressed: onFavorite,
            ),
          ),
        if (onMore != null)
          slot(
            ProductDetailCircleButton(
              icon: AppIcons.more,
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              onPressed: onMore,
            ),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: switch (images) {
          final images? => AppImageGallery(images: images, heroTag: heroTag),
          null => const ColoredBox(color: AppColors.cream),
        },
      ),
    );
  }
}
