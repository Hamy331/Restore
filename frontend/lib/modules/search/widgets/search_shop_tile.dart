import 'package:flutter/material.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_verification_badge.dart';
import 'package:restore/shared/widgets/search/app_search_account_tile.dart';

/// Cửa hàng trong kết quả / gợi ý tìm kiếm: logo, tên kèm nhãn xác minh,
/// số người theo dõi và số tin đang bán
class SearchShopTile extends StatelessWidget {
  final TrustedShopItem item;
  final String? highlight;
  final Widget? trailing;
  final VoidCallback onTap;

  const SearchShopTile({
    super.key,
    required this.item,
    required this.onTap,
    this.highlight,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = item.shop;
    final type = shop.verificationType;
    return AppSearchAccountTile(
      leading: ShopLogo(shop: shop, size: 44),
      title: shop.name,
      highlight: highlight,
      badge: type == null
          ? null
          : ShopVerificationBadge(type: type, iconOnly: true),
      subtitle: l10n.searchShopSubtitle(shop.followerCount, shop.listingCount),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
