import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/data/models/listing_model.dart';
import 'package:restore/modules/account/widgets/profile_header.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/views/shop_detail/shop_detail_view.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_verification_badge.dart';
import 'listing_partner_badge.dart';

/// Thông tin người bán trên thẻ dạng danh sách.
class ListingSellerSummary extends StatelessWidget {
  const ListingSellerSummary({super.key, required this.listing});
  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = listing.shopSummary;
    final name = shop?.name ?? listing.sellerName.trim();
    final rating = shop == null
        ? listing.sellerRating
        : (shop.ratingCount > 0 ? shop.ratingAverage : null);
    final sold = shop?.soldCount ?? listing.sellerSoldCount;
    return InkWell(
      onTap: () => context.push(
        shop == null
            ? '/users/${listing.ownerId}'
            : ShopDetailView.location(shop.id),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shop != null)
                ShopLogo(shop: shop, size: 22)
              else
                ProfileAvatar(
                  radius: 11,
                  url: listing.sellerAvatarUrl,
                  initials: name.characters.take(1).toString().toUpperCase(),
                ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  name.isEmpty ? l10n.sellerTitle : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (shop != null) ...[
                const SizedBox(width: 4),
                if (shop.verificationType case final type?)
                  ShopVerificationBadge(type: type, iconOnly: true)
                else
                  const ListingPartnerBadge(),
              ],
            ],
          );
          final stats = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rating?.toStringAsFixed(1) ?? '—',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${sold ?? '—'} ${l10n.sellerSold}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          );
          if (constraints.maxWidth < 400) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 2), stats],
            );
          }
          return Row(
            children: [
              Flexible(child: identity),
              const SizedBox(width: 14),
              stats,
            ],
          );
        },
      ),
    );
  }
}
