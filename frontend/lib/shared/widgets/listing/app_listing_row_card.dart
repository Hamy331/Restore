import 'listing_seller_summary.dart';
import 'listing_image_overlay.dart';
import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_local_image.dart';
import 'package:restore/shared/widgets/listing/listing_partner_badge.dart';

/// Thẻ tin dạng hàng ngang (trang danh mục, kết quả tìm kiếm): ảnh vuông bên
/// trái kèm nhãn "Tin ưu tiên" và số ảnh; bên phải là tên, tình trạng, giá
/// đỏ, khu vực, thời gian đăng và nút lưu tin. Dùng chung cho điện thoại và
/// web desktop ([imageSize] lớn hơn trên desktop).
class AppListingRowCard extends StatelessWidget {
  const AppListingRowCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFavoriteTap,
    this.imageSize = 120,
  });

  final ListingCardItem item;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final listing = item.listing;
    final cover = listing.coverImage;
    final price = listing.price;
    final createdAt = listing.createdAt;
    final details = listing.condition?.shortLabel(l10n) ?? '';
    final big = imageSize >= 150;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: imageSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: AppColors.cream,
                      child: cover == null
                          ? const Icon(
                              AppIcons.image,
                              color: AppColors.primaryDark,
                            )
                          : AppLocalImage(
                              path: cover,
                              cacheWidth: (imageSize * 2).round(),
                            ),
                    ),
                    if (createdAt != null)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: ListingImageOverlay(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                            child: Text(
                              TimeAgoFormatter.format(createdAt, l10n),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: ListingImageOverlay(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(AppIcons.image, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                '${listing.images.length}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (item.isFeatured)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: ListingImageOverlay(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              vi ? 'Tin ưu tiên' : 'Featured',
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: ListingImageOverlay(
                        child: IconButton(
                          tooltip: item.isFavorite
                              ? l10n.homeUnsaveListing
                              : l10n.homeSaveListing,
                          onPressed: onFavoriteTap,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            item.isFavorite
                                ? AppIcons.savedListing
                                : AppIcons.favorite,
                            size: 22,
                            color: item.isFavorite
                                ? AppColors.error
                                : Colors.white,
                            shadows: ListingImageOverlay.shadows,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: imageSize.clamp(150, double.infinity).toDouble(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListingCardTitle(
                      title: listing.title,
                      isPartner: listing.isPartner,
                      style: TextStyle(
                        fontSize: big ? 16 : 14.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          listing.isFree
                              ? l10n.priceFree
                              : price == null
                              ? l10n.homeExchangeOnly
                              : CurrencyFormatter.formatVnd(
                                  price,
                                  locale: locale,
                                ),
                          style: TextStyle(
                            fontSize: big ? 18 : 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                        if (details.isNotEmpty)
                          Text(
                            '· $details',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    ListingSellerSummary(listing: listing),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          AppIcons.location,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (item.areaLabel.isNotEmpty) item.areaLabel,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
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
    );
  }
}
