import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_search_pill.dart';

/// Ô địa điểm của trang Gần bạn: hiện khu vực đang xem, chạm để đổi địa điểm
class NearbySearchBar extends StatelessWidget {
  /// Tên khu vực; null khi đang xác định vị trí
  final String? locationLabel;
  final VoidCallback onTap;

  const NearbySearchBar({
    super.key,
    required this.locationLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = locationLabel;
    return AppSearchPill(
      icon: AppIcons.location,
      text: label ?? l10n.nearbyLocating,
      isPlaceholder: label == null,
      onTap: onTap,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: const ShapeDecoration(
          color: AppColors.primarySoft,
          shape: StadiumBorder(),
        ),
        child: Text(
          l10n.nearbyChangeLocation,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
