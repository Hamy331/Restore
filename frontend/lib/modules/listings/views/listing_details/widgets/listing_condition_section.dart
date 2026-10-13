import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_field_message.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/listing_condition.dart';

/// Danh sách mức tình trạng sản phẩm (dùng chung mọi danh mục), mỗi mức có mô tả ngắn
/// để người bán chọn đúng dù là điện thoại, quần áo hay đồ nội thất.
class ListingConditionSection extends StatelessWidget {
  final ListingCondition? selected;
  final bool hasError;
  final ValueChanged<ListingCondition> onSelected;

  const ListingConditionSection({
    super.key,
    required this.selected,
    required this.onSelected,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final condition in ListingCondition.values) ...[
          _ConditionTile(
            title: condition.label(l10n),
            description: condition.description(l10n),
            isSelected: condition == selected,
            hasError: hasError,
            onTap: () => onSelected(condition),
          ),
          if (condition != ListingCondition.values.last)
            const SizedBox(height: 8),
        ],
        AppFieldMessage(
          errorText: hasError ? l10n.fieldSelectRequiredError : null,
        ),
      ],
    );
  }
}

class _ConditionTile extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final bool hasError;
  final VoidCallback onTap;

  const _ConditionTile({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: AppAnimationDurations.fast,
            curve: AppAnimationDurations.enterCurve,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primarySoft.withValues(alpha: 0.9)
                  : AppGlass.fillStrong,
              borderRadius: radius,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : hasError
                    ? AppColors.error.withValues(alpha: 0.5)
                    : AppGlass.stroke,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: AppAnimationDurations.fast,
                  child: Icon(
                    isSelected
                        ? AppIcons.radioOn
                        : AppIcons.radioOff,
                    key: ValueKey(isSelected),
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
