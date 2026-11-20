import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_verification_badge.dart';

/// Dải ngang "Cửa hàng phù hợp" đầu tab Tin đăng: thẻ nhỏ mỗi shop khớp từ
/// khoá, "Xem tất cả" chuyển sang tab Cửa hàng
class SearchResultsShopStrip extends StatelessWidget {
  final List<TrustedShopItem> shops;
  final ValueChanged<TrustedShopItem> onOpen;
  final VoidCallback onSeeAll;

  static const double _cardWidth = 148;
  static const double _cardHeight = 150;

  const SearchResultsShopStrip({
    super.key,
    required this.shops,
    required this.onOpen,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.searchShopStripTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.homeSeeAll),
              ),
            ],
          ),
        ),
        SizedBox(
          height: _cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, index) => _ShopCard(
              item: shops[index],
              onTap: () => onOpen(shops[index]),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  final TrustedShopItem item;
  final VoidCallback onTap;

  const _ShopCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = item.shop;
    final type = shop.verificationType;
    final accent = ShopLogo.accentOf(shop);
    final radius = BorderRadius.circular(18);

    return SizedBox(
      width: SearchResultsShopStrip._cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent.withValues(alpha: 0.10), AppColors.surface],
              ),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShopLogo(shop: shop, size: 48),
                  const Spacer(),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          shop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
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
                    l10n.followShopsFollowerCount(shop.followerCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
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
