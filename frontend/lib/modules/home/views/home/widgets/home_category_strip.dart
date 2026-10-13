import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/category_model.dart';

/// Hàng danh mục cuộn ngang: icon trong vòng tròn kem, tên bên dưới
class HomeCategoryStrip extends StatelessWidget {
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;

  const HomeCategoryStrip({
    super.key,
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) => _CategoryItem(
          category: categories[index],
          onTap: () => onTap(categories[index]),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryItem({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = category.name.of(context);
    return Semantics(
      button: true,
      label: name,
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cream,
                ),
                child: Icon(
                  AppIcons.forCategory(category.iconKey),
                  size: 24,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
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
