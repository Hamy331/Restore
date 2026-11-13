import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_follow_button.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_verification_badge.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import 'following_palette.dart';

/// Thẻ gợi ý theo dõi: shop, lý do gợi ý, 3 tin mới nhất và nút theo dõi
class ShopSuggestionCard extends StatelessWidget {
  const ShopSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTap,
    required this.onFollowTap,
    required this.onListingTap,
    this.width,
  });

  final ShopSuggestion suggestion;
  final VoidCallback onTap, onFollowTap;
  final ValueChanged<ListingCardItem> onListingTap;

  /// Đặt khi nằm trong hàng cuộn ngang
  final double? width;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final model = suggestion.item.shop;
    final type = model.verificationType;
    final accent = ShopLogo.accentOf(model);
    // Khẩu hiệu của shop, chưa có thì số người theo dõi
    final subtitle = model.tagline.isNotEmpty
        ? model.tagline
        : l.followShopsFollowerCountText(
            NumberFormat.decimalPattern(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(model.followerCount),
          );
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: suggestion.item.isFollowing
                ? FollowingPalette.accent.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Đối tác: nhãn nhỏ đè mép dưới logo
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        ShopLogo(shop: model, size: 46),
                        if (suggestion.isPartner)
                          const Positioned(bottom: -8, child: _PartnerTag()),
                      ],
                    ),
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
                                ShopVerificationBadge(
                                  type: type,
                                  iconOnly: true,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShopFollowButton(
                      following: suggestion.item.isFollowing,
                      accent: accent,
                      onTap: onFollowTap,
                    ),
                  ],
                ),
                if (suggestion.previews.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: i < suggestion.previews.length
                              ? _Preview(
                                  item: suggestion.previews[i],
                                  onTap: () =>
                                      onListingTap(suggestion.previews[i]),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhỏ "Đối tác" cạnh tên shop
class _PartnerTag extends StatelessWidget {
  const _PartnerTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE0A33A), Color(0xFFC77D1A)],
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      AppLocalizations.of(context)!.followingHubPartner,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: Colors.white,
      ),
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.item, required this.onTap});

  final ListingCardItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final cover = item.listing.coverImage;
    final price = item.listing.price;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover != null)
                AppLocalImage(path: cover, cacheWidth: 300)
              else
                const ColoredBox(color: AppColors.cream),
              Positioned(
                left: 6,
                bottom: 6,
                right: 6,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      price == null
                          ? l.homeExchangeOnly
                          : CurrencyFormatter.formatCompact(
                              price,
                              l,
                              locale: locale,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
