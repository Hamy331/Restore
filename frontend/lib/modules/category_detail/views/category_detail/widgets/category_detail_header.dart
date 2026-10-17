import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_bar.dart';

/// Phần ghim đầu trang danh mục: nút quay lại, icon và tên danh mục, nút
/// tìm kiếm và hàng lọc nhanh
class CategoryDetailHeader extends StatelessWidget {
  /// null khi chưa tải xong thông tin danh mục
  final CategoryModel? category;
  final ListingFilter filter;
  final ListingFilter defaults;
  final VoidCallback onBack;
  final VoidCallback onSearchTap;
  final VoidCallback onFiltersTap;
  final ValueChanged<ListingDealType> onDealToggle;
  final VoidCallback onSortTap;
  final VoidCallback onClearTap;

  const CategoryDetailHeader({
    super.key,
    required this.category,
    required this.filter,
    required this.defaults,
    required this.onBack,
    required this.onSearchTap,
    required this.onFiltersTap,
    required this.onDealToggle,
    required this.onSortTap,
    required this.onClearTap,
  });

  /// Hàng tiêu đề (48) + khoảng cách + hàng chip lọc + lề trên dưới
  static const double height = 8 + 48 + 10 + AppFilterChip.height + 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
              child: Row(
                children: [
                  AppCircleIconButton(
                    icon: AppIcons.back,
                    tooltip: l10n.back,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _CategoryTitle(category: category)),
                  const SizedBox(width: 12),
                  AppCircleIconButton(
                    icon: AppIcons.search,
                    tooltip: l10n.categoryDetailSearch,
                    onTap: onSearchTap,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppListingFilterBar(
            filter: filter,
            defaults: defaults,
            onFiltersTap: onFiltersTap,
            onDealToggle: onDealToggle,
            onSortTap: onSortTap,
            onClearTap: onClearTap,
          ),
        ],
      ),
    );
  }
}

/// Icon trong vòng tròn kem (giống hàng danh mục trang chủ) kèm tên danh
/// mục; hiện khung mờ khi chưa có danh mục
class _CategoryTitle extends StatelessWidget {
  final CategoryModel? category;

  const _CategoryTitle({required this.category});

  @override
  Widget build(BuildContext context) {
    final category = this.category;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cream,
          ),
          child: category == null
              ? null
              : Icon(
                  AppIcons.forCategory(category.iconKey),
                  size: 18,
                  color: AppColors.primaryDark,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: category == null
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : Text(
                  category.name.of(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
        ),
      ],
    );
  }
}
