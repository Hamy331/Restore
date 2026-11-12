import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';

import 'following_palette.dart';

/// Hàng chọn shop được ghim khi cuộn: "Tất cả" và từng shop đang theo dõi,
/// chấm đỏ là shop có tin mới
class FollowingShopFilterDelegate extends SliverPersistentHeaderDelegate {
  FollowingShopFilterDelegate({
    required this.shops,
    required this.selectedId,
    required this.onSelect,
  });

  static const double height = 60;

  final List<FollowedShop> shops;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  bool shouldRebuild(FollowingShopFilterDelegate old) =>
      old.shops != shops || old.selectedId != selectedId;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final l = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: overlaps ? AppColors.border : Colors.transparent,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        itemCount: shops.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChip(
              key: const ValueKey('following-filter-all'),
              selected: selectedId == null,
              onTap: () => onSelect(null),
              leading: const Icon(
                AppIcons.sparkle,
                size: 16,
                color: FollowingPalette.accent,
              ),
              label: l.followingHubAll,
            );
          }
          final shop = shops[index - 1];
          return _FilterChip(
            key: ValueKey('following-filter-${shop.id}'),
            selected: selectedId == shop.id,
            onTap: () => onSelect(shop.id),
            leading: ShopLogo(shop: shop.item.shop, size: 24),
            label: shop.item.shop.name,
            dot: shop.newListingCount > 0,
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.label,
    this.dot = false,
  });

  final bool selected, dot;
  final VoidCallback onTap;
  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? FollowingPalette.tint : AppColors.surface,
    shape: StadiumBorder(
      side: BorderSide(
        color: selected ? FollowingPalette.accent : AppColors.border,
        width: selected ? 1.4 : 1,
      ),
    ),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 26, child: Center(child: leading)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? FollowingPalette.deep
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (dot) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
