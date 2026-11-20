import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/app_search_pill.dart';
import 'package:restore/shared/widgets/app_underline_tabs.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_bar.dart';

import '../../../bloc/search_results_state.dart';

/// Phần ghim đầu trang kết quả: nút quay lại, ô hiện từ khoá (bấm để sửa),
/// tab Tin đăng / Cửa hàng / Người dùng và hàng lọc nhanh (chỉ ở tab Tin đăng)
class SearchResultsHeader extends StatelessWidget {
  final String query;
  final SearchResultsTab tab;
  final ValueChanged<SearchResultsTab> onTabChanged;
  final ListingFilter filter;
  final VoidCallback onBack;
  final VoidCallback onEditQuery;
  final VoidCallback onFiltersTap;
  final ValueChanged<ListingDealType> onDealToggle;
  final VoidCallback onSortTap;
  final VoidCallback onClearTap;

  /// false: ẩn nút quay lại + ô từ khoá (màn rộng đã có ô tìm kiếm ở trên)
  final bool showSearch;

  const SearchResultsHeader({
    super.key,
    required this.query,
    required this.tab,
    required this.onTabChanged,
    required this.filter,
    required this.onBack,
    required this.onEditQuery,
    required this.onFiltersTap,
    required this.onDealToggle,
    required this.onSortTap,
    required this.onClearTap,
    this.showSearch = true,
  });

  /// Ô tìm kiếm (48) + hàng tab + hàng chip lọc (tab Tin đăng) + lề trên dưới
  static double heightFor(SearchResultsTab tab, {bool showSearch = true}) =>
      8 +
      (showSearch ? 48 + 4 : 0) +
      AppUnderlineTabs.height +
      (tab == SearchResultsTab.listings ? 10 + AppFilterChip.height : 0) +
      12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          if (showSearch) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
              child: Row(
                children: [
                  AppCircleIconButton(
                    icon: AppIcons.back,
                    tooltip: l10n.back,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppSearchPill(
                      text: query,
                      isPlaceholder: false,
                      onTap: onEditQuery,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          AppUnderlineTabs(
            labels: [
              l10n.searchTabListings,
              l10n.searchShopsSection,
              l10n.searchUsersSection,
            ],
            selectedIndex: tab.index,
            onChanged: (index) => onTabChanged(SearchResultsTab.values[index]),
          ),
          if (tab == SearchResultsTab.listings) ...[
            const SizedBox(height: 10),
            AppListingFilterBar(
              filter: filter,
              defaults: SearchResultsState.defaultFilter,
              onFiltersTap: onFiltersTap,
              onDealToggle: onDealToggle,
              onSortTap: onSortTap,
              onClearTap: onClearTap,
            ),
          ],
        ],
      ),
    );
  }
}
