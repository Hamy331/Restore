import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_category_circle.dart';
import 'package:restore/shared/widgets/app_category_icon.dart';

/// Hàng danh mục trên web desktop: cùng kiểu với hàng danh mục điện thoại
/// (ô tròn, tên bên dưới, ô Hot sale đứng đầu), dàn đều hết bề ngang.
/// Vòng tròn dùng chung [AppCategoryCircle] nên ảnh thật / icon 3D giống
/// hệt bản điện thoại.
class HomeCategoryPhotoGrid extends StatelessWidget {
  const HomeCategoryPhotoGrid({
    super.key,
    required this.categories,
    required this.onTap,
    required this.onHotSaleTap,
    this.maxColumns = 11,
  });

  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;
  final VoidCallback onHotSaleTap;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = <Widget>[
      _Tile(
        label: l10n.hotSaleTitle,
        hot: true,
        onTap: onHotSaleTap,
        circle: AppCategoryCircle(
          size: 72,
          photo: hotSaleCategoryPhoto,
          background: const Color(0xFFFFE9E4),
          fallback: Image.asset(
            AppImages.coreImages.hotSale,
            width: 48,
            height: 34,
            errorBuilder: (_, _, _) =>
                const Icon(AppIcons.hot, size: 24, color: AppColors.error),
          ),
        ),
      ),
      for (final category in categories)
        _Tile(
          label: category.name.of(context),
          onTap: () => onTap(category),
          circle: AppCategoryCircle(
            size: 72,
            photo: categoryPhotoFor(category),
            fallback: AppCategoryIcon(
              imageUrl: category.imageUrl,
              iconKey: category.iconKey,
              size: 46,
              fallbackSize: 28,
            ),
          ),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = tiles.length.clamp(1, maxColumns);
        final width = constraints.maxWidth / columns;
        return Wrap(
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.onTap,
    required this.circle,
    this.hot = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget circle;
  final bool hot;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 138,
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFF3EFE8)),
          bottom: BorderSide(color: Color(0xFFF3EFE8)),
        ),
      ),
      child: Column(
        children: [
          circle,
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.25,
              color: hot ? AppColors.error : AppColors.textPrimary,
              fontWeight: hot ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
