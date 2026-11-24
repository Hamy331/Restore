import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_category_icon.dart';

/// Danh mục đã chọn ở bước 1 (Danh mục con, trong Danh mục) kèm nút Đổi
class ListingCategorySummary extends StatelessWidget {
  const ListingCategorySummary({
    super.key,
    required this.category,
    this.onChange,
  });

  final CategoryModel category;

  /// null = không cho đổi (sửa tin đã đăng)
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sub = category.subcategory;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: AppCategoryIcon(
              imageUrl: category.imageUrl,
              iconKey: category.iconKey,
              size: 32,
              fallbackSize: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub?.name.of(context) ?? category.name.of(context),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (sub != null)
                  Text(
                    l10n.searchSubcategorySuggestion(category.name.of(context)),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (onChange != null)
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.actionPrimary,
              ),
              child: Text(
                l10n.categoryChange,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
