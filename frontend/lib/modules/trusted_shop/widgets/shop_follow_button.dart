import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Nút theo dõi shop dạng viên thuốc: chưa theo dõi thì nền [accent] chữ
/// trắng, đang theo dõi thì nền trắng viền mảnh kèm dấu tích.
class ShopFollowButton extends StatelessWidget {
  final bool following;
  final Color accent;
  final VoidCallback onTap;

  /// Cao 32 cho thẻ shop, 40 cho trang của shop
  final bool large;

  const ShopFollowButton({
    super.key,
    required this.following,
    required this.accent,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final foreground = following ? AppColors.textPrimary : Colors.white;
    return Semantics(
      button: true,
      toggled: following,
      child: AnimatedContainer(
        duration: AppAnimationDurations.fast,
        curve: AppAnimationDurations.enterCurve,
        height: large ? 40 : 32,
        decoration: ShapeDecoration(
          color: following ? AppColors.surface : accent,
          shape: StadiumBorder(
            side: BorderSide(color: following ? AppColors.border : accent),
          ),
          shadows: following
              ? null
              : [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    spreadRadius: -3,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: large ? 16 : 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    following ? AppIcons.check : AppIcons.add,
                    size: large ? 16 : 14,
                    color: foreground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    following ? l10n.shopFollowing : l10n.shopFollow,
                    style: TextStyle(
                      fontSize: large ? 14 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
