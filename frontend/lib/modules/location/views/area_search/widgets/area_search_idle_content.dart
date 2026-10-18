import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/search/app_search_list_tile.dart';
import 'package:restore/shared/widgets/search/app_search_section_header.dart';

import '../../../models/area_option.dart';
import 'area_search_tile.dart';

/// Nội dung khi chưa gõ: "Gần tôi" (dùng GPS) và khu vực đã chọn gần đây.
/// Có [onNationwide] thì hiện "Toàn quốc" thay cho "Gần tôi".
class AreaSearchIdleContent extends StatelessWidget {
  final List<AreaOption> recent;
  final VoidCallback onMyLocation;
  final VoidCallback? onNationwide;
  final ValueChanged<AreaOption> onPick;
  final ValueChanged<AreaOption> onRemove;

  const AreaSearchIdleContent({
    super.key,
    required this.recent,
    required this.onMyLocation,
    required this.onPick,
    required this.onRemove,
    this.onNationwide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(top: 10, bottom: bottom + 16),
      children: [
        if (onNationwide case final onNationwide?)
          AppSearchListTile(
            icon: AppIcons.globe,
            iconColor: AppColors.primaryDark,
            boxed: true,
            title: l10n.areaNationwide,
            subtitle: l10n.areaNationwideSubtitle,
            onTap: onNationwide,
          )
        else
          AppSearchListTile(
            icon: AppIcons.myLocation,
            iconColor: AppColors.primaryDark,
            boxed: true,
            title: l10n.searchNearMe,
            subtitle: l10n.areaMyLocationSubtitle,
            onTap: onMyLocation,
          ),
        if (recent.isNotEmpty) ...[
          const Divider(height: 20, indent: 16, endIndent: 16),
          AppSearchSectionHeader(title: l10n.areaRecentTitle),
          for (final area in recent)
            AreaSearchTile(
              area: area,
              onTap: () => onPick(area),
              onRemove: () => onRemove(area),
            ),
        ],
      ],
    );
  }
}
