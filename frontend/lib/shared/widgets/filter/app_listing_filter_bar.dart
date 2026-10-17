import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/distance_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';

import 'app_filter_bar.dart';
import 'listing_filter_labels.dart';

/// Hàng lọc nhanh của các trang danh sách tin (gần bạn, kết quả tìm kiếm,
/// danh mục...): Bộ lọc, bán kính (khi có [onRadiusTap]), kiểu giao dịch
/// (mua trực tiếp / trao đổi) và sắp xếp.
class AppListingFilterBar extends StatelessWidget {
  final ListingFilter filter;
  final VoidCallback onFiltersTap;
  final ValueChanged<ListingDealType> onDealToggle;
  final VoidCallback onSortTap;

  /// null thì ẩn chip bán kính (trang không lọc theo vị trí)
  final VoidCallback? onRadiusTap;

  const AppListingFilterBar({
    super.key,
    required this.filter,
    required this.onFiltersTap,
    required this.onDealToggle,
    required this.onSortTap,
    this.onRadiusTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final radius = filter.radiusKm;
    final onRadiusTap = this.onRadiusTap;

    return AppFilterBar(
      children: [
        AppFilterChip(
          label: l10n.nearbyFilters,
          icon: AppIcons.filter,
          badgeCount: filter.advancedCount,
          onTap: onFiltersTap,
        ),
        if (radius != null && onRadiusTap != null)
          AppFilterChip(
            label: l10n.nearbyRadiusChip(
              DistanceFormatter.format(radius, l10n, locale: locale),
            ),
            icon: AppIcons.nearby,
            hasDropdown: true,
            onTap: onRadiusTap,
          ),
        for (final type in ListingDealType.values)
          AppFilterChip(
            label: type.label(l10n),
            selected: filter.dealTypes.contains(type),
            onTap: () => onDealToggle(type),
          ),
        AppFilterChip(
          label: filter.sort.label(l10n),
          hasDropdown: true,
          onTap: onSortTap,
        ),
      ],
    );
  }
}
