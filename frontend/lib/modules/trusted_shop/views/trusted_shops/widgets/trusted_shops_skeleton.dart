import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';

import 'trusted_shop_card.dart';

/// Khung chờ khi đang tải trang: banner, dải tóm tắt, một hàng thẻ shop và
/// lưới tin
class TrustedShopsSkeleton extends StatelessWidget {
  const TrustedShopsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block({double? width, required double height, double radius = 18}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: block(height: 184, radius: 22),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: block(height: 40, radius: 16),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: block(width: 180, height: 18, radius: 8),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: TrustedShopCard.height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 2,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => block(
              width: TrustedShopCard.width,
              height: TrustedShopCard.height,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const AppListingGridSkeleton(rows: 1),
      ],
    );
  }
}
