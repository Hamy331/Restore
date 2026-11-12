import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';

import 'following_palette.dart';

/// Banner mời theo dõi shop khi chưa theo dõi shop nào: lời mời bên trái,
/// logo vài shop gợi ý xoè ra bên phải, ba điều trang làm được ở dưới
class FollowingOnboardingHero extends StatelessWidget {
  const FollowingOnboardingHero({super.key, required this.suggestions});

  final List<ShopSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final logos = suggestions.take(3).toList();
    final benefits = [
      (AppIcons.sparkle, l.followingHubBenefitFeed),
      (AppIcons.filter, l.followingHubBenefitFilter),
      (AppIcons.verified, l.followingHubBenefitVerified),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1F5), Color(0xFFFDE3EB), Color(0xFFFFEEDB)],
          ),
        ),
        child: Stack(
          children: [
            // Vòng tròn trang trí phía sau logo
            Positioned(
              right: -36,
              top: -30,
              child: _Ring(size: 170, alpha: 0.10),
            ),
            Positioned(right: 40, top: 70, child: _Ring(size: 70, alpha: 0.08)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
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
                            Text(
                              l.followingHubOnboardTitle,
                              style: const TextStyle(
                                fontSize: 19,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.followingHubOnboardBody,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (logos.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _LogoFan(suggestions: logos),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (icon, text) in benefits)
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 13,
                                color: FollowingPalette.accent,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo shop gợi ý xếp chồng, hơi nghiêng như một xấp thẻ
class _LogoFan extends StatelessWidget {
  const _LogoFan({required this.suggestions});

  final List<ShopSuggestion> suggestions;

  static const double _size = 50;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 104,
    height: 92,
    child: Stack(
      children: [
        for (var i = 0; i < suggestions.length; i++)
          Positioned(
            left: [0.0, 46.0, 22.0][i],
            top: [6.0, 0.0, 40.0][i],
            child: Transform.rotate(
              angle: [-0.12, 0.1, -0.02][i],
              child: ShopLogo(shop: suggestions[i].item.shop, size: _size),
            ),
          ),
      ],
    ),
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size, alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: FollowingPalette.accent.withValues(alpha: alpha),
    ),
  );
}
