import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/home_quick_action.dart';

/// 4 lối tắt dạng lưới 2 × 2 ngay dưới hàng danh mục.
/// Mỗi ô có màu và kiểu khung icon riêng để dễ phân biệt.
class HomeQuickActions extends StatelessWidget {
  final ValueChanged<HomeQuickAction> onTap;

  const HomeQuickActions({super.key, required this.onTap});

  static _QuickActionStyle _styleOf(
    HomeQuickAction action,
    AppLocalizations l10n,
  ) => switch (action) {
    HomeQuickAction.nearby => _QuickActionStyle(
      icon: AppIcons.nearby,
      title: l10n.homeQuickNearby,
      description: l10n.homeQuickNearbyDesc,
      accent: const Color(0xFF0E7C70),
      tint: const Color(0xFFE5F5F2),
      iconShape: const CircleBorder(),
    ),
    HomeQuickAction.wantedAlert => _QuickActionStyle(
      icon: AppIcons.wantedAlert,
      title: l10n.homeQuickWanted,
      description: l10n.homeQuickWantedDesc,
      accent: AppColors.primaryDark,
      tint: AppColors.primarySoft,
      iconShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    HomeQuickAction.trustedShops => _QuickActionStyle(
      icon: AppIcons.verified,
      title: l10n.homeQuickTrustedShops,
      description: l10n.homeQuickTrustedShopsDesc,
      accent: const Color(0xFF2B63C6),
      tint: const Color(0xFFEAF1FD),
      iconShape: const StarBorder.polygon(sides: 6, pointRounding: 0.45),
    ),
    HomeQuickAction.following => _QuickActionStyle(
      icon: AppIcons.following,
      title: l10n.homeQuickFollowing,
      description: l10n.homeQuickFollowingDesc,
      accent: const Color(0xFFC23A62),
      tint: const Color(0xFFFDECF1),
      iconShape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const actions = HomeQuickAction.values;
    Widget tile(HomeQuickAction action) => Expanded(
      child: _QuickActionTile(
        style: _styleOf(action, l10n),
        onTap: () => onTap(action),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var row = 0; row < actions.length; row += 2) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(
              children: [
                tile(actions[row]),
                const SizedBox(width: 10),
                tile(actions[row + 1]),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionStyle {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Color tint;
  final ShapeBorder iconShape;

  const _QuickActionStyle({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.tint,
    required this.iconShape,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickActionStyle style;
  final VoidCallback onTap;

  const _QuickActionTile({required this.style, required this.onTap});

  static const _radius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${style.title}. ${style.description}',
      excludeSemantics: true,
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: _radius,
          side: BorderSide(color: style.accent.withValues(alpha: 0.14)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [style.tint, Color.lerp(style.tint, Colors.white, 0.6)!],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: style.accent.withValues(alpha: 0.10),
            highlightColor: style.accent.withValues(alpha: 0.05),
            child: Stack(
              children: [
                // Icon lớn mờ ở góc làm hoạ tiết, mỗi ô một hình riêng
                Positioned(
                  right: -8,
                  top: -10,
                  child: Icon(
                    style.icon,
                    size: 64,
                    color: style.accent.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: ShapeDecoration(
                          shape: style.iconShape,
                          color: style.accent,
                          shadows: [
                            BoxShadow(
                              color: style.accent.withValues(alpha: 0.28),
                              blurRadius: 10,
                              spreadRadius: -3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(style.icon, size: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        style.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        style.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
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
      ),
    );
  }
}
