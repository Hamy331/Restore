import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_scroll.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_dimesions.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/modules/auth/bloc/auth/auth_context.dart';
import 'package:restore/modules/auth/utils/auth_route_guard.dart';
import 'package:restore/modules/trusted_shop/views/shop_detail/shop_detail_view.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_follow_button.dart';
import 'package:restore/modules/trusted_shop/widgets/shop_logo.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_create/wanted_alert_create_view.dart';
import 'package:restore/modules/location/utils/listing_area.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/search_accounts_cubit.dart';
import '../../bloc/search_accounts_state.dart';
import '../../bloc/search_results_cubit.dart';
import '../../bloc/search_results_state.dart';
import '../../models/search_user_item.dart';
import '../../widgets/search_shop_tile.dart';
import '../../widgets/search_user_tile.dart';
import 'widgets/search_results_alert_prompt.dart';
import 'widgets/search_results_header.dart';
import 'widgets/search_results_shop_strip.dart';

class SearchResultsMobileView extends StatefulWidget {
  final bool fromSearch;

  const SearchResultsMobileView({super.key, this.fromSearch = false});

  @override
  State<SearchResultsMobileView> createState() =>
      _SearchResultsMobileViewState();
}

class _SearchResultsMobileViewState extends State<SearchResultsMobileView> {
  static const double _sidePadding = 16;
  static const double _contentRadius = 24;

  final _scrollController = ScrollController();

  /// Phần đầu đã ghim (đã cuộn), để dải thanh trạng thái đổi màu theo
  final _headerPinned = ValueNotifier(false);

  var _tab = SearchResultsTab.listings;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateHeaderPinned);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerPinned.dispose();
    super.dispose();
  }

  void _updateHeaderPinned() =>
      _headerPinned.value = _scrollController.offset > 0;

  void _back() => context.canPop() ? context.pop() : context.go('/home');

  /// Sửa từ khoá: quay về trang tìm kiếm (từ khoá vẫn nằm trên ô), hoặc mở
  /// trang tìm kiếm mới nếu trang này không mở từ đó
  void _editQuery() {
    if (widget.fromSearch && context.canPop()) {
      context.pop();
      return;
    }
    final query = context.read<SearchResultsCubit>().state.query;
    context.push(
      Uri(path: '/search', queryParameters: {'q': query}).toString(),
    );
  }

  /// Chưa thấy món ưng ý: đặt "Báo khi có hàng" cho từ khoá đang tìm
  void _createAlert() {
    final query = context.read<SearchResultsCubit>().state.query;
    context.push(WantedAlertCreateView.location(keywords: query));
  }

  /// Sheet Bộ lọc đầy đủ; chưa dùng vị trí nên không có nhóm Khoảng cách
  Future<void> _openFilters() async {
    final cubit = context.read<SearchResultsCubit>();
    final filter = await showListingFilterSheet(
      context,
      filter: cubit.state.filter,
      defaults: SearchResultsState.defaultFilter,
    );
    if (filter != null) cubit.applyFilter(filter);
  }

  /// Lọc theo tỉnh/thành hoặc phường/xã của tin
  Future<void> _pickArea() async {
    final cubit = context.read<SearchResultsCubit>();
    final filter = await pickListingArea(context, cubit.state.filter);
    if (filter != null) cubit.applyFilter(filter);
  }

  Future<void> _pickSort() async {
    final cubit = context.read<SearchResultsCubit>();
    final sort = await showListingSortSheet(
      context,
      selected: cubit.state.filter.sort,
      options: SearchResultsState.sortOptions,
    );
    if (sort != null) cubit.setSort(sort);
  }

  /// Mở trang chi tiết; quay lại mà trạng thái lưu tin đã đổi thì cập nhật thẻ
  Future<void> _openDetail(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite == null || !mounted) return;
    context.read<SearchResultsCubit>().syncFavorite(id, favorite);
  }

  /// Đổi tab: về đầu danh sách
  void _selectTab(SearchResultsTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  /// Mở trang shop; quay lại mà trạng thái theo dõi đã đổi thì cập nhật
  Future<void> _openShop(TrustedShopItem item) async {
    final following = await context.push<bool>(
      ShopDetailView.location(item.shop.id),
      extra: item,
    );
    if (following == null || !mounted) return;
    context.read<SearchAccountsCubit>().syncShopFollowing(
      item.shop.id,
      following,
    );
  }

  void _openUser(SearchUserItem user) => context.push('/users/${user.id}');

  /// Khách bấm Theo dõi thì mời đăng nhập, xong quay lại trang này
  bool _ensureSignedIn() {
    if (context.isSignedIn) return true;
    context.push(loginPath(from: GoRouterState.of(context).uri.toString()));
    return false;
  }

  /// Nút Theo dõi trên dòng shop; ẩn với shop của chính mình
  Widget? _shopFollowButton(TrustedShopItem item) {
    if (item.shop.ownerId == context.currentUser?.id) return null;
    return ShopFollowButton(
      following: item.isFollowing,
      accent: ShopLogo.accentOf(item.shop),
      onTap: () {
        if (_ensureSignedIn()) {
          context.read<SearchAccountsCubit>().toggleShopFollowing(item);
        }
      },
    );
  }

  /// Nút Theo dõi trên dòng người dùng; ẩn với chính mình
  Widget? _userFollowButton(SearchUserItem user) {
    if (user.id == context.currentUser?.id) return null;
    return ShopFollowButton(
      following: user.isFollowing,
      accent: AppColors.primaryDark,
      onTap: () {
        if (_ensureSignedIn()) {
          context.read<SearchAccountsCubit>().toggleUserFollowing(user);
        }
      },
    );
  }

  Future<void> _refresh() {
    final accounts = context.read<SearchAccountsCubit>();
    return switch (_tab) {
      SearchResultsTab.listings => Future.wait([
        context.read<SearchResultsCubit>().refresh(),
        accounts.reloadShops(showLoading: false),
      ]),
      SearchResultsTab.shops => accounts.reloadShops(showLoading: false),
      SearchResultsTab.users => accounts.reloadUsers(showLoading: false),
    };
  }

  void _loadMore() {
    final accounts = context.read<SearchAccountsCubit>();
    switch (_tab) {
      case SearchResultsTab.listings:
        context.read<SearchResultsCubit>().loadMore();
      case SearchResultsTab.shops:
        accounts.loadMoreShops();
      case SearchResultsTab.users:
        accounts.loadMoreUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchResultsCubit>();
    final padding = MediaQuery.paddingOf(context);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimesions.desktopWidth;
    final headerColor = isDesktop ? AppColors.surface : AppHeaderPalette.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Thanh trạng thái cùng màu phần đầu, chuyển trắng khi đã cuộn
          if (!isDesktop)
            ValueListenableBuilder<bool>(
              valueListenable: _headerPinned,
              builder: (context, pinned, _) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: padding.top,
                width: double.infinity,
                color: pinned
                    ? AppPinnedHeaderSurface.pinnedColor
                    : AppHeaderPalette.bottom,
              ),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: BlocBuilder<SearchResultsCubit, SearchResultsState>(
                builder: (context, state) =>
                    BlocBuilder<SearchAccountsCubit, SearchAccountsState>(
                      builder: (context, accounts) => AppPullToRefresh.inline(
                        onRefresh: _refresh,
                        builder: (context, refreshIndicator) => AppLoadMoreListener(
                          onLoadMore: _loadMore,
                          child: CustomScrollView(
                            // Dựng sẵn và tải ảnh trước khoảng 1,5 màn hình phía dưới
                            scrollCacheExtent: AppScroll.prefetchCacheExtent,
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: AppPinnedHeaderDelegate(
                                  height: SearchResultsHeader.heightFor(
                                    _tab,
                                    showSearch: !isDesktop,
                                  ),
                                  color: headerColor,
                                  child: SearchResultsHeader(
                                    showSearch: !isDesktop,
                                    query: state.query,
                                    tab: _tab,
                                    onTabChanged: _selectTab,
                                    filter: state.filter,
                                    onBack: _back,
                                    onEditQuery: _editQuery,
                                    onFiltersTap: _openFilters,
                                    onAreaTap: _pickArea,
                                    onDealToggle: cubit.toggleDeal,
                                    onSortTap: _pickSort,
                                    onClearTap: cubit.clearFilters,
                                  ),
                                ),
                              ),
                              // Viên loading kéo để làm mới mở ra ngay dưới phần ghim
                              SliverToBoxAdapter(
                                child: ColoredBox(
                                  color: headerColor,
                                  child: refreshIndicator,
                                ),
                              ),
                              // Mép trên bo cong của phần nội dung trắng
                              if (!isDesktop)
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
                              ...switch (_tab) {
                                SearchResultsTab.listings => _content(
                                  state,
                                  accounts.shops,
                                  isDesktop: isDesktop,
                                ),
                                SearchResultsTab.shops => _accountContent(
                                  accounts.shops,
                                  emptyTitle: l10nOf(
                                    context,
                                  ).searchShopsEmpty(state.query),
                                  emptyIcon: AppIcons.store,
                                  onRetry: () => context
                                      .read<SearchAccountsCubit>()
                                      .reloadShops(),
                                  tile: (item) => SearchShopTile(
                                    item: item,
                                    highlight: state.query,
                                    trailing: _shopFollowButton(item),
                                    onTap: () => _openShop(item),
                                  ),
                                ),
                                SearchResultsTab.users => _accountContent(
                                  accounts.users,
                                  emptyTitle: l10nOf(
                                    context,
                                  ).searchUsersEmpty(state.query),
                                  emptyIcon: AppIcons.user,
                                  onRetry: () => context
                                      .read<SearchAccountsCubit>()
                                      .reloadUsers(),
                                  tile: (user) => SearchUserTile(
                                    user: user,
                                    highlight: state.query,
                                    trailing: _userFollowButton(user),
                                    onTap: () => _openUser(user),
                                  ),
                                ),
                              },
                              SliverToBoxAdapter(
                                child: SizedBox(height: padding.bottom + 16),
                              ),
                            ],
                          ),
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

  static AppLocalizations l10nOf(BuildContext context) =>
      AppLocalizations.of(context)!;

  /// Tab Cửa hàng / Người dùng: danh sách dòng, tải thêm, trống, lỗi
  List<Widget> _accountContent<T>(
    SearchAccountList<T> list, {
    required String emptyTitle,
    required IconData emptyIcon,
    required VoidCallback onRetry,
    required Widget Function(T item) tile,
  }) {
    final l10n = l10nOf(context);
    switch (list.status) {
      case SearchResultsStatus.loading:
        return const [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ];
      case SearchResultsStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppLoadErrorView(
              title: l10n.searchLoadErrorTitle,
              onRetry: onRetry,
            ),
          ),
        ];
      case SearchResultsStatus.ready:
        break;
    }
    if (list.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedbackView(
            icon: emptyIcon,
            title: emptyTitle,
            message: l10n.searchAccountsEmptyBody,
            action: OutlinedButton(
              onPressed: _editQuery,
              child: Text(l10n.searchTryAnother),
            ),
          ),
        ),
      ];
    }
    return [
      SliverList.builder(
        itemCount: list.items.length,
        itemBuilder: (_, index) => tile(list.items[index]),
      ),
      SliverToBoxAdapter(
        child: AppLoadMoreFooter(
          isLoading: list.isLoadingMore,
          hasMore: list.hasMore,
          endText: l10n.searchEndOfList,
        ),
      ),
    ];
  }

  List<Widget> _content(
    SearchResultsState state,
    SearchAccountList<TrustedShopItem> shops, {
    required bool isDesktop,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SearchResultsCubit>();

    switch (state.status) {
      case SearchResultsStatus.loading:
        return [const SliverToBoxAdapter(child: AppListingGridSkeleton())];
      case SearchResultsStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppLoadErrorView(
              title: l10n.searchLoadErrorTitle,
              onRetry: cubit.retry,
            ),
          ),
        ];
      case SearchResultsStatus.ready:
        break;
    }

    final strip = shops.items.isEmpty
        ? null
        : SliverToBoxAdapter(
            child: SearchResultsShopStrip(
              shops: shops.items.take(10).toList(),
              onOpen: _openShop,
              onSeeAll: () => _selectTab(SearchResultsTab.shops),
            ),
          );

    if (state.items.isEmpty) {
      return [
        ?strip,
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedbackView(
            icon: AppIcons.searchEmpty,
            title: l10n.searchEmptyTitle(state.query),
            message: l10n.searchEmptyBody,
            action: Column(
              children: [
                FilledButton.icon(
                  onPressed: _createAlert,
                  icon: const Icon(AppIcons.wantedAlert, size: 18),
                  label: Text(l10n.homeQuickWanted),
                ),
                if (!isDesktop) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _editQuery,
                    child: Text(l10n.searchTryAnother),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    }

    return [
      ?strip,
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
        sliver: AppListingSliverGrid(
          items: state.items,
          itemBuilder: (_, item) => AppListingCard(
            item: item,
            onTap: () => _openDetail(item),
            onFavoriteTap: () => cubit.toggleFavorite(item),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: AppLoadMoreFooter(
          isLoading: state.isLoadingMore,
          hasMore: state.hasMore,
          endText: l10n.searchEndOfList,
        ),
      ),
      if (!state.hasMore)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_sidePadding, 4, _sidePadding, 0),
          sliver: SliverToBoxAdapter(
            child: SearchResultsAlertPrompt(
              query: state.query,
              onTap: _createAlert,
            ),
          ),
        ),
    ];
  }
}
