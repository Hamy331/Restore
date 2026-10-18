import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
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
    final originalPrice = listing.originalPrice;
    final discount = listing.discountPercent;
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
                        if (discount != null)
                          _Tag(
                            label: '-$discount%',
                            color: AppColors.error,
                            textColor: Colors.white,
                          ),
                        if (item.isFeatured)
                          _Tag(
                            label: l10n.homeFeaturedTag,
                            color: AppColors.primary,
                          ),
                        if (listing.allowExchange)
                          _Tag(label: l10n.homeExchangeTag),
                      ],
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
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                          // Giá bán hiện đủ (tối đa 85% bề ngang), giá gốc
                          // lấy phần còn lại
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.85,
                            ),
                            child: Text(
                              price == null
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
                                color: discount == null
                                    ? AppColors.primaryDark
                                    : AppColors.error,
                              ),
                            ),
                          ),
                          // Giá gốc gạch ngang khi tin đang giảm giá; thẻ
                          // hẹp không đủ chỗ thì mờ dần ở cuối
                          if (discount != null && originalPrice != null) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                CurrencyFormatter.formatVnd(
                                  originalPrice,
                                  locale: locale,
                                ),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.textSecondary,
                                ),
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
                        // Trang theo vị trí ưu tiên khoảng cách + khu vực,
                        // bỏ thời gian đăng cho khỏi bị cắt chữ
                        if (createdAt != null && distanceKm == null) ...[
                          const SizedBox(width: 6),
                          Text(
                            TimeAgoFormatter.format(createdAt, l10n),
                            maxLines: 1,
                            style: _metaStyle,
                          ),
                        ],
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

  /// Nền nhãn, mặc định trắng mờ
  final Color? color;
  final Color textColor;

  const _Tag({
    required this.label,
    this.color,
    this.textColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color ?? Colors.white.withValues(alpha: 0.88),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
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
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
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
                active ? AppIcons.favoriteActive : AppIcons.favorite,
                key: ValueKey(active),
                size: 16,
                color: active ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
