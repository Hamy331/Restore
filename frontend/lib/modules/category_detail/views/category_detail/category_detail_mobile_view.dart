import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_scroll.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_create/wanted_alert_create_view.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
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

/// Trang tin của một danh mục, cùng một bố cục cho điện thoại và web
/// desktop ([wide]): đầu trang trắng gồm ô tìm kiếm mang tên danh mục,
/// khu vực, hàng nút lọc, chọn nhanh tỉnh/thành, hàng sắp xếp; bên dưới
/// là danh sách tin dạng hàng ngang (có thể đổi sang lưới).
class CategoryDetailMobileView extends StatefulWidget {
  const CategoryDetailMobileView({super.key, this.wide = false});

  /// Web desktop: đặt trong khung giữa màn hình (header site ở trên)
  final bool wide;

  @override
  State<CategoryDetailMobileView> createState() =>
      _CategoryDetailMobileViewState();
}

class _CategoryDetailMobileViewState extends State<CategoryDetailMobileView> {
  bool _grid = false;

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
          onSearch: () => context.push('/search'),
          onSaveSearch: () => context.push(
            WantedAlertCreateView.location(
              keywords: state.category?.name.of(context) ?? '',
            ),
          ),
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
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              bottom: false,
              child: AppPullToRefresh(
                onRefresh: _cubit.refresh,
                child: AppLoadMoreListener(
                  onLoadMore: _cubit.loadMore,
                  child: CustomScrollView(
                    // Dựng sẵn và tải ảnh trước khoảng 1,5 màn hình phía dưới
                    scrollCacheExtent: AppScroll.prefetchCacheExtent,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
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

/// Đầu trang trắng của trang danh mục: ô tìm kiếm mang tên danh mục, thanh
/// lọc dùng chung (như trang tìm kiếm) và hàng sắp xếp
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.grid,
    required this.wide,
    required this.onBack,
    required this.onSearch,
    required this.onSaveSearch,
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
  final VoidCallback onSearch;
  final VoidCallback onSaveSearch;
  final VoidCallback onFilters;
  final ValueChanged<ListingFilter> onFilterChanged;
  final ValueChanged<String> onSwitchCategory;
  final VoidCallback onClearAll;
  final VoidCallback onSort;
  final VoidCallback onGridToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final categoryName = state.category?.name.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quay lại + ô tìm kiếm mang tên danh mục + lưu tìm kiếm
        Padding(
          padding: EdgeInsets.fromLTRB(wide ? 12 : 4, wide ? 14 : 6, 12, 6),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.back,
                onPressed: onBack,
                icon: const Icon(AppIcons.back, size: 24),
              ),
              Expanded(
                child: Material(
                  color: ListingBarChip.fill,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onSearch,
                    child: SizedBox(
                      height: 46,
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            AppIcons.search,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              categoryName ?? l10n.categoryDetailSearch,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 22,
                            color: AppColors.border,
                          ),
                          IconButton(
                            tooltip: t(
                              'Lưu tìm kiếm, báo khi có hàng',
                              'Save search',
                            ),
                            onPressed: onSaveSearch,
                            icon: const Icon(
                              Icons.bookmark_border,
                              size: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
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
