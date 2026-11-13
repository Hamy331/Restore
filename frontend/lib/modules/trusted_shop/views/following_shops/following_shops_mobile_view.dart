import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/following_feed/following_feed_cubit.dart';
import '../../bloc/following_feed/following_feed_state.dart';
import '../../models/followed_shop.dart';
import '../../widgets/followed_shops_empty.dart';
import '../../widgets/followed_shops_strip.dart';
import '../../widgets/trusted_shop_section_header.dart';
import '../shop_detail/shop_detail_view.dart';
import '../trusted_shops/trusted_shops_view.dart';

class FollowingShopsMobileView extends StatelessWidget {
  const FollowingShopsMobileView({super.key});

  /// Mở trang shop; quay lại mà đã đổi theo dõi thì tải lại trang này
  Future<void> _openShop(BuildContext context, FollowedShop shop) async {
    final cubit = context.read<FollowingFeedCubit>();
    final following = await context.push<bool>(
      ShopDetailView.location(shop.id),
      extra: shop.item,
    );
    if (following != null && following != shop.item.isFollowing) {
      await cubit.load(showLoading: false);
    }
  }

  Future<void> _openListing(BuildContext context, ListingCardItem item) async {
    final cubit = context.read<FollowingFeedCubit>();
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite != null) cubit.syncFavorite(id, favorite);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<FollowingFeedCubit>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l.followShopsFeedTitle),
      ),
      body: BlocBuilder<FollowingFeedCubit, FollowingFeedState>(
        builder: (context, state) {
          switch (state.status) {
            case FollowingFeedStatus.loading:
              return const Center(child: AppLoadingIndicator());
            case FollowingFeedStatus.failure:
              return FeedbackView(
                icon: AppIcons.offline,
                title: l.followShopsLoadError,
                message: l.trustedShopsLoadErrorBody,
                action: FilledButton(
                  onPressed: cubit.load,
                  child: Text(l.retry),
                ),
              );
            case FollowingFeedStatus.ready:
              break;
          }
          if (state.shops.isEmpty) {
            return FollowedShopsEmpty(
              onBrowse: () => context.push(TrustedShopsView.path),
            );
          }
          return AppPullToRefresh(
            onRefresh: () => cubit.load(showLoading: false),
            child: AppLoadMoreListener(
              onLoadMore: cubit.loadMore,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: TrustedShopSectionHeader(
                      title: l.followShopsCount(state.shopTotal),
                      subtitle: l.followShopsStripHint,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: FollowedShopsStrip(
                      shops: state.shops,
                      onShopTap: (shop) => _openShop(context, shop),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(
                    child: TrustedShopSectionHeader(
                      title: l.followShopsLatest,
                      subtitle: l.followShopsLatestHint,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (state.listings.isEmpty)
                    SliverToBoxAdapter(
                      child: FeedbackView(
                        icon: AppIcons.searchEmpty,
                        title: l.followShopsListingsEmpty,
                        message: l.followShopsListingsEmptyHint,
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: AppListingSliverGrid(
                        items: state.listings,
                        itemBuilder: (_, item) => AppListingCard(
                          item: item,
                          onTap: () => _openListing(context, item),
                          onFavoriteTap: () => cubit.toggleFavorite(item),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AppLoadMoreFooter(
                        isLoading: state.isLoadingMore,
                        hasMore: state.hasMore,
                        endText: l.followShopsEnd,
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 16,
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
