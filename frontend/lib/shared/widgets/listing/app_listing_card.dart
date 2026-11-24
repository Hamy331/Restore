import 'listing_image_overlay.dart';
import 'package:flutter/material.dart';
import 'package:restore/shared/widgets/listing/listing_partner_badge.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/distance_formatter.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// Thẻ tin đăng tối giản dùng chung cho mọi danh sách tin: ảnh vuông, nhãn
/// nổi bật/đổi được, nút lưu tin, tên, giá và khu vực + thời gian đăng.
/// Bật [showDistance] ở các trang theo vị trí để hiện khoảng cách thay cho
/// thời gian đăng.
class AppListingCard extends StatelessWidget {
  final ListingCardItem item;
  final VoidCallback? onTap;
  final VoidCallback onFavoriteTap;

  /// Hiện khoảng cách (VD "1,2 km · Quận 3") trước khu vực khi đã biết,
  /// thay cho thời gian đăng
  final bool showDistance;

  const AppListingCard({
    super.key,
    required this.item,
    required this.onFavoriteTap,
    this.onTap,
    this.showDistance = false,
  });

  static const double _infoHeight = 98;
  static const double _radius = 16;

  static const TextStyle _metaStyle = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  /// Chiều cao thẻ theo chiều rộng (ảnh vuông + phần chữ cố định)
  static double heightFor(double width) => width + _infoHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listing = item.listing;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final price = listing.price;
    final createdAt = listing.createdAt;
    final distanceKm = showDistance ? item.distanceKm : null;
    final area = distanceKm == null
        ? item.areaLabel
        : [
            DistanceFormatter.format(distanceKm, l10n, locale: locale),
            if (item.areaLabel.isNotEmpty) item.areaLabel,
          ].join(' · ');

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.cream,
                    child: listing.coverImage == null
                        ? const Icon(
                            AppIcons.image,
                            size: 32,
                            color: AppColors.primaryDark,
                          )
                        : AppLocalImage(
                            path: listing.coverImage!,
                            cacheWidth: 480,
                          ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        if (createdAt != null)
                          _Tag(label: TimeAgoFormatter.format(createdAt, l10n)),
                        if (item.isFeatured)
                          _HotBadge(label: l10n.homeFeaturedTag),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _Tag(
                      label: '${listing.images.length}',
                      icon: AppIcons.image,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: _FavoriteButton(
                      active: item.isFavorite,
                      tooltip: item.isFavorite
                          ? l10n.homeUnsaveListing
                          : l10n.homeSaveListing,
                      onTap: onFavoriteTap,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListingCardTitle(
                      title: listing.title,
                      isPartner: listing.isPartner,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    LayoutBuilder(
                      builder: (context, constraints) => Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  constraints.maxWidth *
                                  (listing.condition == null ? 0.85 : 0.62),
                            ),
                            child: Text(
                              listing.isFree
                                  ? l10n.priceFree
                                  : price == null
                                  ? l10n.homeExchangeOnly
                                  : CurrencyFormatter.formatVnd(
                                      price,
                                      locale: locale,
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          if (listing.condition != null) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '· ${listing.condition!.shortLabel(l10n)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _metaStyle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (distanceKm != null) ...[
                          const Icon(
                            AppIcons.location,
                            size: 12,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Expanded(
                          child: Text(
                            area,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _metaStyle,
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

class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _Tag({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return ListingImageOverlay(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn tin Hot sale: nguyên cụm icon (ngọn lửa + chữ HOT SALE)
class _HotBadge extends StatelessWidget {
  const _HotBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Image.asset(
      AppImages.coreImages.hotSale,
      height: 26,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          const Icon(AppIcons.hot, size: 16, color: AppColors.error),
    ),
  );
}

class _FavoriteButton extends StatelessWidget {
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ListingImageOverlay(
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                active ? AppIcons.savedListing : AppIcons.favorite,
                key: ValueKey(active),
                size: 16,
                color: active ? AppColors.error : Colors.white,
                shadows: ListingImageOverlay.shadows,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
