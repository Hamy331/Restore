import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/home_cubit.dart';
import '../../bloc/home_state.dart';
import '../../models/home_listing_item.dart';
import '../../models/home_quick_action.dart';
import 'widgets/home_banner_carousel.dart';
import 'widgets/home_category_strip.dart';
import 'widgets/home_header_palette.dart';
import 'widgets/home_listing_card.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_search_header.dart';
import 'widgets/home_section_header.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/home_top_bar.dart';

class HomeMobileView extends StatefulWidget {
  const HomeMobileView({super.key});

  @override
  State<HomeMobileView> createState() => _HomeMobileViewState();
}

class _HomeMobileViewState extends State<HomeMobileView> {
  /// Thẻ tin trong hàng "Dành cho bạn"
  static const double _featuredCardWidth = 164;

  /// Chiều rộng tối đa một cột của lưới "Tin đăng mới"
  static const double _gridMaxCardWidth = 220;
  static const double _gridSpacing = 12;
  static const double _sidePadding = 16;
  static const double _contentRadius = 24;

  static const String _messagesPath = '/messages';

  final _scrollController = ScrollController();
  final _topBarKey = GlobalKey();

  /// Ô tìm kiếm đã ghim chưa, để dải thanh trạng thái đổi màu theo
  final _searchPinned = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateSearchPinned);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchPinned.dispose();
    super.dispose();
  }

  void _updateSearchPinned() {
    final topBarHeight = _topBarKey.currentContext?.size?.height;
    if (topBarHeight == null) return;
    _searchPinned.value = _scrollController.offset >= topBarHeight;
  }

  /// Tính năng chưa có trang riêng (tìm kiếm, thông báo...)
  void _comingSoon() => TSnackBarHelper.showInfo(
    context,
    message: AppLocalizations.of(context)!.featureComingSoon,
  );

  /// Mở trang chi tiết; quay lại mà trạng thái lưu tin đã đổi thì cập nhật thẻ
  Future<void> _openDetail(HomeListingItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite == null || !mounted) return;
    context.read<HomeCubit>().syncFavorite(id, favorite);
  }

  void _onQuickAction(HomeQuickAction action) {
    // TODO: mở trang riêng khi có (gần bạn, thẻ đặt trước, shop uy tín,
    // đang theo dõi)
    switch (action) {
      case HomeQuickAction.nearby:
      case HomeQuickAction.wantedAlert:
      case HomeQuickAction.trustedShops:
      case HomeQuickAction.following:
        _comingSoon();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HomeCubit>();
    final padding = MediaQuery.paddingOf(context);

    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          // Thanh trạng thái cùng màu đầu trang, chuyển trắng khi ô tìm
          // kiếm đã ghim để hai phần liền nhau
          ValueListenableBuilder<bool>(
            valueListenable: _searchPinned,
            builder: (context, pinned, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: padding.top,
              width: double.infinity,
              color: pinned ? AppColors.surface : HomeHeaderPalette.top,
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) => AppPullToRefresh(
                  onRefresh: () => cubit.load(showLoading: false),
                  child: AppLoadMoreListener(
                    onLoadMore: cubit.loadMore,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: HomeTopBar(
                            key: _topBarKey,
                            areaName: state.areaName,
                            greetingName: state.user == null
                                ? ''
                                : state.greetingName,
                            onAreaTap: _comingSoon,
                            onMessagesTap: () => context.go(_messagesPath),
                            onNotificationsTap: _comingSoon,
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: HomeSearchHeaderDelegate(
                            hintText: l10n.homeSearchHint,
                            onTap: _comingSoon,
                          ),
                        ),
                        // Mép trên bo cong của phần nội dung trắng
                        SliverToBoxAdapter(
                          child: ColoredBox(
                            color: HomeHeaderPalette.bottom,
                            child: Container(
                              height: _contentRadius,
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(_contentRadius),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ...switch (state.status) {
                          HomeStatus.loading => [
                            const SliverToBoxAdapter(child: HomeSkeleton()),
                          ],
                          HomeStatus.failure => [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: FeedbackView(
                                icon: AppIcons.offline,
                                title: l10n.homeLoadErrorTitle,
                                message: l10n.homeLoadErrorBody,
                                action: FilledButton(
                                  onPressed: cubit.load,
                                  child: Text(l10n.retry),
                                ),
                              ),
                            ),
                          ],
                          HomeStatus.ready => _content(state),
                        },
                        SliverToBoxAdapter(
                          // Chừa chỗ cho thanh điều hướng phía dưới
                          child: SizedBox(height: padding.bottom + 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(HomeState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HomeCubit>();

    Widget card(HomeListingItem item) => HomeListingCard(
      item: item,
      onTap: () => _openDetail(item),
      onFavoriteTap: () => cubit.toggleFavorite(item),
    );

    return [
      SliverToBoxAdapter(
        child: HomeCategoryStrip(
          categories: state.categories,
          onTap: (_) => _comingSoon(),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      SliverToBoxAdapter(child: HomeQuickActions(onTap: _onQuickAction)),
      const SliverToBoxAdapter(child: SizedBox(height: 22)),
      SliverToBoxAdapter(
        child: HomeBannerCarousel(
          banners: state.banners,
          onTap: (banner) {
            final route = banner.route;
            if (route != null) context.push(route);
          },
        ),
      ),
      if (state.recommended.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        SliverToBoxAdapter(
          child: HomeSectionHeader(
            title: l10n.homeForYouTitle,
            actionLabel: l10n.homeSeeAll,
            onAction: _comingSoon,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: HomeListingCard.heightFor(_featuredCardWidth),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
              itemCount: state.recommended.length,
              separatorBuilder: (_, _) => const SizedBox(width: _gridSpacing),
              itemBuilder: (_, index) => SizedBox(
                width: _featuredCardWidth,
                child: card(state.recommended[index]),
              ),
            ),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: HomeSectionHeader(title: l10n.homeLatestTitle)),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      if (state.latest.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              l10n.homeLatestEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              final columns =
                  ((width + _gridSpacing) / (_gridMaxCardWidth + _gridSpacing))
                      .ceil()
                      .clamp(2, 6);
              final cardWidth =
                  (width - _gridSpacing * (columns - 1)) / columns;
              return SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: _gridSpacing,
                  crossAxisSpacing: _gridSpacing,
                  mainAxisExtent: HomeListingCard.heightFor(cardWidth),
                ),
                itemCount: state.latest.length,
                itemBuilder: (_, index) => card(state.latest[index]),
              );
            },
          ),
        ),
      SliverToBoxAdapter(
        child: AppLoadMoreFooter(
          isLoading: state.isLoadingMore,
          hasMore: state.hasMoreLatest,
          endText: state.latest.isEmpty ? null : l10n.homeEndOfList,
        ),
      ),
    ];
  }
}
