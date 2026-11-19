import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';

import '../models/followed_shop.dart';
import 'shop_logo.dart';

/// Dải ngang các shop đang theo dõi: logo, tên và chấm số tin mới
class FollowedShopsStrip extends StatelessWidget {
  const FollowedShopsStrip({
    super.key,
    required this.shops,
    required this.onShopTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<FollowedShop> shops;
  final ValueChanged<FollowedShop> onShopTap;
  final EdgeInsetsGeometry padding;

  static const double _itemWidth = 72;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: shops.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final shop = shops[index];
          final model = shop.item.shop;
          return InkWell(
            key: ValueKey('followed-shop-${shop.id}'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => onShopTap(shop),
            child: SizedBox(
              width: _itemWidth,
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ShopLogo(shop: model, size: 56),
                      if (shop.newListingCount > 0)
                        Positioned(
                          top: -5,
                          right: -7,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.surface,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              shop.newListingCount > 99
                                  ? '99+'
                                  : '${shop.newListingCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    model.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
