import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';

import '../../../bloc/followed_shops/followed_shops_cubit.dart';
import '../../../bloc/followed_shops/followed_shops_state.dart';
import '../../../models/followed_shop.dart';
import '../../../widgets/followed_shops_strip.dart';
import '../../../widgets/trusted_shop_section_header.dart';

/// Khu "Shop bạn theo dõi" đầu trang Shop uy tín. Ẩn khi chưa theo dõi shop
/// nào hoặc chưa tải được (VD chưa đăng nhập).
class FollowedShopsSection extends StatelessWidget {
  const FollowedShopsSection({
    super.key,
    required this.onShopTap,
    required this.onSeeAll,
  });

  final ValueChanged<FollowedShop> onShopTap;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return BlocBuilder<FollowedShopsCubit, FollowedShopsState>(
      builder: (context, state) {
        final shops = [
          for (final shop in state.shops)
            if (shop.item.isFollowing) shop,
        ];
        if (shops.isEmpty) return const SizedBox.shrink();
        final fresh = shops.fold(0, (sum, shop) => sum + shop.newListingCount);
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrustedShopSectionHeader(
                title: l.followShopsFeedTitle,
                subtitle: fresh > 0
                    ? l.followShopsFeedNew(fresh)
                    : l.followShopsCount(state.total),
                highlightSubtitle: fresh > 0,
                trailing: TextButton.icon(
                  key: const ValueKey('followed-shops-see-all'),
                  onPressed: onSeeAll,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(AppIcons.chevronRight, size: 16),
                  label: Text(l.followShopsFeedCta),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FollowedShopsStrip(shops: shops, onShopTap: onShopTap),
            ],
          ),
        );
      },
    );
  }
}
