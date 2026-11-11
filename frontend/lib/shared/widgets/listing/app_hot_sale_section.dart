import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/constants/app_images.dart' show AppImages;
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';

import 'app_listing_card.dart';

/// Mục Hot sale: nhãn Hot sale và dải tin ưu tiên (FEATURED) cuộn ngang.
/// Dùng ở trang chủ và đầu trang chuyên mục. Không có tin thì ẩn hẳn.
class AppHotSaleSection extends StatelessWidget {
  const AppHotSaleSection({
    super.key,
    required this.items,
    required this.onTap,
    required this.onFavoriteTap,
    this.onSeeAll,
    this.cardWidth = 164,
    this.sidePadding = 16,
    this.spacing = 12,
  });

  final List<ListingCardItem> items;
  final ValueChanged<ListingCardItem> onTap;
  final ValueChanged<ListingCardItem> onFavoriteTap;
  final VoidCallback? onSeeAll;
  final double cardWidth;
  final double sidePadding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(sidePadding, 0, 8, 0),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Semantics(
                  label: l10n.hotSaleTitle,
                  child: Image.asset(
                    AppImages.coreImages.hotSale,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Text(
                      l10n.hotSaleTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeSeeAll,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(AppIcons.chevronRight, size: 16),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: AppListingCard.heightFor(cardWidth),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: sidePadding),
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(width: spacing),
            itemBuilder: (_, index) {
              final item = items[index];
              return SizedBox(
                width: cardWidth,
                child: AppListingCard(
                  item: item,
                  onTap: () => onTap(item),
                  onFavoriteTap: () => onFavoriteTap(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
