import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Hàng danh mục cuộn ngang: icon trong vòng tròn kem, tên bên dưới
/// [onHotSaleTap] khác null thì thêm ô Hot sale (icon ngọn lửa) đứng đầu.
class HomeCategoryStrip extends StatelessWidget {
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;
  final VoidCallback? onHotSaleTap;

  const HomeCategoryStrip({
    super.key,
    required this.categories,
    required this.onTap,
    this.onHotSaleTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final hot = onHotSaleTap;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + (hot == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          if (hot != null && index == 0) {
            return _StripItem(
              label: AppLocalizations.of(context)!.hotSaleTitle,
              onTap: hot,
              icon: Image.asset(
                AppImages.coreImages.hotFlame,
                width: 30,
                height: 30,
                errorBuilder: (_, _, _) =>
                    const Icon(AppIcons.hot, size: 24, color: AppColors.error),
              ),
            );
          }
          final category = categories[index - (hot == null ? 0 : 1)];
          return _StripItem(
            label: category.name.of(context),
            onTap: () => onTap(category),
            icon: Icon(
              AppIcons.forCategory(category.iconKey),
              size: 24,
              color: AppColors.primaryDark,
            ),
          );
        },
      ),
    );
  }
}

class _StripItem extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _StripItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cream,
                ),
                child: icon,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
