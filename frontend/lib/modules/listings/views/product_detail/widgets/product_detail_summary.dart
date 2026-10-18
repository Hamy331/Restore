import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/currency_formatter.dart';
import 'package:restore/core/utils/formatters/time_ago_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../models/product_detail.dart';
import 'product_detail_section.dart';

/// Giá, tên sản phẩm, các nhãn (tình trạng, danh mục, nhận đổi) và
/// khu vực / thời gian đăng / lượt xem
class ProductDetailSummary extends StatelessWidget {
  final ProductDetail detail;

  /// Giá trước khi người bán vừa đổi, hiện gạch ngang cạnh giá mới
  final int? previousPrice;

  const ProductDetailSummary({
    super.key,
    required this.detail,
    this.previousPrice,
  });

  static const TextStyle _metaStyle = TextStyle(
    fontSize: 12.5,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final listing = detail.listing;
    final price = listing.price;
    final discount = listing.discountPercent;
    // Giá cũ gạch ngang: giá trước khi vừa đổi, hoặc giá gốc khi đang giảm
    final struckPrice =
        previousPrice ?? (discount == null ? null : listing.originalPrice);
    final createdAt = listing.createdAt;
    final tags = [
      ?listing.condition?.label(l10n),
      ?detail.category?.name.of(context),
      if (price != null && listing.isNegotiable) l10n.negotiable,
      if (listing.allowExchange) l10n.tradeExchangeAccepted,
    ];

    return ProductDetailSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!detail.isAvailable) ...[
            _StatusBanner(
              label: listing.status.label(l10n),
              hint: l10n.productUnavailableHint,
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                price == null
                    ? l10n.homeExchangeOnly
                    : CurrencyFormatter.formatVnd(price, locale: locale),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: discount == null
                      ? AppColors.primaryDark
                      : AppColors.error,
                ),
              ),
              if (struckPrice != null && struckPrice != price)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    CurrencyFormatter.formatVnd(struckPrice, locale: locale),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (discount != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-$discount%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            listing.title,
            style: const TextStyle(
              fontSize: 18,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final tag in tags) _Chip(label: tag)],
            ),
          ],
          if (listing.allowExchange && detail.exchangeWish != null) ...[
            const SizedBox(height: 12),
            _ExchangeWish(wish: detail.exchangeWish!),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          if (detail.areaLabel.isNotEmpty) ...[
            _Meta(icon: AppIcons.location, text: detail.areaLabel),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (createdAt != null)
                _Meta(
                  icon: AppIcons.clock,
                  text: TimeAgoFormatter.format(createdAt, l10n),
                ),
              _Meta(
                icon: AppIcons.visible,
                text: l10n.productViewCount(listing.viewCount),
              ),
              if (detail.isAvailable)
                _LiveBadge(label: l10n.productLiveIndicator),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Flexible(child: Text(text, style: ProductDetailSummary._metaStyle)),
      ],
    );
  }
}

/// Chấm xanh: trang đang tự cập nhật trạng thái tin
class _LiveBadge extends StatelessWidget {
  final String label;

  const _LiveBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 15,
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: ProductDetailSummary._metaStyle),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ExchangeWish extends StatelessWidget {
  final String wish;

  const _ExchangeWish({required this.wish});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.swap, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${l10n.exchangeWishLabel}: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: wish),
                ],
              ),
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String label;
  final String hint;

  const _StatusBanner({required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.info, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label · $hint',
              style: const TextStyle(fontSize: 13, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
