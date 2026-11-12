import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/config/dev_plan_override.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/category_detail/views/category_detail/category_detail_view.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_cubit.dart';
import 'package:restore/modules/location/bloc/user_area/user_area_state.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/modules/location/views/area_search/area_search_view.dart';
import 'package:restore/modules/following/views/following_hub/following_hub_view.dart';
import 'package:restore/modules/trusted_shop/views/trusted_shops/trusted_shops_view.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alerts/wanted_alerts_view.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_hot_sale_section.dart';
import 'package:restore/modules/hot_sale/views/hot_sale/hot_sale_view.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/home_cubit.dart';
import '../../bloc/home_state.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import '../../models/home_quick_action.dart';
import 'widgets/home_banner_carousel.dart';
import 'widgets/home_category_strip.dart';
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

  static const double _gridSpacing = 12;
  static const double _sidePadding = 16;
  static const double _contentRadius = 24;

  static const String _messagesPath = '/messages';
  static const String _nearbyPath = '/nearby';
  static const String _searchPath = '/search';

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

  void _openMessages() => context.go(_messagesPath);

  void _openSearch() => context.push(_searchPath);

  void _openHotSale() => context.push(HotSaleView.path);

  void _openCategory(CategoryModel category) =>
      context.push(CategoryDetailView.location(category.id), extra: category);

  /// Tên khu vực trên nút đầu trang: tỉnh theo GPS / tự chọn, không có thì
  /// "Toàn quốc"
  String _areaLabel(AppLocalizations l10n, UserAreaState area) =>
      switch (area.status) {
        UserAreaStatus.locating => l10n.homeAreaLocating,
        UserAreaStatus.nationwide => l10n.areaNationwide,
        UserAreaStatus.ready => area.area?.displayName ?? l10n.areaNationwide,
      };

  /// Chọn khu vực khác (có thêm "Toàn quốc")
  Future<void> _pickArea() async {
    final userArea = context.read<UserAreaCubit>();
    final result = await context.push<AreaPickResult>(
      AreaSearchView.location(allowNationwide: true),
    );
    if (result == null) return;
    if (result.nationwide) {
      userArea.selectNationwide();
    } else if (result.area case final area?) {
      userArea.select(area);
    }
  }

  /// Tính năng chưa có trang riêng (thông báo...)
  void _comingSoon() => TSnackBarHelper.showInfo(
    context,
    message: AppLocalizations.of(context)!.featureComingSoon,
  );

  /// Mở trang chi tiết; quay lại mà trạng thái lưu tin đã đổi thì cập nhật thẻ
  Future<void> _openDetail(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite == null || !mounted) return;
    context.read<HomeCubit>().syncFavorite(id, favorite);
  }

  /// Khách bấm lưu tin thì mời đăng nhập, xong quay lại trang chủ
  void _toggleFavorite(ListingCardItem item) {
    if (!context.isSignedIn) {
      context.go(loginPath(from: '/home'));
      return;
    }
    context.read<HomeCubit>().toggleFavorite(item);
  }

  void _onQuickAction(HomeQuickAction action) {
    switch (action) {
      case HomeQuickAction.nearby:
        context.push(_nearbyPath);
      case HomeQuickAction.wantedAlert:
        context.push(WantedAlertsView.path);
      case HomeQuickAction.trustedShops:
        context.push(TrustedShopsView.path);
      case HomeQuickAction.following:
        context.push(FollowingHubView.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HomeCubit>();
    final padding = MediaQuery.paddingOf(context);
    // Khách chưa đăng nhập: chuỗi rỗng, đầu trang hiện lời chào chung
    final greetingName = context.watchUser()?.givenName ?? '';

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
              color: pinned ? AppColors.surface : AppHeaderPalette.top,
            ),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) => AppPullToRefresh.inline(
                  onRefresh: () => cubit.load(showLoading: false),
                  builder: (context, refreshIndicator) => AppLoadMoreListener(
                    onLoadMore: cubit.loadMore,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: ValueListenableBuilder(
                            valueListenable: DevPlanOverride.plan,
                            builder: (context, plan, _) =>
                                BlocBuilder<UserAreaCubit, UserAreaState>(
                                  builder: (context, area) => HomeTopBar(
                                    key: _topBarKey,
                                    areaName: _areaLabel(l10n, area),
                                    greetingName: greetingName,
                                    plan: plan,
                                    onAreaTap: _pickArea,
                                    onPlanTap: DevPlanOverride.enabled
                                        ? DevPlanOverride.next
                                        : null,
                                  ),
                                ),
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: HomeSearchHeaderDelegate(
                            hintText: l10n.homeSearchHint,
                            onTap: _openSearch,
                            onMessagesTap: _openMessages,
                            onNotificationsTap: _comingSoon,
                          ),
                        ),
                        // Kéo xuống để làm mới: viên loading mở ra ngay dưới
                        // ô tìm kiếm, đẩy nội dung xuống thay vì bị che
                        SliverToBoxAdapter(
                          child: ColoredBox(
                            color: AppHeaderPalette.bottom,
                            child: refreshIndicator,
                          ),
                        ),
                        // Mép trên bo cong của phần nội dung trắng
                        SliverToBoxAdapter(
                          child: ColoredBox(
                            color: AppHeaderPalette.bottom,
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

    Widget card(ListingCardItem item) => AppListingCard(
      item: item,
      onTap: () => _openDetail(item),
      onFavoriteTap: () => _toggleFavorite(item),
    );

    return [
      SliverToBoxAdapter(
        child: HomeCategoryStrip(
          categories: state.categories,
          onTap: _openCategory,
          onHotSaleTap: _openHotSale,
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
          child: AppHotSaleSection(
            items: state.recommended,
            onTap: _openDetail,
            onFavoriteTap: _toggleFavorite,
            onSeeAll: _openHotSale,
            cardWidth: _featuredCardWidth,
            sidePadding: _sidePadding,
            spacing: _gridSpacing,
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
          sliver: AppListingSliverGrid(
            items: state.latest,
            spacing: _gridSpacing,
            itemBuilder: (_, item) => card(item),
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
