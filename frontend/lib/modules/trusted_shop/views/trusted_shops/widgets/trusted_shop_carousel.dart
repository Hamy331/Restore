import 'package:flutter/material.dart';

import '../../../models/trusted_shop_item.dart';
import '../../../widgets/trusted_shop_section_header.dart';
import 'trusted_shop_card.dart';
import 'trusted_shops_responsive.dart';

/// Một khu shop (Thương hiệu nổi tiếng, Mới gia nhập...): tiêu đề kèm nhãn
/// màu của khu và hàng thẻ shop cuộn ngang
class TrustedShopCarousel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String eyebrow;
  final Color accent;
  final List<TrustedShopItem> shops;
  final ValueChanged<TrustedShopItem> onShopTap;
  final ValueChanged<TrustedShopItem> onFollowTap;

  const TrustedShopCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.eyebrow,
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
          eyebrow: eyebrow,
          accent: accent,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            final columns = shopGridColumns(box.maxWidth - 32, minWidth: 260);
            // Điện thoại: hàng cuộn ngang. Tablet / desktop: lưới, không cuộn
            if (columns == null) {
              return SizedBox(
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
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: TrustedShopCard.height,
                ),
                itemCount: shops.length,
                itemBuilder: (_, index) {
                  final item = shops[index];
                  return TrustedShopCard(
                    item: item,
                    expand: true,
                    onTap: () => onShopTap(item),
                    onFollowTap: () => onFollowTap(item),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
