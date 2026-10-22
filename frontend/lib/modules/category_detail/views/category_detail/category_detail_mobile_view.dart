import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/theme/app_header_palette.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
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

import '../../bloc/category_detail_cubit.dart';
import '../../bloc/category_detail_state.dart';
import 'widgets/category_detail_header.dart';

class CategoryDetailMobileView extends StatefulWidget {
  const CategoryDetailMobileView({super.key});

  @override
  State<CategoryDetailMobileView> createState() =>
      _CategoryDetailMobileViewState();
}

class _CategoryDetailMobileViewState extends State<CategoryDetailMobileView> {
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

  void _openSearch() => context.push('/search');

  void _createListing() => context.push(CreateListingStep.category.path);

  /// Sheet Bộ lọc đầy đủ, ẩn nhóm Danh mục vì trang đã cố định danh mục
  Future<void> _openFilters() async {
    final cubit = context.read<CategoryDetailCubit>();
    final filter = await showListingFilterSheet(
      context,
      filter: cubit.state.filter,
      defaults: cubit.state.defaultFilter,
      showCategories: false,
    );
    if (filter != null) cubit.applyFilter(filter);
  }

  Future<void> _pickSort() async {
    final cubit = context.read<CategoryDetailCubit>();
    final sort = await showListingSortSheet(
      context,
      selected: cubit.state.filter.sort,
      options: CategoryDetailState.sortOptions,
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
    context.read<CategoryDetailCubit>().syncFavorite(id, favorite);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CategoryDetailCubit>();
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
              child: BlocBuilder<CategoryDetailCubit, CategoryDetailState>(
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
                            height: CategoryDetailHeader.height,
                            child: CategoryDetailHeader(
                              category: state.category,
                              filter: state.filter,
                              defaults: state.defaultFilter,
                              onBack: _back,
                              onSearchTap: _openSearch,
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

  List<Widget> _content(CategoryDetailState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CategoryDetailCubit>();

    switch (state.status) {
      case CategoryDetailStatus.loading:
        return [const SliverToBoxAdapter(child: AppListingGridSkeleton())];
      case CategoryDetailStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: FeedbackView(
              icon: AppIcons.offline,
              title: l10n.categoryDetailLoadErrorTitle,
              message: l10n.categoryDetailLoadErrorBody,
              action: FilledButton(
                onPressed: cubit.retry,
                child: Text(l10n.retry),
              ),
            ),
          ),
        ];
      case CategoryDetailStatus.ready:
        break;
    }

    if (state.items.isEmpty) {
      // Đang lọc thì gợi ý xoá bộ lọc, không thì mời đăng tin đầu tiên
      final filtered = state.hasActiveFilters;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
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
                    onPressed: cubit.clearFilters,
                    child: Text(l10n.listingFilterReset),
                  )
                : FilledButton(
                    onPressed: _createListing,
                    child: Text(l10n.categoryDetailPostListing),
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
          endText: l10n.categoryDetailEndOfList,
        ),
      ),
    ];
  }
}
