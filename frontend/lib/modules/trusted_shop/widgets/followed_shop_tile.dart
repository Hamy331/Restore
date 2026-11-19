import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../models/followed_shop.dart';
import 'shop_follow_button.dart';
import 'shop_logo.dart';
import 'shop_verification_badge.dart';

/// Một dòng shop đang theo dõi: logo, tên + huy hiệu xác minh, khẩu hiệu,
/// số tin mới trong 7 ngày và nút theo dõi.
class FollowedShopTile extends StatelessWidget {
  const FollowedShopTile({
    super.key,
    required this.shop,
    required this.onTap,
    required this.onFollowTap,
  });

  final FollowedShop shop;
  final VoidCallback onTap;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final model = shop.item.shop;
    final type = model.verificationType;
    final accent = ShopLogo.accentOf(model);
    final subtitle = model.tagline.isNotEmpty
        ? model.tagline
        : l.followShopsFollowerCount(model.followerCount);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            ShopLogo(shop: model, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          model.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (type != null) ...[
                        const SizedBox(width: 4),
                        ShopVerificationBadge(type: type, iconOnly: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (shop.newListingCount > 0) ...[
                    const SizedBox(height: 6),
                    FollowedShopNewChip(
                      count: shop.newListingCount,
                      accent: accent,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            ShopFollowButton(
              following: shop.item.isFollowing,
              accent: accent,
              onTap: onFollowTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Viên nhỏ "N tin mới" theo màu nhận diện của shop
class FollowedShopNewChip extends StatelessWidget {
  const FollowedShopNewChip({
    super.key,
    required this.count,
    required this.accent,
  });

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l.followShopsNewCount(count),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color.lerp(accent, Colors.black, 0.2),
        ),
      ),
    );
  }
}
