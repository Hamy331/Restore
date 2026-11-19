import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/feeds/widgets/feed_shared.dart';
import 'package:restore/modules/trusted_shop/bloc/followed_shops/followed_shops_cubit.dart';
import 'package:restore/modules/trusted_shop/bloc/followed_shops/followed_shops_state.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/modules/trusted_shop/repositories/shop_following_repository.dart';
import 'package:restore/modules/trusted_shop/views/following_shops/following_shops_view.dart';
import 'package:restore/modules/trusted_shop/views/shop_detail/shop_detail_view.dart';
import 'package:restore/modules/trusted_shop/views/trusted_shops/trusted_shops_view.dart';
import 'package:restore/modules/trusted_shop/widgets/followed_shop_tile.dart';
import 'package:restore/modules/trusted_shop/widgets/followed_shops_empty.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

/// Tab "Shop" ở trang Đang theo dõi (chỉ hồ sơ của mình): các shop uy tín
/// đang theo dõi, lối vào trang tin mới của họ.
class FollowedShopsTab extends StatelessWidget {
  const FollowedShopsTab({super.key, required this.repository});

  final ShopFollowingRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => FollowedShopsCubit(repository)..load(),
    child: const _FollowedShopsList(),
  );
}

class _FollowedShopsList extends StatelessWidget {
  const _FollowedShopsList();

  Future<void> _openShop(BuildContext context, FollowedShop shop) async {
    final cubit = context.read<FollowedShopsCubit>();
    final following = await context.push<bool>(
      ShopDetailView.location(shop.id),
      extra: shop.item,
    );
    if (following != null) cubit.sync(shop.id, following);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<FollowedShopsCubit>();
    return BlocConsumer<FollowedShopsCubit, FollowedShopsState>(
      listenWhen: (_, state) => state.actionFailed,
      listener: (context, _) => feedNotice(context, l.feedActionError),
      builder: (context, state) {
        if (state.loading && state.shops.isEmpty) {
          return const Center(child: AppLoadingIndicator());
        }
        if (state.failed) {
          return Center(
            child: TextButton(onPressed: cubit.load, child: Text(l.retry)),
          );
        }
        if (state.shops.isEmpty) {
          return FollowedShopsEmpty(
            onBrowse: () => context.push(TrustedShopsView.path),
          );
        }
        return AppPullToRefresh(
          onRefresh: cubit.load,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 300) cubit.load(more: true);
              return false;
            },
            child: ListView.builder(
              itemCount: state.shops.length + (state.hasMore ? 2 : 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _FeedEntry(
                    count: state.shops.fold(
                      0,
                      (sum, shop) => sum + shop.newListingCount,
                    ),
                    onTap: () => context.push(FollowingShopsView.path),
                  );
                }
                if (index > state.shops.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: AppLoadingIndicator()),
                  );
                }
                final shop = state.shops[index - 1];
                return FollowedShopTile(
                  key: ValueKey('followed-shop-tile-${shop.id}'),
                  shop: shop,
                  onTap: () => _openShop(context, shop),
                  onFollowTap: () => cubit.toggleFollow(shop),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Thẻ đầu tab: mở trang tin mới của các shop đang theo dõi
class _FeedEntry extends StatelessWidget {
  const _FeedEntry({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Material(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const ValueKey('followed-shops-feed'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.sparkle,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.followShopsFeedCta,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count > 0
                            ? l.followShopsFeedNew(count)
                            : l.followShopsLatestHint,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
