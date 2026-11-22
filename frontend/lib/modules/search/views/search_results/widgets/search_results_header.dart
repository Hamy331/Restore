import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_underline_tabs.dart';
import 'package:restore/shared/widgets/search/app_listing_search_bar.dart';

import '../../../bloc/search_results_state.dart';

/// Phần ghim đầu trang kết quả: nút quay lại, ô hiện từ khoá (bấm để sửa),
/// tab Tin đăng / Cửa hàng / Người dùng. Thanh lọc nằm trong nội dung tab Tin
/// đăng (cuộn theo danh sách, như trang danh mục)
class SearchResultsHeader extends StatelessWidget {
  final String query;
  final SearchResultsTab tab;
  final ValueChanged<SearchResultsTab> onTabChanged;
  final VoidCallback onBack;
  final VoidCallback onEditQuery;

  /// Lưu tìm kiếm thành "Báo khi có hàng"
  final VoidCallback onSaveSearch;

  /// false: ẩn nút quay lại + ô từ khoá (màn rộng đã có ô tìm kiếm ở trên)
  final bool showSearch;

  /// Phần đầu đang trên nền xanh (chưa ghim, điện thoại): tab chữ trắng
  final bool onDark;

  const SearchResultsHeader({
    super.key,
    required this.query,
    required this.tab,
    required this.onTabChanged,
    required this.onBack,
    required this.onEditQuery,
    required this.onSaveSearch,
    this.showSearch = true,
    this.onDark = false,
  });

  /// Ô tìm kiếm (48) + hàng tab + lề trên dưới
  static double heightFor({bool showSearch = true}) =>
      8 + (showSearch ? 48 + 4 : 0) + AppUnderlineTabs.height + 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          if (showSearch) ...[
            AppListingSearchBar(
              text: query,
              onBack: onBack,
              onEdit: onEditQuery,
              onSave: onSaveSearch,
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
            onDark: onDark,
            onChanged: (index) => onTabChanged(SearchResultsTab.values[index]),
          ),
        ],
      ),
    );
  }
}
