import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/shared/widgets/app_image_icon.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/home_quick_action.dart';

/// 4 lối tắt dạng lưới 2 × 2 ngay dưới hàng danh mục.
/// Mỗi ô có màu riêng và icon 3D (AppImages.uiIcons) để dễ phân biệt.
class HomeQuickActions extends StatelessWidget {
  final ValueChanged<HomeQuickAction> onTap;

  const HomeQuickActions({super.key, required this.onTap});

  static _QuickActionStyle _styleOf(
    HomeQuickAction action,
    AppLocalizations l10n,
  ) => switch (action) {
    HomeQuickAction.nearby => _QuickActionStyle(
      icon: AppIcons.nearby,
      image: AppImages.uiIcons.nearby,
      title: l10n.homeQuickNearby,
      description: l10n.homeQuickNearbyDesc,
      accent: const Color(0xFF0E7C70),
      tint: const Color(0xFFE5F5F2),
    ),
    HomeQuickAction.wantedAlert => _QuickActionStyle(
      icon: AppIcons.wantedAlert,
      image: AppImages.uiIcons.wantedAlert,
      title: l10n.homeQuickWanted,
      description: l10n.homeQuickWantedDesc,
      accent: AppColors.primaryDark,
      tint: AppColors.primarySoft,
    ),
    HomeQuickAction.trustedShops => _QuickActionStyle(
      icon: AppIcons.verified,
      image: AppImages.uiIcons.trustedShop,
      title: l10n.homeQuickTrustedShops,
      description: l10n.homeQuickTrustedShopsDesc,
      accent: const Color(0xFF2B63C6),
      tint: const Color(0xFFEAF1FD),
    ),
    HomeQuickAction.following => _QuickActionStyle(
      icon: AppIcons.following,
      image: AppImages.uiIcons.following,
      title: l10n.homeQuickFollowing,
      description: l10n.homeQuickFollowingDesc,
      accent: const Color(0xFFC23A62),
      tint: const Color(0xFFFDECF1),
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
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tile(actions[row]),
                  const SizedBox(width: 10),
                  tile(actions[row + 1]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActionStyle {
  final IconData icon;
  final String image;
  final String title;
  final String description;
  final Color accent;
  final Color tint;

  const _QuickActionStyle({
    required this.icon,
    required this.image,
    required this.title,
    required this.description,
    required this.accent,
    required this.tint,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gạch màu ngắn trên tên, nhận diện từng ô
                            Container(
                              width: 16,
                              height: 3,
                              decoration: BoxDecoration(
                                color: style.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              style.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      AppImageIcon(
                        style.image,
                        size: 30,
                        fallback: style.icon,
                        fallbackColor: style.accent.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    style.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: AppColors.textSecondary,
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
