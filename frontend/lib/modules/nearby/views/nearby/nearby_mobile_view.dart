import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/core/utils/formatters/distance_formatter.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/modules/location/views/area_search/area_search_view.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/app_option_sheet.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/filter/app_filter_bar.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/nearby_cubit.dart';
import '../../bloc/nearby_state.dart';
import 'widgets/nearby_filter_bar.dart';
import 'widgets/nearby_location_notice.dart';
import 'widgets/nearby_search_bar.dart';
import 'widgets/nearby_skeleton.dart';
import 'widgets/nearby_top_bar.dart';

class NearbyMobileView extends StatefulWidget {
  const NearbyMobileView({super.key});

  @override
  State<NearbyMobileView> createState() => _NearbyMobileViewState();
}

class _NearbyMobileViewState extends State<NearbyMobileView> {
  static const double _sidePadding = 16;
  static const double _contentRadius = 24;

  /// Ô địa điểm (48) + khoảng cách + hàng chip lọc + lề trên dưới
  static const double _searchHeaderHeight =
      8 + 48 + 10 + AppFilterChip.height + 12;

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

  String _distance(double km) => DistanceFormatter.format(
    km,
    AppLocalizations.of(context)!,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );

  /// Sheet Bộ lọc đầy đủ, có thêm nhóm Khoảng cách
  Future<void> _openFilters() async {
    final cubit = context.read<NearbyCubit>();
    final filter = await showListingFilterSheet(
      context,
      filter: cubit.state.filter,
      defaults: NearbyState.defaultFilter,
      radiusOptions: NearbyState.radiusOptions,
    );
    if (filter != null) cubit.applyFilter(filter);
  }

  void _back() => context.canPop() ? context.pop() : context.go('/home');

  Future<void> _pickRadius() async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NearbyCubit>();
    final radius = await showAppOptionSheet<double>(
      context,
      title: l10n.nearbyRadiusTitle,
      icon: AppIcons.nearby,
      selected: cubit.state.filter.radiusKm,
      options: [
        for (final km in NearbyState.radiusOptions)
          AppSheetOption(km, l10n.nearbyRadiusOption(_distance(km))),
      ],
    );
    if (radius != null) cubit.setRadius(radius);
  }

  Future<void> _pickSort() async {
    final cubit = context.read<NearbyCubit>();
    final sort = await showListingSortSheet(
      context,
      selected: cubit.state.filter.sort,
      options: NearbyState.sortOptions,
    );
    if (sort != null) cubit.setSort(sort);
  }

  /// Chọn khu vực khác để xem tin quanh đó, hoặc quay về vị trí GPS
  Future<void> _pickArea() async {
    final cubit = context.read<NearbyCubit>();
    final result = await context.push<AreaPickResult>(AreaSearchView.path);
    if (result == null || !mounted) return;
    final area = result.area;
    area == null ? cubit.relocate() : cubit.setArea(area);
  }

  /// Mở trang chi tiết; quay lại mà trạng thái lưu tin đã đổi thì cập nhật thẻ
  Future<void> _openDetail(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite == null || !mounted) return;
    context.read<NearbyCubit>().syncFavorite(id, favorite);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NearbyCubit>();
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
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
              child: BlocBuilder<NearbyCubit, NearbyState>(
                builder: (context, state) => AppPullToRefresh.inline(
                  onRefresh: cubit.refresh,
                  builder: (context, refreshIndicator) => AppLoadMoreListener(
                    onLoadMore: cubit.loadMore,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: NearbyTopBar(
                            key: _topBarKey,
                            onBack: _back,
                            onRelocate: cubit.relocate,
                            isLocating:
                                state.status == NearbyStatus.locating ||
                                state.isRelocating,
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: AppPinnedHeaderDelegate(
                            height: _searchHeaderHeight,
                            child: _searchHeader(state),
                          ),
                        ),
                        // Viên loading kéo để làm mới mở ra ngay dưới phần ghim
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
                        ..._content(state),
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
        ],
      ),
    );
  }

  Widget _searchHeader(NearbyState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NearbyCubit>();
    final origin = state.origin;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
            child: NearbySearchBar(
              locationLabel: origin == null
                  ? null
                  : origin.label ?? l10n.nearbyCurrentLocation,
              onTap: _pickArea,
            ),
          ),
          const SizedBox(height: 10),
          NearbyFilterBar(
            filter: state.filter,
            onFiltersTap: _openFilters,
            onRadiusTap: _pickRadius,
            onDealToggle: cubit.toggleDeal,
            onSortTap: _pickSort,
            onClearTap: cubit.clearFilters,
          ),
        ],
      ),
    );
  }

  List<Widget> _content(NearbyState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NearbyCubit>();
    final locationError = state.origin?.locationError;

    final notice = locationError == null
        ? null
        : SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _sidePadding,
              0,
              _sidePadding,
              14,
            ),
            sliver: SliverToBoxAdapter(
              child: NearbyLocationNotice(
                error: locationError,
                onUseLocation: cubit.relocate,
                onOpenSettings: cubit.openLocationSettings,
              ),
            ),
          );

    switch (state.status) {
      case NearbyStatus.locating:
      case NearbyStatus.loading:
        return [?notice, const SliverToBoxAdapter(child: NearbySkeleton())];
      case NearbyStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FeedbackView(
              icon: AppIcons.offline,
              title: l10n.nearbyLoadErrorTitle,
              message: l10n.nearbyLoadErrorBody,
              action: FilledButton(
                onPressed: cubit.retry,
                child: Text(l10n.retry),
              ),
            ),
          ),
        ];
      case NearbyStatus.ready:
        break;
    }

    if (state.items.isEmpty) {
      final wider = state.widerRadius;
      return [
        ?notice,
        SliverFillRemaining(
          hasScrollBody: false,
          child: FeedbackView(
            icon: AppIcons.nearby,
            title: l10n.nearbyEmptyTitle,
            message: l10n.nearbyEmptyBody,
            action: wider == null
                ? null
                : FilledButton(
                    onPressed: () => cubit.setRadius(wider),
                    child: Text(l10n.nearbyExpandRadius(_distance(wider))),
                  ),
          ),
        ),
      ];
    }

    return [
      ?notice,
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
        sliver: AppListingSliverGrid(
          items: state.items,
          itemBuilder: (_, item) => AppListingCard(
            item: item,
            showDistance: true,
            onTap: () => _openDetail(item),
            onFavoriteTap: () => cubit.toggleFavorite(item),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: AppLoadMoreFooter(
          isLoading: state.isLoadingMore,
          hasMore: state.hasMore,
          endText: l10n.nearbyEndOfList,
        ),
      ),
    ];
  }
}
