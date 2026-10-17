import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/app_search_pill.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_bar.dart';

/// Phần ghim đầu trang kết quả: nút quay lại, ô hiện từ khoá (bấm để sửa)
/// và hàng lọc nhanh
class SearchResultsHeader extends StatelessWidget {
  final String query;
  final ListingFilter filter;
  final VoidCallback onBack;
  final VoidCallback onEditQuery;
  final VoidCallback onFiltersTap;
  final ValueChanged<ListingDealType> onDealToggle;
  final VoidCallback onSortTap;

  const SearchResultsHeader({
    super.key,
    required this.query,
    required this.filter,
    required this.onBack,
    required this.onEditQuery,
    required this.onFiltersTap,
    required this.onDealToggle,
    required this.onSortTap,
  });

  /// Ô tìm kiếm (48) + khoảng cách + hàng chip lọc + lề trên dưới
  static const double height = 8 + 48 + 10 + AppFilterChip.height + 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
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
          const SizedBox(height: 10),
          AppListingFilterBar(
            filter: filter,
            onFiltersTap: onFiltersTap,
            onDealToggle: onDealToggle,
            onSortTap: onSortTap,
          ),
        ],
      ),
    );
  }
}
