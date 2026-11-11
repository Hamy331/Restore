import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../bloc/promotion_hub_cubit.dart';

/// Chip lọc kèm số tin của từng nhóm, cuộn ngang
class HubFilterBar extends StatelessWidget {
  const HubFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final PromotionHubFilter selected;
  final Map<PromotionHubFilter, int> counts;
  final ValueChanged<PromotionHubFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    String label(PromotionHubFilter filter) => switch (filter) {
      PromotionHubFilter.all => l.hubFilterAll,
      PromotionHubFilter.running => l.hubFilterRunning,
      PromotionHubFilter.expiring => l.hubFilterExpiring,
      PromotionHubFilter.idle => l.hubFilterIdle,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in PromotionHubFilter.values) ...[
            ChoiceChip(
              key: ValueKey('hub-filter-${filter.name}'),
              label: Text('${label(filter)} · ${counts[filter] ?? 0}'),
              selected: filter == selected,
              showCheckmark: false,
              selectedColor: AppColors.primarySoft,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: filter == selected
                    ? AppColors.primary
                    : AppColors.border,
              ),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: filter == selected
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
