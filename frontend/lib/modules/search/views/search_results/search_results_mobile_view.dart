import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_create/wanted_alert_create_view.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/search_results_cubit.dart';
import '../../bloc/search_results_state.dart';
import 'widgets/search_results_alert_prompt.dart';
import 'widgets/search_results_header.dart';

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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchResultsCubit>();
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Thanh trạng thái cùng màu phần đầu, chuyển trắng khi đã cuộn
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
                builder: (context, state) => AppPullToRefresh.inline(
                  onRefresh: cubit.refresh,
                  builder: (context, refreshIndicator) => AppLoadMoreListener(
                    onLoadMore: cubit.loadMore,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: AppPinnedHeaderDelegate(
                            height: SearchResultsHeader.height,
                            child: SearchResultsHeader(
                              query: state.query,
                              filter: state.filter,
                              onBack: _back,
                              onEditQuery: _editQuery,
                              onFiltersTap: _openFilters,
                              onDealToggle: cubit.toggleDeal,
                              onSortTap: _pickSort,
                              onClearTap: cubit.clearFilters,
                            ),
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

  List<Widget> _content(SearchResultsState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SearchResultsCubit>();

    switch (state.status) {
      case SearchResultsStatus.loading:
        return [const SliverToBoxAdapter(child: AppListingGridSkeleton())];
      case SearchResultsStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FeedbackView(
              icon: AppIcons.offline,
              title: l10n.searchLoadErrorTitle,
              message: l10n.searchLoadErrorBody,
              action: FilledButton(
                onPressed: cubit.retry,
                child: Text(l10n.retry),
              ),
            ),
          ),
        ];
      case SearchResultsStatus.ready:
        break;
    }

    if (state.items.isEmpty) {
      return [
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
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _editQuery,
                  child: Text(l10n.searchTryAnother),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
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
