import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../../../models/shop_product_item.dart';
import '../../../widgets/shop_logo.dart';
import '../../../widgets/shop_verification_badge.dart';
import '../../../widgets/trusted_shop_section_header.dart';

/// Khu "Siêu phẩm mới ra mắt": tiêu đề và hàng thẻ lớn cuộn ngang, mỗi thẻ
/// có ảnh to, nhãn "Mới ra mắt", logo + tên thương hiệu, giá và ngày ra mắt
class TrustedNewReleases extends StatelessWidget {
  final List<ShopProductItem> products;
  final ValueChanged<ShopProductItem> onProductTap;
  final ValueChanged<ShopProductItem> onFavoriteTap;

  const TrustedNewReleases({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.onFavoriteTap,
  });

  static const Color accent = Color(0xFFE8590C);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrustedShopSectionHeader(
          title: l10n.trustedShopsNewReleasesTitle,
          subtitle: l10n.trustedShopsNewReleasesSubtitle,
          icon: AppIcons.hot,
          iconColor: accent,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _NewReleaseCard.height + 6,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final product = products[index];
              return Align(
                alignment: Alignment.topCenter,
                child: _NewReleaseCard(
                  product: product,
                  onTap: () => onProductTap(product),
                  onFavoriteTap: () => onFavoriteTap(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NewReleaseCard extends StatelessWidget {
  final ShopProductItem product;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _NewReleaseCard({
    required this.product,
    required this.onTap,
    required this.onFavoriteTap,
  });

  static const double width = 248;
  static const double height = 300;
  static const double _imageHeight = 176;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final item = product.item;
    final listing = item.listing;
    final shop = product.shop;
    final accent = ShopLogo.accentOf(shop);
    final price = listing.price;
    final cover = listing.coverImage;
    final createdAt = listing.createdAt;
    final type = shop.verificationType;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Nền nhuốm màu thương hiệu phía sau ảnh sản phẩm
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.9,
                          colors: [
                            Color.lerp(accent, Colors.white, 0.85)!,
                            Color.lerp(accent, Colors.white, 0.6)!,
                          ],
                        ),
                      ),
                    ),
                    if (cover != null)
                      AppLocalImage(path: cover, cacheWidth: 600),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A3D), Color(0xFFE8590C)],
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.hot,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.trustedShopsNewReleaseTag,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Tooltip(
                        message: item.isFavorite
                            ? l10n.homeUnsaveListing
                            : l10n.homeSaveListing,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: onFavoriteTap,
                            customBorder: const CircleBorder(),
                            child: SizedBox.square(
                              dimension: 32,
                              child: Icon(
                                item.isFavorite
                                    ? AppIcons.favoriteActive
                                    : AppIcons.favorite,
                                size: 17,
                                color: item.isFavorite
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShopLogo(shop: shop, size: 22),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          if (type != null) ...[
                            const SizedBox(width: 3),
                            ShopVerificationBadge(type: type, iconOnly: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              price == null
                                  ? l10n.homeExchangeOnly
                                  : CurrencyFormatter.formatVnd(
                                      price,
                                      locale: locale,
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              l10n.trustedShopsLaunchedDaysAgo(
                                DateTime.now().difference(createdAt).inDays,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
