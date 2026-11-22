import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_scroll.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_create/wanted_alert_create_view.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/glass/app_pinned_header_surface.dart';
import 'package:restore/shared/widgets/search/app_listing_search_bar.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/listing/app_hot_sale_section.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_row_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/category_detail_cubit.dart';
import '../../bloc/category_detail_state.dart';
import 'category_detail_view.dart';
import 'package:restore/shared/widgets/filter/listing_chip_filter_bar.dart';

/// Trang tin của một danh mục, trông giống hệt trang kết quả tìm kiếm: cùng
/// thanh tìm kiếm ghim trên dải xanh (ô hiện tên danh mục), cùng thanh lọc,
/// hàng Khu vực, hàng sắp xếp; bên dưới là danh sách tin dạng hàng ngang (có
/// thể đổi sang lưới). Web desktop ([wide]) dùng ô tìm kiếm của header site.
class CategoryDetailMobileView extends StatefulWidget {
  const CategoryDetailMobileView({
    super.key,
    this.wide = false,
    this.fromSearch = false,
  });

  /// Web desktop: đặt trong khung giữa màn hình (header site ở trên)
  final bool wide;

  /// Mở từ trang tìm kiếm: chạm ô tìm kiếm thì quay lại trang đó
  final bool fromSearch;

  @override
  State<CategoryDetailMobileView> createState() =>
      _CategoryDetailMobileViewState();
}

class _CategoryDetailMobileViewState extends State<CategoryDetailMobileView> {
  static const double _contentRadius = 24;

  /// Ô tìm kiếm (48) + lề trên dưới, như phần đầu trang kết quả
  static const double _searchBarHeight = 8 + AppListingSearchBar.height + 12;

  bool _grid = false;

  final _scrollController = ScrollController();

  /// Thanh tìm kiếm đã ghim (đã cuộn), để dải thanh trạng thái đổi màu theo
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

  /// Chạm ô tìm kiếm: quay lại trang tìm kiếm nếu vừa từ đó sang (ô đã được
  /// xoá trống), không thì mở trang tìm kiếm trống
  void _editQuery() {
    if (widget.fromSearch && context.canPop()) {
      context.pop();
      return;
    }
    context.push('/search');
  }

  CategoryDetailCubit get _cubit => context.read<CategoryDetailCubit>();

  void _back() => context.canPop() ? context.pop() : context.go('/home');

  /// Sheet Bộ lọc đầy đủ (nút "Lọc")
  Future<void> _openFilters() async {
    final filter = await showListingFilterSheet(
      context,
      filter: _cubit.state.filter,
      defaults: _cubit.state.defaultFilter,
      showCategories: false,
    );
    if (filter != null) _cubit.applyFilter(filter);
  }

  Future<void> _pickSort() async {
    final sort = await showListingSortSheet(
      context,
      selected: _cubit.state.filter.sort,
      options: CategoryDetailState.sortOptions,
    );
    if (sort != null) _cubit.setSort(sort);
  }

  Future<void> _openDetail(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = await context.push<bool>(
      '/listings/$id',
      extra: item.listing,
    );
    if (favorite == null || !mounted) return;
    _cubit.syncFavorite(id, favorite);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryDetailCubit, CategoryDetailState>(
      builder: (context, state) {
        final header = _Header(
          state: state,
          grid: _grid,
          wide: widget.wide,
          onBack: _back,
          onFilters: _openFilters,
          onFilterChanged: _cubit.applyFilter,
          onSwitchCategory: (id) =>
              context.pushReplacement(CategoryDetailView.location(id)),
          onClearAll: _cubit.clearFilters,
          onSort: _pickSort,
          onGridToggle: () => setState(() => _grid = !_grid),
        );

        if (widget.wide) {
          return DesktopPage(
            contentWidth: 1000,
            onEndReached: _cubit.loadMore,
            slivers: [
              DecoratedSliver(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(child: header),
                    ..._content(state, wide: true),
                  ],
                ),
              ),
            ],
          );
        }

        final padding = MediaQuery.paddingOf(context);
        final name = state.category?.name.of(context) ?? '';
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
                  child: AppPullToRefresh(
                    onRefresh: _cubit.refresh,
                    child: AppLoadMoreListener(
                      onLoadMore: _cubit.loadMore,
                      child: CustomScrollView(
                        // Dựng sẵn và tải ảnh trước khoảng 1,5 màn hình phía dưới
                        scrollCacheExtent: AppScroll.prefetchCacheExtent,
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: AppPinnedHeaderDelegate(
                              height: _searchBarHeight,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 12,
                                ),
                                child: AppListingSearchBar(
                                  // Đang duyệt danh mục, không phải tìm từ
                                  // khoá: ô trống với chữ gợi ý
                                  text: AppLocalizations.of(
                                    context,
                                  )!.homeSearchHint,
                                  isPlaceholder: true,
                                  onBack: _back,
                                  onEdit: _editQuery,
                                  onSave: () => context.push(
                                    WantedAlertCreateView.location(
                                      keywords: name,
                                    ),
                                  ),
                                ),
                              ),
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
                          SliverToBoxAdapter(child: header),
                          ..._content(state, wide: false),
                          SliverToBoxAdapter(
                            child: SizedBox(height: padding.bottom + 16),
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

  List<Widget> _content(CategoryDetailState state, {required bool wide}) {
    final l10n = AppLocalizations.of(context)!;
    const side = 16.0;

    switch (state.status) {
      case CategoryDetailStatus.loading:
        return [const SliverToBoxAdapter(child: AppListingGridSkeleton())];
      case CategoryDetailStatus.failure:
        return [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 380,
              child: AppLoadErrorView(
                title: l10n.categoryDetailLoadErrorTitle,
                message: l10n.categoryDetailLoadErrorBody,
                onRetry: _cubit.retry,
              ),
            ),
          ),
        ];
      case CategoryDetailStatus.ready:
        break;
    }

    final items = state.items;
    if (items.isEmpty) {
      final filtered = state.hasActiveFilters || state.filter.hasArea;
      return [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 380,
            child: FeedbackView(
              icon: filtered ? AppIcons.searchEmpty : AppIcons.category,
              title: filtered
                  ? l10n.categoryDetailFilteredEmptyTitle
                  : l10n.categoryDetailEmptyTitle,
              message: filtered
                  ? l10n.categoryDetailFilteredEmptyBody
                  : l10n.categoryDetailEmptyBody,
              action: filtered
                  ? OutlinedButton(
                      onPressed: () {
                        _cubit.clearAll();
                      },
                      child: Text(l10n.listingFilterReset),
                    )
                  : FilledButton(
                      onPressed: () =>
                          context.push(CreateListingStep.category.path),
                      child: Text(l10n.categoryDetailPostListing),
                    ),
            ),
          ),
        ),
      ];
    }

    return [
      if (!state.hasActiveFilters &&
          !state.filter.hasArea &&
          state.hotItems.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(
          child: AppHotSaleSection(
            items: state.hotItems,
            onTap: _openDetail,
            onFavoriteTap: _cubit.toggleFavorite,
            sidePadding: side,
          ),
        ),
        const SliverToBoxAdapter(
          child: Divider(height: 24, color: AppColors.border),
        ),
      ],
      if (_grid)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(side, 12, side, 0),
          sliver: AppListingSliverGrid(
            items: items,
            itemBuilder: (_, item) => AppListingCard(
              item: item,
              onTap: () => _openDetail(item),
              onFavoriteTap: () => _cubit.toggleFavorite(item),
            ),
          ),
        )
      else
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (_, index) => AppListingRowCard(
            item: items[index],
            imageSize: wide ? 170 : 120,
            onTap: () => _openDetail(items[index]),
            onFavoriteTap: () => _cubit.toggleFavorite(items[index]),
          ),
        ),
      SliverToBoxAdapter(
        child: AppLoadMoreFooter(
          isLoading: state.isLoadingMore,
          hasMore: state.hasMore,
          endText: l10n.categoryDetailEndOfList,
        ),
      ),
    ];
  }
}

/// Thanh lọc dùng chung (như trang kết quả tìm kiếm) và hàng sắp xếp của
/// trang danh mục; ô tìm kiếm là [AppListingSearchBar] ghim ở đầu trang
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.grid,
    required this.wide,
    required this.onBack,
    required this.onFilters,
    required this.onFilterChanged,
    required this.onSwitchCategory,
    required this.onClearAll,
    required this.onSort,
    required this.onGridToggle,
  });

  final CategoryDetailState state;
  final bool grid;
  final bool wide;
  final VoidCallback onBack;
  final VoidCallback onFilters;
  final ValueChanged<ListingFilter> onFilterChanged;
  final ValueChanged<String> onSwitchCategory;
  final VoidCallback onClearAll;
  final VoidCallback onSort;
  final VoidCallback onGridToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide) const SizedBox(height: 14),
        ListingChipFilterBar(
          filter: state.filter,
          defaults: state.defaultFilter,
          category: state.category,
          onChanged: onFilterChanged,
          onFilters: onFilters,
          onSwitchCategory: onSwitchCategory,
          // Đang ở cả danh mục mà bấm × trên chip danh mục thì thoát trang
          onCloseCategory: onBack,
          onClearAll: onClearAll,
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 6, color: Color(0xFFF4F4F5)),
        ListingSortRow(
          sort: state.filter.sort,
          onSort: onSort,
          grid: grid,
          onGridToggle: onGridToggle,
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
