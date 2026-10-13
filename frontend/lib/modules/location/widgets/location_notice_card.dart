import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import '../bloc/address_picker/address_picker_state.dart';

/// Thẻ thông báo nhẹ nhàng khi định vị xong nhưng không ra được địa chỉ:
/// đang ở nước ngoài, hoặc ở Việt Nam mà chưa khớp được phường/xã.
class LocationNoticeCard extends StatelessWidget {
  final LocationNotice notice;
  final VoidCallback onDismiss;

  const LocationNoticeCard({
    super.key,
    required this.notice,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, title, body) = switch (notice) {
      LocationNotice.outsideVietnam => (
        AppIcons.globe,
        l10n.locationOutsideVietnamTitle,
        l10n.locationOutsideVietnamBody,
      ),
      LocationNotice.outOfCoverage => (
        AppIcons.locationUnknown,
        l10n.locationOutOfCoverageTitle,
        l10n.locationOutOfCoverage,
      ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFEFF5FF).withValues(alpha: 0.9),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.info.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, size: 20, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              AppIcons.close,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
