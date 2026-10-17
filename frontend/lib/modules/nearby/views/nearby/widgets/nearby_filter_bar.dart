import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/distance_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';

/// Hàng lọc nhanh của trang Gần bạn: Bộ lọc, bán kính, kiểu giao dịch
/// (mua trực tiếp / trao đổi) và sắp xếp.
class NearbyFilterBar extends StatelessWidget {
  final ListingFilter filter;
  final VoidCallback onFiltersTap;
  final VoidCallback onRadiusTap;
  final ValueChanged<ListingDealType> onDealToggle;
  final VoidCallback onSortTap;

  const NearbyFilterBar({
    super.key,
    required this.filter,
    required this.onFiltersTap,
    required this.onRadiusTap,
    required this.onDealToggle,
    required this.onSortTap,
  });

  static String dealLabel(ListingDealType type, AppLocalizations l10n) =>
      switch (type) {
        ListingDealType.buy => l10n.listingDealBuy,
        ListingDealType.exchange => l10n.listingDealExchange,
      };

  static String sortLabel(ListingSort sort, AppLocalizations l10n) =>
      switch (sort) {
        ListingSort.nearest => l10n.listingSortNearest,
        ListingSort.newest => l10n.listingSortNewest,
        ListingSort.priceLow => l10n.listingSortPriceLow,
        ListingSort.priceHigh => l10n.listingSortPriceHigh,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final radius = filter.radiusKm;

    return AppFilterBar(
      children: [
        AppFilterChip(
          label: l10n.nearbyFilters,
          icon: AppIcons.filter,
          badgeCount: filter.advancedCount,
          onTap: onFiltersTap,
        ),
        if (radius != null)
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
            label: dealLabel(type, l10n),
            selected: filter.dealTypes.contains(type),
            onTap: () => onDealToggle(type),
          ),
        AppFilterChip(
          label: sortLabel(filter.sort, l10n),
          hasDropdown: true,
          onTap: onSortTap,
        ),
      ],
    );
  }
}
