import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/shared/widgets/search/app_search_list_tile.dart';

import '../../../bloc/search_state.dart';
import '../../../models/search_history_entry.dart';
import '../../../models/search_user_item.dart';
import '../../../widgets/search_shop_tile.dart';
import '../../../utils/category_matches.dart';
import '../../../widgets/search_user_tile.dart';

/// Nội dung khi đang gõ: dòng "Tìm …" để tìm ngay, vài cửa hàng và người
/// dùng khớp tên (bấm là mở trang shop / trang cá nhân), rồi lịch sử khớp và
/// gợi ý từ khoá (phần khớp được tô đậm)
class SearchSuggestionList extends StatelessWidget {
  final SearchState state;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onFill;
  final ValueChanged<SearchHistoryEntry> onRemoveHistory;
  final ValueChanged<TrustedShopItem> onOpenShop;
  final ValueChanged<SearchUserItem> onOpenUser;

  /// Danh mục có tên khớp từ khoá, hiện ngay dưới dòng "Tìm …"
  final List<CategoryMatch> categories;
  final ValueChanged<CategoryMatch> onOpenCategory;

  /// Co theo nội dung (khung gợi ý thả xuống dưới ô tìm kiếm trên desktop)
  final bool shrinkWrap;

  const SearchSuggestionList({
    super.key,
    required this.state,
    required this.onSubmit,
    required this.onFill,
    required this.onRemoveHistory,
    required this.onOpenShop,
    required this.onOpenUser,
    this.categories = const [],
    required this.onOpenCategory,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final query = state.query;

    return ListView(
      shrinkWrap: shrinkWrap,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(top: 10, bottom: bottom + 16),
      children: [
        AppSearchListTile(
          icon: AppIcons.search,
          iconColor: AppColors.primaryDark,
          title: l10n.searchForQuery(query),
          onTap: () => onSubmit(query),
        ),
        // Gõ đúng tên danh mục thì mở thẳng trang danh mục
        for (final match in categories)
          AppSearchListTile(
            icon: AppIcons.category,
            iconColor: AppColors.primaryDark,
            title: (match.sub?.name ?? match.parent.name).of(context),
            subtitle: match.sub == null
                ? l10n.searchCategorySuggestion
                : l10n.searchSubcategorySuggestion(
                    match.parent.name.of(context),
                  ),
            highlight: query,
            onTap: () => onOpenCategory(match),
          ),
        for (final shop in state.shops)
          SearchShopTile(
            item: shop,
            highlight: query,
            onTap: () => onOpenShop(shop),
          ),
        for (final user in state.users)
          SearchUserTile(
            user: user,
            highlight: query,
            onTap: () => onOpenUser(user),
          ),
        if (state.shops.isNotEmpty || state.users.isNotEmpty)
          const Divider(height: 17, indent: 16, endIndent: 16),
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
