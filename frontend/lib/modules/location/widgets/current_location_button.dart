import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/theme/app_glass.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Nút "Dùng vị trí hiện tại": đang định vị thì hiện vòng xoay, xong thì hiện dấu tích
class CurrentLocationButton extends StatelessWidget {
  final bool isLocating;
  final bool isDetected;
  final VoidCallback onTap;

  const CurrentLocationButton({
    super.key,
    required this.isLocating,
    required this.isDetected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(AppGlass.fieldRadius);

    return Material(
      color: AppGlass.fillStrong,
      borderRadius: radius,
      child: InkWell(
        onTap: isLocating ? null : onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: AppAnimationDurations.fast,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: isDetected ? AppColors.primary : AppGlass.stroke,
              width: isDetected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: AppAnimationDurations.fast,
                  child: isLocating
                      ? const Padding(
                          key: ValueKey('locating'),
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : Icon(
                          isDetected
                              ? AppIcons.checkCircleActive
                              : AppIcons.myLocation,
                          key: ValueKey(isDetected),
                          color: AppColors.primaryDark,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDetected
                          ? l10n.locationDetected
                          : l10n.useCurrentLocation,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLocating
                          ? l10n.locatingLabel
                          : l10n.useCurrentLocationHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
