import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_scroll.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/administrative_unit_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/location/models/area_option.dart';
import 'package:restore/modules/location/views/area_search/area_search_view.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_create/wanted_alert_create_view.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
import 'package:restore/shared/widgets/filter/app_listing_sort_sheet.dart';
import 'package:restore/shared/widgets/filter/listing_filter_labels.dart';
import 'package:restore/shared/widgets/listing/app_hot_sale_section.dart';
import 'package:restore/shared/widgets/listing/app_listing_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_grid_skeleton.dart';
import 'package:restore/shared/widgets/listing/app_listing_row_card.dart';
import 'package:restore/shared/widgets/listing/app_listing_sliver_grid.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/category_detail_cubit.dart';
import '../../bloc/category_detail_state.dart';

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
  /// Tỉnh / thành chọn nhanh: tên hiển thị → mã tỉnh, lọc ở server
  static const _quickProvinces = {
    'TP Hồ Chí Minh': '79',
    'Hà Nội': '01',
    'Đà Nẵng': '48',
  };

  /// Tên khu vực đang lọc hiện trên nút khu vực, null là toàn quốc
  String? _province;
  bool _grid = false;

  CategoryDetailCubit get _cubit => context.read<CategoryDetailCubit>();

  void _back() => context.canPop() ? context.pop() : context.go('/home');

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

  Future<void> _pickArea() async {
    final result = await context.push<AreaPickResult>(
      AreaSearchView.location(allowNationwide: true),
    );
    if (result == null || !mounted) return;
    if (result.nationwide) {
      setState(() => _province = null);
      _cubit.setArea();
    } else if (result.area case final area?) {
      setState(() => _province = area.displayName);
      final ward = area.level == AdministrativeLevel.ward;
      _cubit.setArea(
        provinceCode: ward ? null : area.code,
        wardCode: ward ? area.code : null,
      );
    }
  }

  void _toggleQuickProvince(String name) {
    final selected = _province == name ? null : name;
    setState(() => _province = selected);
    _cubit.setArea(provinceCode: _quickProvinces[selected]);
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
          province: _province,
          provinces: _quickProvinces.keys.toList(),
          grid: _grid,
          wide: widget.wide,
          onBack: _back,
          onSearch: () => context.push('/search'),
          onSaveSearch: () => context.push(
            WantedAlertCreateView.location(
              keywords: state.category?.name.of(context) ?? '',
            ),
          ),
          onArea: _pickArea,
          onProvince: _toggleQuickProvince,
          onFilters: _openFilters,
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
      final filtered = state.hasActiveFilters || _province != null;
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
                        setState(() => _province = null);
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
          _province == null &&
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

/// Đầu trang trắng của trang danh mục
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.province,
    required this.provinces,
    required this.grid,
    required this.wide,
    required this.onBack,
    required this.onSearch,
    required this.onSaveSearch,
    required this.onArea,
    required this.onProvince,
    required this.onFilters,
    required this.onSort,
    required this.onGridToggle,
  });

  final CategoryDetailState state;
  final String? province;
  final List<String> provinces;
  final bool grid;
  final bool wide;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onSaveSearch;
  final VoidCallback onArea;
  final ValueChanged<String> onProvince;
  final VoidCallback onFilters;
  final VoidCallback onSort;
  final VoidCallback onGridToggle;

  static const _chipFill = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    String t(String vn, String en) => vi ? vn : en;
    final filter = state.filter;
    final defaults = state.defaultFilter;
    final categoryName = state.category?.name.of(context);
    final active = filter.activeCount(defaults);

    Widget chip({
      required String label,
      required VoidCallback onTap,
      bool selected = false,
      IconData? leading,
      bool dropdown = false,
      VoidCallback? onClear,
    }) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.textPrimary : _chipFill,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  Icon(
                    leading,
                    size: 17,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (dropdown) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ],
                if (onClear != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      AppIcons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    Widget scrollRow(List<Widget> children) => SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: children,
      ),
    );

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
                  color: _chipFill,
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
                            tooltip: t('Lưu tìm kiếm, báo khi có hàng',
                                'Save search'),
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
        // Khu vực
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: InkWell(
            onTap: onArea,
            child: Row(
              children: [
                const Icon(
                  AppIcons.location,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  t('Khu vực: ', 'Area: '),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Flexible(
                  child: Text(
                    province ?? l10n.areaNationwide,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  AppIcons.chevronDown,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ),
        ),
        // Bộ lọc
        scrollRow([
          chip(
            label: active > 0
                ? '${l10n.listingFilterTitle} ($active)'
                : l10n.listingFilterTitle,
            leading: AppIcons.filter,
            onTap: onFilters,
          ),
          if (categoryName != null)
            chip(
              label: categoryName,
              selected: true,
              onTap: onFilters,
              onClear: onBack,
            ),
          chip(
            label: t('Giá', 'Price'),
            dropdown: true,
            selected: filter.hasPriceRange,
            onTap: onFilters,
          ),
          chip(
            label: t('Tình trạng', 'Condition'),
            dropdown: true,
            selected: filter.conditions.isNotEmpty,
            onTap: onFilters,
          ),
          for (final type in ListingDealType.values)
            chip(
              label: type.label(l10n),
              selected: filter.dealTypes.contains(type),
              onTap: () => context.read<CategoryDetailCubit>().toggleDeal(type),
            ),
        ]),
        const SizedBox(height: 10),
        // Chọn nhanh tỉnh / thành
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Center(
                child: Text(
                  t('Khu vực:', 'Area:'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              for (final name in provinces)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => onProvince(name),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: province == name
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      foregroundColor: province == name
                          ? Colors.white
                          : AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: Text(name),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 6, color: Color(0xFFF4F4F5)),
        // Sắp xếp + đổi dạng hiển thị
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              InkWell(
                onTap: onSort,
                child: Row(
                  children: [
                    Text(
                      filter.sort.label(l10n),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(AppIcons.chevronDown, size: 18),
                  ],
                ),
              ),
              const Spacer(),
              IconButton.outlined(
                tooltip: grid
                    ? t('Xem dạng danh sách', 'List view')
                    : t('Xem dạng lưới', 'Grid view'),
                onPressed: onGridToggle,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: Icon(
                  grid ? Icons.view_agenda_outlined : Icons.grid_view,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
