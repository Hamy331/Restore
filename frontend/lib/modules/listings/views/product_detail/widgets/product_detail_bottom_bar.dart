import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';

import '../../../models/product_detail.dart';

/// Thanh hành động cố định cuối trang, đổi theo tin:
/// - Tin của mình: Sửa tin + Đẩy tin
/// - Tin đã bán / đã có người đặt: chỉ còn nhắn tin
/// - Tin bán: nút vuông nhắn tin + Trả giá (nếu cho thương lượng) + Mua ngay
/// - Tin chỉ trao đổi: nút vuông nhắn tin + Đề nghị đổi
class ProductDetailBottomBar extends StatelessWidget {
  final ProductDetail detail;
  final bool isSubmitting;
  final VoidCallback onChat;
  final VoidCallback onOffer;
  final VoidCallback onBuy;
  final VoidCallback onEdit;
  final VoidCallback onBoost;

  const ProductDetailBottomBar({
    super.key,
    required this.detail,
    required this.isSubmitting,
    required this.onChat,
    required this.onOffer,
    required this.onBuy,
    required this.onEdit,
    required this.onBoost,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listing = detail.listing;

    if (detail.isOwner) {
      return AppBottomActionBar(
        secondaryLabel: l10n.productEditListing,
        secondaryIcon: AppIcons.edit,
        onSecondary: onEdit,
        primaryLabel: l10n.productBoost,
        primaryIcon: AppIcons.boost,
        onPrimary: onBoost,
      );
    }

    final chat = AppSecondaryActionButton(
      icon: AppIcons.chat,
      tooltip: l10n.productChat,
      onPressed: isSubmitting ? null : onChat,
    );

    if (!detail.isAvailable) {
      return AppBottomActionBar(
        leading: chat,
        primaryLabel: listing.status.label(l10n),
        onPrimary: null,
      );
    }

    final forSale = listing.allowSale && listing.price != null;
    return AppBottomActionBar(
      leading: chat,
      isLoading: isSubmitting,
      secondaryLabel: forSale && detail.canMakeOffer
          ? l10n.productMakeOffer
          : null,
      secondaryIcon: AppIcons.offer,
      onSecondary: onOffer,
      primaryLabel: forSale ? l10n.productBuyNow : l10n.productProposeExchange,
      primaryIcon: forSale ? AppIcons.buy : AppIcons.swap,
      // Tin chỉ trao đổi: thoả thuận món đổi qua tin nhắn
      onPrimary: forSale ? onBuy : onChat,
    );
  }
}
