import 'package:flutter/material.dart';

import '../../../models/trusted_shop_item.dart';
import '../../../widgets/trusted_shop_section_header.dart';
import 'trusted_shop_card.dart';

/// Một khu shop (Thương hiệu nổi tiếng, Mới gia nhập...): tiêu đề kèm icon
/// màu của khu và hàng thẻ shop cuộn ngang
class TrustedShopCarousel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<TrustedShopItem> shops;
  final ValueChanged<TrustedShopItem> onShopTap;
  final ValueChanged<TrustedShopItem> onFollowTap;

  const TrustedShopCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.shops,
    required this.onShopTap,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrustedShopSectionHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          iconColor: accent,
        ),
        const SizedBox(height: 14),
        SizedBox(
          // Chừa chỗ cho bóng của thẻ
          height: TrustedShopCard.height + 4,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shops.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, index) {
              final item = shops[index];
              return Align(
                alignment: Alignment.topCenter,
                child: TrustedShopCard(
                  item: item,
                  onTap: () => onShopTap(item),
                  onFollowTap: () => onFollowTap(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
