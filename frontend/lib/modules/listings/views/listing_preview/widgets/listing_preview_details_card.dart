import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../../../bloc/create_listing/create_listing_state.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import '../../../utils/attribute_value_formatter.dart';
import 'listing_preview_card.dart';

/// Bảng thông tin chi tiết theo danh mục (ẩn khi chưa nhập thuộc tính nào)
class ListingPreviewDetailsCard extends StatelessWidget {
  final CreateListingState state;
  const ListingPreviewDetailsCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Chỉ hiện thuộc tính đã nhập, giống trang chi tiết tin người mua sẽ thấy
    final rows = <(String, String)>[
      for (final attribute
          in state.category?.attributes ?? const <CategoryAttributeModel>[])
        if (AttributeValueFormatter.format(
              context,
              attribute,
              state.draft.attributes[attribute.key],
            )
            case final value?)
          (attribute.label.of(context), value),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return ListingPreviewCard(
      title: l10n.detailedInfoTitle,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                        fontSize: 14,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
