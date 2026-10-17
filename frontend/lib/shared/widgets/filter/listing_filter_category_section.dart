import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/bloc/listing_filter/listing_filter_state.dart';

import 'app_filter_bar.dart';
import 'listing_filter_section.dart';

/// Chọn một danh mục (hoặc "Tất cả") trong sheet Bộ lọc.
/// Danh mục tải từ API nên có trạng thái đang tải và lỗi.
class ListingFilterCategorySection extends StatelessWidget {
  final ListingFilterOptionsStatus status;
  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onRetry;

  const ListingFilterCategorySection({
    super.key,
    required this.status,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListingFilterSection(
      title: l10n.listingFilterCategory,
      child: switch (status) {
        ListingFilterOptionsStatus.loading => const _CategorySkeleton(),
        ListingFilterOptionsStatus.failure => Row(
          children: [
            const Icon(AppIcons.offline, size: 18, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.listingFilterCategoryError,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
        ListingFilterOptionsStatus.ready => ListingFilterChipWrap(
          children: [
            AppFilterChip(
              label: l10n.listingFilterAllCategories,
              icon: AppIcons.category,
              selected: selectedId == null,
              onTap: () => onSelected(null),
            ),
            for (final category in categories)
              AppFilterChip(
                label: category.name.of(context),
                icon: AppIcons.forCategory(category.iconKey),
                selected: category.id == selectedId,
                // Bấm lại danh mục đang chọn thì bỏ chọn
                onTap: () =>
                    onSelected(category.id == selectedId ? null : category.id),
              ),
          ],
        ),
      },
    );
  }
}

/// Khung chip mờ trong lúc chờ danh mục
class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  static const List<double> _widths = [72, 110, 96, 124, 88, 104];

  @override
  Widget build(BuildContext context) {
    return ListingFilterChipWrap(
      children: [
        for (final width in _widths)
          Container(
            width: width,
            height: AppFilterChip.height,
            decoration: ShapeDecoration(
              color: AppColors.border.withValues(alpha: 0.6),
              shape: const StadiumBorder(),
            ),
          ),
      ],
    );
  }
}
