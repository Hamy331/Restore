import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';

/// Khu "Trải nghiệm hàng hiệu": khối nền cam đỏ ấm, đầu khối có mức giảm
/// cao nhất và nút "Xem tất cả", bên dưới là hàng thẻ tin đang giảm giá
class TrustedDealsSection extends StatelessWidget {
  final List<ListingCardItem> deals;
  final ValueChanged<ListingCardItem> onListingTap;
  final ValueChanged<ListingCardItem> onFavoriteTap;
  final VoidCallback onSeeAll;

  const TrustedDealsSection({
    super.key,
    required this.deals,
    required this.onListingTap,
    required this.onFavoriteTap,
    required this.onSeeAll,
  });

  static const double _cardWidth = 150;
  static const Color _accent = Color(0xFFD9412E);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxDiscount = deals
        .map((item) => item.listing.discountPercent ?? 0)
        .fold(0, (max, value) => value > max ? value : max);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE3DA), Color(0xFFFFF4EC)],
          ),
          border: Border.all(color: _accent.withValues(alpha: 0.12)),
        ),
        child: Stack(
          children: [
            // Hoạ tiết % mờ ở góc cho khối thêm sinh động
            Positioned(
              right: -18,
              top: -22,
              child: Icon(
                AppIcons.sale,
                size: 120,
                color: _accent.withValues(alpha: 0.07),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 6, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: -3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          AppIcons.sale,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.trustedShopsDealsTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              maxDiscount > 0
                                  ? l10n.trustedShopsDealsUpTo(maxDiscount)
                                  : l10n.trustedShopsDealsSubtitle,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: onSeeAll,
                        style: TextButton.styleFrom(
                          foregroundColor: _accent,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.trustedShopsSeeAll,
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
                SizedBox(
                  height: AppListingCard.heightFor(_cardWidth),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: deals.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final item = deals[index];
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
                const SizedBox(height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
