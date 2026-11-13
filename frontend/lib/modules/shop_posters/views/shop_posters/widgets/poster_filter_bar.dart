import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../bloc/shop_posters_cubit.dart';

/// Hàng chip lọc poster cuộn ngang, kèm số poster mỗi mục
class PosterFilterBar extends StatelessWidget {
  const PosterFilterBar({
    super.key,
    required this.selected,
    required this.countOf,
    required this.onSelected,
  });

  final PosterFilter selected;
  final int Function(PosterFilter) countOf;
  final ValueChanged<PosterFilter> onSelected;

  String _label(AppLocalizations l, PosterFilter filter) => switch (filter) {
    PosterFilter.all => l.spFilterAll,
    PosterFilter.running => l.spFilterRunning,
    PosterFilter.pending => l.spFilterPending,
    PosterFilter.scheduled => l.spFilterScheduled,
    PosterFilter.rejected => l.spFilterRejected,
    PosterFilter.ended => l.spFilterEnded,
  };

  Widget _chip(AppLocalizations l, PosterFilter filter) {
    final active = filter == selected;
    final count = countOf(filter);
    return ChoiceChip(
      key: ValueKey('poster-filter-${filter.name}'),
      selected: active,
      showCheckmark: false,
      onSelected: (_) => onSelected(filter),
      label: Text(
        count > 0 ? '${_label(l, filter)} · $count' : _label(l, filter),
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: active ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.textPrimary,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: active ? AppColors.textPrimary : AppColors.border,
      ),
      shape: const StadiumBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in PosterFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(l, filter),
            ),
        ],
      ),
    );
  }
}
