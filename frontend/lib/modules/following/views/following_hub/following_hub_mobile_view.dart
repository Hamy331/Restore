import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/modules/trusted_shop/views/shop_detail/shop_detail_view.dart';
import 'package:restore/modules/trusted_shop/views/trusted_shops/trusted_shops_view.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/following_hub_cubit.dart';
import '../../bloc/following_hub_state.dart';
import 'widgets/following_onboarding_hero.dart';
import 'widgets/following_people_row.dart';
import 'widgets/following_selected_shop.dart';
import 'widgets/following_shop_filter.dart';
import 'widgets/following_posts_row.dart';
import 'widgets/following_section_title.dart';
import 'widgets/shop_suggestion_card.dart';

class FollowingHubMobileView extends StatelessWidget {
  const FollowingHubMobileView({super.key});

  static const double _side = 16;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return BlocBuilder<FollowingHubCubit, FollowingHubState>(
      builder: (context, state) {
        final cubit = context.read<FollowingHubCubit>();
        final l = AppLocalizations.of(context)!;
        final picked = state.followedFromSuggestions;
        final showBar =
            state.status == FollowingHubStatus.ready &&
            state.isOnboarding &&
            picked > 0;
        return Scaffold(
          backgroundColor: AppColors.surface,
          bottomNavigationBar: showBar
              ? AppBottomActionBar(
                  key: const ValueKey('following-hub-see-feed'),
                  primaryLabel: l.followingHubSeeFeed(picked),
                  primaryIcon: AppIcons.sparkle,
                  onPrimary: cubit.load,
                )
              : null,
          body: Column(
            children: [
              Container(height: padding.top, color: AppHeaderPalette.top),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: AppPullToRefresh(
                    onRefresh: () => cubit.load(showLoading: false),
                    child: AppLoadMoreListener(
                      onLoadMore: cubit.loadMore,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _Header(state: state)),
                          ..._body(context, state),
                          SliverToBoxAdapter(
                            child: SizedBox(height: padding.bottom + 24),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _body(BuildContext context, FollowingHubState state) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<FollowingHubCubit>();
    switch (state.status) {
      case FollowingHubStatus.loading:
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: AppLoadingIndicator()),
          ),
        ];
      case FollowingHubStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FeedbackView(
              icon: AppIcons.offline,
              title: l.followShopsLoadError,
              message: l.trustedShopsLoadErrorBody,
              action: FilledButton(onPressed: cubit.load, child: Text(l.retry)),
            ),
          ),
        ];
      case FollowingHubStatus.ready:
        break;
    }
    return state.isOnboarding
        ? _onboarding(context, state)
        : _feed(context, state);
  }

  Widget _gap(double height) =>
      SliverToBoxAdapter(child: SizedBox(height: height));

  /// Bài đăng mới của người mình theo dõi; chưa có bài thì hiện hàng ảnh
  /// đại diện của họ
  List<Widget> _social(BuildContext context, FollowingHubState state) {
    final l = AppLocalizations.of(context)!;
    if (state.posts.isNotEmpty) {
      return [
        _gap(20),
        SliverToBoxAdapter(
          child: FollowingSectionTitle(
            title: l.followingHubPostsTitle,
            subtitle: l.followingHubPostsHint,
            actionLabel: l.followingHubSeeAll,
            onAction: () => context.go('/feeds'),
          ),
        ),
        _gap(10),
        SliverToBoxAdapter(
          child: FollowingPostsRow(
            posts: state.posts,
            onTap: (_) => context.go('/feeds'),
          ),
        ),
      ];
    }
    if (state.people.isEmpty) return const [];
    return [
      _gap(20),
      SliverToBoxAdapter(
        child: FollowingSectionTitle(
          title: l.followingHubPeopleTitle,
          actionLabel: l.followingHubSeeAll,
          onAction: () => _openFollows(context, state, 'following'),
        ),
      ),
      _gap(6),
      SliverToBoxAdapter(
        child: FollowingPeopleRow(
          people: state.people,
          onTap: (FollowUser user) => context.push('/users/${user.id}'),
        ),
      ),
    ];
  }

  List<Widget> _feed(BuildContext context, FollowingHubState state) {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<FollowingHubCubit>();
    final selected = state.selectedShop;
    return [
      ..._social(context, state),
      _gap(state.posts.isEmpty && state.people.isEmpty ? 8 : 22),
      SliverToBoxAdapter(
        child: FollowingSectionTitle(
          title: l.followingHubFeedTitle,
          subtitle: l.followingHubFeedHint,
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: FollowingShopFilterDelegate(
          shops: state.shops,
          selectedId: state.selectedShopId,
          onSelect: cubit.selectShop,
        ),
      ),
      if (selected != null) ...[
        _gap(4),
        SliverToBoxAdapter(
          child: FollowingSelectedShop(
            shop: selected,
            onOpen: () => _openShop(context, selected.item),
          ),
        ),
      ],
      _gap(12),
      if (state.isLoadingListings)
        const SliverToBoxAdapter(child: AppListingGridSkeleton())
      else if (state.listings.isEmpty)
        SliverToBoxAdapter(
          child: FeedbackView(
            icon: AppIcons.searchEmpty,
            title: l.followShopsListingsEmpty,
            message: l.followShopsListingsEmptyHint,
          ),
        )
      else ...[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _side),
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
      // Hết tin thì gợi ý thêm vài shop để theo dõi
      if (!state.hasMore &&
          !state.isLoadingListings &&
          state.suggestions.isNotEmpty) ...[
        _gap(18),
        SliverToBoxAdapter(
          child: FollowingSectionTitle(
            title: l.followingHubForYouTitle,
            subtitle: l.followingHubSuggestHint,
          ),
        ),
        _gap(12),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _side),
              itemCount: state.suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _suggestion(context, state, index, width: 300),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _onboarding(BuildContext context, FollowingHubState state) {
    final l = AppLocalizations.of(context)!;
    return [
      SliverToBoxAdapter(
        child: _HeaderTail(
          child: FollowingOnboardingHero(suggestions: state.suggestions),
        ),
      ),
      ..._social(context, state),
      _gap(24),
      SliverToBoxAdapter(
        child: FollowingSectionTitle(
          title: l.followingHubForYouTitle,
          subtitle: l.followingHubSuggestHint,
        ),
      ),
      _gap(12),
      if (state.suggestions.isEmpty)
        SliverToBoxAdapter(
          child: FeedbackView(
            icon: AppIcons.shop,
            title: l.followingHubNoSuggestions,
            message: l.followShopsEmptyHint,
            action: FilledButton(
              onPressed: () => context.push(TrustedShopsView.path),
              child: Text(l.followShopsBrowse),
            ),
          ),
        )
      else ...[
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _side),
          sliver: SliverList.separated(
            itemCount: state.suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _suggestion(context, state, index),
          ),
        ),
        _gap(16),
        SliverToBoxAdapter(
          child: Center(
            child: TextButton.icon(
              onPressed: () => context.push(TrustedShopsView.path),
              iconAlignment: IconAlignment.end,
              icon: const Icon(AppIcons.chevronRight, size: 16),
              label: Text(l.followShopsBrowse),
            ),
          ),
        ),
      ],
    ];
  }

  Widget _suggestion(
    BuildContext context,
    FollowingHubState state,
    int index, {
    double? width,
  }) {
    final cubit = context.read<FollowingHubCubit>();
    final suggestion = state.suggestions[index];
    return ShopSuggestionCard(
      key: ValueKey('suggestion-${suggestion.id}'),
      width: width,
      suggestion: suggestion,
      onTap: () => _openShop(context, suggestion.item, suggestion: true),
      onFollowTap: () => cubit.toggleSuggestion(suggestion),
      onListingTap: (item) =>
          context.push('/listings/${item.listing.id}', extra: item.listing),
    );
  }

  /// Mở trang shop; quay lại mà đã đổi theo dõi thì cập nhật. Shop gợi ý chỉ
  /// đổi thẻ (đang chọn shop để theo dõi), shop đang theo dõi thì tải lại.
  Future<void> _openShop(
    BuildContext context,
    TrustedShopItem item, {
    bool suggestion = false,
  }) async {
    final cubit = context.read<FollowingHubCubit>();
    final following = await context.push<bool>(
      ShopDetailView.location(item.shop.id),
      extra: item,
    );
    if (following == null || following == item.isFollowing) return;
    suggestion
        ? cubit.syncSuggestion(item.shop.id, following)
        : await cubit.load(showLoading: false);
  }

  Future<void> _openListing(BuildContext context, ListingCardItem item) async {
    final cubit = context.read<FollowingHubCubit>();
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite != null) cubit.syncFavorite(id, favorite);
  }

  /// Danh sách theo dõi của mình ([tab] following | shops), quay lại thì
  /// tải lại vì có thể đã bỏ theo dõi
  Future<void> _openFollows(
    BuildContext context,
    FollowingHubState state,
    String tab,
  ) async {
    final cubit = context.read<FollowingHubCubit>();
    await context.push('/users/${state.myId}/follows?tab=$tab&me=1');
    await cubit.load(showLoading: false);
  }
}

/// Nối màu kem của đầu trang xuống nửa trên thẻ đầu tiên để thẻ như nổi
/// trên mép đầu trang
class _HeaderTail extends StatelessWidget {
  const _HeaderTail({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppHeaderPalette.bottom,
          AppHeaderPalette.bottom,
          AppColors.surface,
          AppColors.surface,
        ],
        stops: [0, 0.4, 0.4, 1],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: child,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final FollowingHubState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final myId = state.myId;
    return AppPageHeader(
      title: l.followingHubTitle,
      subtitle: state.isOnboarding && state.status == FollowingHubStatus.ready
          ? l.followingHubOnboardSubtitle
          : l.followingHubSubtitle,
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      trailing: myId == null
          ? null
          : AppCircleIconButton(
              icon: AppIcons.followUser,
              tooltip: l.followingHubManage,
              onTap: () => context.push('/users/$myId/follows?tab=shops&me=1'),
            ),
    );
  }
}
