import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/search/app_search_list_tile.dart';

import '../../../bloc/search_state.dart';
import '../../../models/search_history_entry.dart';

/// Nội dung khi đang gõ: dòng "Tìm …" để tìm ngay, rồi lịch sử khớp và
/// gợi ý từ khoá (phần khớp được tô đậm)
class SearchSuggestionList extends StatelessWidget {
  final SearchState state;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onFill;
  final ValueChanged<SearchHistoryEntry> onRemoveHistory;

  const SearchSuggestionList({
    super.key,
    required this.state,
    required this.onSubmit,
    required this.onFill,
    required this.onRemoveHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final query = state.query;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(top: 10, bottom: bottom + 16),
      children: [
        AppSearchListTile(
          icon: AppIcons.search,
          iconColor: AppColors.primaryDark,
          title: l10n.searchForQuery(query),
          onTap: () => onSubmit(query),
        ),
        for (final entry in state.matchingHistory)
          AppSearchListTile(
            icon: AppIcons.history,
            title: entry.keyword,
            highlight: query,
            onTap: () => onSubmit(entry.keyword),
            onRemove: () => onRemoveHistory(entry),
          ),
        for (final keyword in state.freshSuggestions)
          AppSearchListTile(
            icon: AppIcons.search,
            title: keyword,
            highlight: query,
            onTap: () => onSubmit(keyword),
            onFill: () => onFill(keyword),
          ),
      ],
    );
  }
}
