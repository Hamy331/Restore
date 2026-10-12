import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Tên danh mục đã chọn kèm icon, nhắc người bán thông tin bên dưới theo danh mục nào
class ListingDetailsHeader extends StatelessWidget {
  final CategoryModel? category;

  const ListingDetailsHeader({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = this.category;
    if (category == null) return const SizedBox.shrink();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.forCategory(category.iconKey),
            size: 20,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.categoryWithName(category.name.of(context)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.categoryAttributesHint,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
