import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/animations/app_animation_durations.dart';
import 'package:restore/data/models/enums/shop_verification_type.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

import '../../../models/trusted_shop_item.dart';
import '../../../widgets/shop_follow_button.dart';
import '../../../widgets/shop_logo.dart';
import '../../../widgets/shop_palette.dart';
import '../../../widgets/shop_stats_row.dart';
import '../../../widgets/shop_verification_badge.dart';

/// Hồ sơ shop đầu trang (nhuốm màu shop): ảnh bìa, logo, nút theo dõi, tên + nhãn xác minh,
/// giới thiệu, số liệu, thẻ chứng nhận và phần mô tả thu gọn được
class ShopDetailProfile extends StatelessWidget {
  final TrustedShopItem item;
  final VoidCallback onFollowTap;
  final VoidCallback onCertificateTap;

  const ShopDetailProfile({
    super.key,
    required this.item,
    required this.onFollowTap,
    required this.onCertificateTap,
  });

  static const double _coverHeight = 120;
  static const double _logoSize = 76;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = item.shop;
    final accent = ShopLogo.accentOf(shop);
    final type = shop.verificationType;
    final coverUrl = shop.coverUrl;
    final address = shop.address;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _coverHeight + _logoSize / 2,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    height: _coverHeight,
                    width: double.infinity,
                    child: coverUrl != null
                        ? AppLocalImage(path: coverUrl, cacheWidth: 1000)
                        : _CoverPattern(
                            accent: accent,
                            icon: ShopVerificationStyle.of(type).icon,
                          ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 0,
                  child: ShopLogo(shop: shop, size: _logoSize),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: ShopFollowButton(
                    following: item.isFollowing,
                    accent: accent,
                    large: true,
                    onTap: onFollowTap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            shop.name,
            style: const TextStyle(
              fontSize: 21,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (type != null) ShopVerificationBadge(type: type),
              if (address != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.location,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (shop.tagline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              shop.tagline,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _ShopStats(item: item),
          const SizedBox(height: 12),
          if (type != null) ...[
            _CertificateTile(item: item, onTap: onCertificateTap),
            const SizedBox(height: 12),
          ],
          if (shop.description.isNotEmpty)
            _ExpandableDescription(
              text: shop.description,
              accent: accent,
              moreLabel: l10n.shopDescriptionMore,
              lessLabel: l10n.shopDescriptionLess,
            ),
        ],
      ),
    );
  }
}

/// Nền bìa mặc định: gradient màu nhận diện, vệt sáng và dấu xác minh mờ
class _CoverPattern extends StatelessWidget {
  final Color accent;
  final IconData icon;

  const _CoverPattern({required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.white, 0.35)!,
            accent,
            Color.lerp(accent, Colors.black, 0.18)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -26,
            child: Icon(
              icon,
              size: 150,
              color: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ba ô số liệu: đánh giá, người theo dõi, sản phẩm đang bán
class _ShopStats extends StatelessWidget {
  final TrustedShopItem item;

  const _ShopStats({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shop = item.shop;

    Widget cell(String value, String label, {IconData? icon}) => Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    Widget divider() =>
        Container(width: 1, height: 28, color: AppColors.border);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: ShopPalette.of(shop).soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          cell(
            ShopStatsRow.formatRating(shop.ratingAverage, locale),
            l10n.shopRatingCount(
              NumberFormat.decimalPattern(locale).format(shop.ratingCount),
            ),
            icon: AppIcons.star,
          ),
          divider(),
          cell(
            ShopStatsRow.formatCount(shop.followerCount, locale),
            l10n.shopFollowersLabel,
          ),
          divider(),
          cell(
            ShopStatsRow.formatCount(shop.listingCount, locale),
            l10n.shopProductsLabel,
          ),
        ],
      ),
    );
  }
}

/// Thẻ chứng nhận nhỏ: kiểu xác minh, mã và thời điểm xác minh; bấm để xem
/// giải thích đầy đủ
class _CertificateTile extends StatelessWidget {
  final TrustedShopItem item;
  final VoidCallback onTap;

  const _CertificateTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shop = item.shop;
    final type = shop.verificationType!;
    final style = ShopVerificationStyle.of(type);
    final verifiedAt = shop.verifiedAt;
    final details = [
      ?shop.certificateCode,
      if (verifiedAt != null)
        l10n.shopVerifiedSinceShort(
          DateFormat.yM(locale).format(verifiedAt.toLocal()),
        ),
    ].join(' · ');

    return Material(
      color: style.tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: style.accent.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, size: 19, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == ShopVerificationType.officialBrand
                          ? l10n.trustedShopsOfficialTitle
                          : l10n.trustedShopsCertifiedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: style.accent),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(AppIcons.chevronRight, size: 18, color: style.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mô tả shop: mặc định 3 dòng, bấm "Xem thêm" để mở hết
class _ExpandableDescription extends StatefulWidget {
  final String text;
  final Color accent;
  final String moreLabel;
  final String lessLabel;

  const _ExpandableDescription({
    required this.text,
    required this.accent,
    required this.moreLabel,
    required this.lessLabel,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const int _collapsedLines = 3;
  static const TextStyle _style = TextStyle(
    fontSize: 13.5,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Chỉ hiện nút khi chữ thật sự dài hơn số dòng thu gọn
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: _style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: AppAnimationDurations.fast,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                maxLines: _expanded ? null : _collapsedLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: _style,
              ),
            ),
            if (overflows)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _expanded ? widget.lessLabel : widget.moreLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.accent,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
