import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/services/device_location_service.dart';

/// Thẻ nhắc khi chưa dùng được GPS: đang xem quanh khu vực mặc định, kèm lý
/// do và nút bật vị trí (hoặc mở Cài đặt khi quyền đã bị chặn).
class NearbyLocationNotice extends StatelessWidget {
  final DeviceLocationError error;
  final VoidCallback onUseLocation;
  final VoidCallback onOpenSettings;

  const NearbyLocationNotice({
    super.key,
    required this.error,
    required this.onUseLocation,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocked = error == DeviceLocationError.permissionDeniedForever;
    final message = switch (error) {
      DeviceLocationError.serviceDisabled => l10n.locationServiceDisabled,
      DeviceLocationError.permissionDenied => l10n.locationPermissionDenied,
      DeviceLocationError.permissionDeniedForever =>
        l10n.locationPermissionDeniedForever,
      DeviceLocationError.unavailable => l10n.locationUnavailable,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  AppIcons.locationUnknown,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nearbyFallbackTitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: blocked ? onOpenSettings : onUseLocation,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(
                blocked ? l10n.nearbyOpenSettings : l10n.nearbyUseMyLocation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
