import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/filter/listing_filter_labels.dart';

import '../../../bloc/wanted_alert_create/wanted_alert_create_state.dart';
import '../../../models/wanted_alert_draft.dart';

/// Hàng chip dưới ô tìm ở trang tạo thông báo: Bộ lọc (mở sheet dùng
/// chung), khu vực, kiểu giao dịch và nút xoá lọc. Không có sắp xếp vì tin
/// gợi ý luôn xếp theo độ giống.
class WantedAlertCreateFilterBar extends StatelessWidget {
  final WantedAlertDraft draft;
  final VoidCallback onFiltersTap;
  final VoidCallback onAreaTap;
  final ValueChanged<ListingDealType> onDealToggle;
  final VoidCallback onClearTap;

  const WantedAlertCreateFilterBar({
    super.key,
    required this.draft,
    required this.onFiltersTap,
    required this.onAreaTap,
    required this.onDealToggle,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = draft.filter;
    final activeCount = filter.activeCount(
      WantedAlertCreateState.defaultFilter,
    );
    final area = draft.area;

    return AppFilterBar(
      children: [
        AppFilterChip(
          label: l10n.listingFilterTitle,
          icon: AppIcons.filter,
          selected: activeCount > 0,
          badgeCount: activeCount,
          onTap: onFiltersTap,
        ),
        AppFilterChip(
          label: area?.name ?? l10n.wantedAlertNationwide,
          icon: AppIcons.location,
          selected: area != null,
          hasDropdown: true,
          onTap: onAreaTap,
        ),
        for (final type in ListingDealType.values)
          AppFilterChip(
            label: type.label(l10n),
            selected: filter.dealTypes.contains(type),
            onTap: () => onDealToggle(type),
          ),
        if (activeCount > 0)
          AppFilterChip(
            label: l10n.listingFilterReset,
            icon: AppIcons.close,
            onTap: onClearTap,
          ),
      ],
    );
  }
}
