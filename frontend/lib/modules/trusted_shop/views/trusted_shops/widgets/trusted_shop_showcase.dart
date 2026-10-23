import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';

import '../../../models/trusted_shops_overview.dart';
import '../../../widgets/shop_logo.dart';
import '../../../widgets/shop_stats_row.dart';
import '../../../widgets/shop_verification_badge.dart';

/// Khối sản phẩm của một shop: nền nhạt theo màu nhận diện, đầu khối có logo,
/// tên, số liệu và nút "Xem shop", bên dưới là hàng thẻ tin cuộn ngang
class TrustedShopShowcaseBlock extends StatelessWidget {
  final ShopShowcase showcase;
  final VoidCallback onShopTap;
  final ValueChanged<ListingCardItem> onListingTap;
  final ValueChanged<ListingCardItem> onFavoriteTap;

  const TrustedShopShowcaseBlock({
    super.key,
    required this.showcase,
    required this.onShopTap,
    required this.onListingTap,
    required this.onFavoriteTap,
  });

  static const double _cardWidth = 150;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = showcase.shop.shop;
    final accent = ShopLogo.accentOf(shop);
    final type = shop.verificationType;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(accent, Colors.white, 0.88)!,
              Color.lerp(accent, Colors.white, 0.96)!,
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onShopTap,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 6, 10),
                child: Row(
                  children: [
                    ShopLogo(shop: shop, size: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  shop.name,
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
                                ShopVerificationBadge(
                                  type: type,
                                  iconOnly: true,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          ShopStatsRow(shop: shop, showFollowers: false),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onShopTap,
                      style: TextButton.styleFrom(
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.trustedShopsViewShop,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(AppIcons.chevronRight, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: AppListingCard.heightFor(_cardWidth),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: showcase.listings.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final item = showcase.listings[index];
                  return SizedBox(
                    width: _cardWidth,
                    child: AppListingCard(
                      item: item,
                      onTap: () => onListingTap(item),
                      onFavoriteTap: () => onFavoriteTap(item),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
