import 'package:flutter/material.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_bar.dart';

import '../../../bloc/nearby_state.dart';

/// Hàng lọc nhanh của trang Gần bạn: hàng lọc dùng chung kèm chip bán kính
class NearbyFilterBar extends StatelessWidget {
  final ListingFilter filter;
  final VoidCallback onFiltersTap;
  final VoidCallback onRadiusTap;
  final ValueChanged<ListingDealType> onDealToggle;
  final VoidCallback onSortTap;
  final VoidCallback onClearTap;

  const NearbyFilterBar({
    super.key,
    required this.filter,
    required this.onFiltersTap,
    required this.onRadiusTap,
    required this.onDealToggle,
    required this.onSortTap,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListingFilterBar(
      filter: filter,
      defaults: NearbyState.defaultFilter,
      onFiltersTap: onFiltersTap,
      onRadiusTap: onRadiusTap,
      onDealToggle: onDealToggle,
      onSortTap: onSortTap,
      onClearTap: onClearTap,
    );
  }
}
