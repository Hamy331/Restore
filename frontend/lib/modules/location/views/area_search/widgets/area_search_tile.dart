import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/search/app_search_list_tile.dart';

import '../../../models/area_option.dart';

/// Một khu vực trong danh sách: icon theo cấp, tên và tỉnh/thành chứa nó
class AreaSearchTile extends StatelessWidget {
  final AreaOption area;
  final VoidCallback onTap;
  final String? highlight;
  final VoidCallback? onRemove;

  const AreaSearchTile({
    super.key,
    required this.area,
    required this.onTap,
    this.highlight,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isProvince = area.level == AdministrativeLevel.province;
    return AppSearchListTile(
      icon: isProvince ? AppIcons.province : AppIcons.ward,
      boxed: true,
      title: area.name,
      subtitle: area.parentName ?? l10n.areaWholeProvince,
      highlight: highlight,
      onTap: onTap,
      onRemove: onRemove,
    );
  }
}
