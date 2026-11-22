import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/search/app_search_list_tile.dart';
import 'package:restore/shared/widgets/search/app_search_section_header.dart';

import '../../../bloc/search_state.dart';
import '../../../models/search_history_entry.dart';

/// Nội dung khi chưa gõ gì: lối tắt "Gần tôi", gợi ý tìm nhanh và lịch sử
class SearchIdleContent extends StatelessWidget {
  final SearchState state;
  final ValueChanged<String> onSubmit;
  final VoidCallback onNearMe;
  final ValueChanged<SearchHistoryEntry> onRemoveHistory;
  final VoidCallback onClearHistory;

  const SearchIdleContent({
    super.key,
    required this.state,
    required this.onSubmit,
    required this.onNearMe,
    required this.onRemoveHistory,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Desktop: gợi ý dạng chip, lịch sử 2 cột thay vì danh sách dọc dài
    final wide = isDesktopLayout(context);
    Widget historyTile(SearchHistoryEntry entry) => AppSearchListTile(
      icon: AppIcons.history,
      boxed: true,
      title: entry.keyword,
      subtitle: entry.searchedAt == null
          ? null
          : TimeAgoFormatter.format(entry.searchedAt!, l10n),
      onTap: () => onSubmit(entry.keyword),
      onRemove: () => onRemoveHistory(entry),
    );

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(top: 10, bottom: bottom + 16),
      children: [
        AppSearchListTile(
          icon: AppIcons.myLocation,
          iconColor: AppColors.primaryDark,
          boxed: true,
          title: l10n.searchNearMe,
          subtitle: l10n.searchNearMeSubtitle,
          onTap: onNearMe,
        ),
        if (state.trending.isNotEmpty) ...[
          const Divider(height: 20, indent: 16, endIndent: 16),
          AppSearchSectionHeader(title: l10n.searchTipsTitle),
          if (wide)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final keyword in state.trending)
                    AppFilterChip(
                      label: keyword,
                      icon: AppIcons.search,
                      onTap: () => onSubmit(keyword),
                    ),
                ],
              ),
            )
          else
            for (final keyword in state.trending)
              AppSearchListTile(title: keyword, onTap: () => onSubmit(keyword)),
        ],
        if (state.history.isNotEmpty) ...[
          AppSearchSectionHeader(
            title: l10n.searchHistoryTitle,
            actionLabel: l10n.searchClearHistory,
            onAction: onClearHistory,
          ),
          if (wide)
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                children: [
                  for (final entry in state.history)
                    SizedBox(
                      width: constraints.maxWidth / 2,
                      child: historyTile(entry),
                    ),
                ],
              ),
            )
          else
            for (final entry in state.history) historyTile(entry),
        ],
      ],
    );
  }
}
