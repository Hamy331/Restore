import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/app_search_pill.dart';
import 'package:restore/shared/widgets/app_underline_tabs.dart';

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

  /// false: ẩn nút quay lại + ô từ khoá (màn rộng đã có ô tìm kiếm ở trên)
  final bool showSearch;

  const SearchResultsHeader({
    super.key,
    required this.query,
    required this.tab,
    required this.onTabChanged,
    required this.onBack,
    required this.onEditQuery,
    this.showSearch = true,
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
        ],
      ),
    );
  }
}
