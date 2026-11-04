import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';

import '../../../widgets/trusted_shop_section_header.dart';

/// Khu "Trải nghiệm hàng hiệu": khối nền cam đỏ ấm, đầu khối là tiêu đề
/// kèm mức giảm cao nhất và nút "Xem tất cả", bên dưới là hàng thẻ tin đang giảm giá
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrustedShopSectionHeader(
              padding: const EdgeInsets.fromLTRB(14, 16, 6, 12),
              eyebrow: l10n.trustedShopsDealsEyebrow,
              title: l10n.trustedShopsDealsTitle,
              subtitle: maxDiscount > 0
                  ? l10n.trustedShopsDealsUpTo(maxDiscount)
                  : l10n.trustedShopsDealsSubtitle,
              accent: _accent,
              highlightSubtitle: true,
              trailing: TextButton(
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
      ),
    );
  }
}
