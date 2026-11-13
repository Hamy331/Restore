import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/modules/trusted_shop/widgets/followed_shop_tile.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_verification_badge.dart';

/// Đang lọc một shop: thẻ nhỏ giới thiệu shop và nút mở trang shop
class FollowingSelectedShop extends StatelessWidget {
  const FollowingSelectedShop({
    super.key,
    required this.shop,
    required this.onOpen,
  });

  final FollowedShop shop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final model = shop.item.shop;
    final type = model.verificationType;
    final accent = ShopLogo.accentOf(model);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ShopLogo(shop: model, size: 48),
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
                          fontWeight: FontWeight.w800,
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
                const SizedBox(height: 3),
                Text(
                  l.followShopsFollowerCountText(
                    NumberFormat.decimalPattern(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(model.followerCount),
                  ),
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
          const SizedBox(width: 8),
          OutlinedButton(
            key: const ValueKey('following-open-shop'),
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              foregroundColor: Color.lerp(accent, Colors.black, 0.2),
              side: BorderSide(color: accent.withValues(alpha: 0.5)),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(l.followingHubOpenShop),
          ),
        ],
      ),
    );
  }
}
