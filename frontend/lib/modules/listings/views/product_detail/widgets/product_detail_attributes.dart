import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../utils/attribute_value_formatter.dart';
import 'product_detail_section.dart';

/// Bảng "Thông tin chi tiết" theo schema thuộc tính của danh mục.
/// Chỉ hiện thuộc tính người bán đã nhập; không có gì thì ẩn cả khối.
class ProductDetailAttributes extends StatelessWidget {
  final CategoryModel category;
  final Map<String, Object?> values;

  const ProductDetailAttributes({
    super.key,
    required this.category,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <(String, String)>[
      for (final attribute in category.attributes)
        if (AttributeValueFormatter.format(
              context,
              attribute,
              values[attribute.key]?.toString(),
            )
            case final value?)
          (attribute.label.of(context), value),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return ProductDetailSection(
      title: l10n.detailedInfoTitle,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.border))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
