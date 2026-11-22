import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_scroll.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/listings/models/create_listing_step.dart';
import 'package:restore/modules/location/utils/listing_area.dart';
import 'package:restore/modules/wanted_alert/views/wanted_alert_create/wanted_alert_create_view.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/widgets/desktop/desktop_layout.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/widgets/filter/app_listing_filter_sheet.dart';
import 'package:restore/shared/widgets/filter/filter_popover.dart';
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
import 'category_detail_view.dart';
import 'widgets/category_picker_sheet.dart';

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
  /// Tỉnh / thành chọn nhanh trên hàng "Khu vực:" (tên → mã tỉnh), lọc ở
  /// server. 5 thành phố trực thuộc trung ương theo danh sách 34 tỉnh mới.
  static const _quickProvinces = {
    'TP. Hồ Chí Minh': '79',
    'Hà Nội': '01',
    'Đà Nẵng': '48',
    'Hải Phòng': '31',
    'Cần Thơ': '92',
  };
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

  ListingFilter get _filter => _cubit.state.filter;

  /// Danh mục đã gộp danh mục con đang chọn (bộ lọc riêng, giá tối đa...)
  CategoryModel? get _merged =>
      _cubit.state.category?.withSubcategory(_filter.subcategoryId);

  /// Bảng chọn trong danh sách (radio / checkbox), trả tập giá trị đã chọn
  Future<Set<T>?> _choose<T>(
    BuildContext anchor,
    String title,
    List<FilterChoice<T>> choices,
    Set<T> selected, {
    bool multiple = false,
  }) => showFilterPopover<Set<T>>(
    anchor,
    builder: (_) => FilterChoicePanel<T>(
      title: title,
      choices: choices,
      selected: selected,
      multiple: multiple,
    ),
  );

  /// Chip "Giá ▾": thanh trượt tới giá tối đa của danh mục con + hai ô nhập
  Future<void> _pickPrice(BuildContext anchor) async {
    final l10n = AppLocalizations.of(context)!;
    final range = await showFilterPopover<FilterRange>(
      anchor,
      builder: (_) => FilterRangePanel(
        min: _filter.minPrice,
        max: _filter.maxPrice,
        top: _merged?.priceMax,
        money: true,
        minLabel: l10n.listingFilterPriceMin,
        maxLabel: l10n.listingFilterPriceMax,
      ),
    );
    if (range == null || !mounted) return;
    _cubit.applyFilter(
      _filter.copyWith(
        minPrice: () => range.min?.toInt(),
        maxPrice: () => range.max?.toInt(),
      ),
    );
  }

  /// Chip bộ lọc riêng ("Hãng ▾", "Dung lượng ▾"...) theo ux_type
  Future<void> _pickAttribute(
    BuildContext anchor,
    CategoryAttributeModel attribute,
  ) async {
    final label = attribute.label.of(context);
    final current = _filter.attributeFilters[attribute.key];
    if (attribute.filter == AttributeFilterKind.range) {
      final range = await showFilterPopover<FilterRange>(
        anchor,
        builder: (_) => FilterRangePanel(
          title: label,
          min: current?.min,
          max: current?.max,
          unit: attribute.unit?.of(context),
        ),
      );
      if (range == null || !mounted) return;
      _cubit.applyFilter(
        _filter.withAttribute(
          attribute.key,
          AttributeFilterValue(min: range.min, max: range.max),
        ),
      );
      return;
    }
    final values = await _choose(
      anchor,
      label,
      [
        for (final option in attribute.options)
          (value: option.value, label: option.label.of(context)),
      ],
      current?.values ?? const <String>{},
      multiple: attribute.filter == AttributeFilterKind.multi,
    );
    if (values == null || !mounted) return;
    _cubit.applyFilter(
      _filter.withAttribute(
        attribute.key,
        AttributeFilterValue(values: values),
      ),
    );
  }

  void _clearAttribute(String key) => _cubit.applyFilter(
    _filter.withAttribute(key, const AttributeFilterValue()),
  );

  /// Chip "Tình trạng ▾": theo nhóm (Điện tử có thêm Còn bảo hành)
  Future<void> _pickCondition(BuildContext anchor) async {
    final l10n = AppLocalizations.of(context)!;
    final groups = ListingConditionGroup.available(
      warranty: _merged?.hasWarranty ?? false,
    );
    final picked = await _choose(
      anchor,
      l10n.listingFilterCondition,
      [for (final group in groups) (value: group, label: group.label(l10n))],
      {?_filter.conditionGroup},
    );
    if (picked == null || !mounted) return;
    _cubit.applyFilter(_filter.withConditionGroup(picked.firstOrNull));
  }

  /// Chip "Đăng bởi ▾": chọn nhiều Cá nhân / Bán chuyên / Đối tác
  Future<void> _pickSeller(BuildContext anchor) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await _choose(
      anchor,
      l10n.listingFilterSeller,
      [
        for (final kind in ListingSellerKind.values)
          (value: kind, label: kind.label(l10n)),
      ],
      _filter.sellers,
      multiple: true,
    );
    if (picked == null || !mounted) return;
    _cubit.applyFilter(_filter.copyWith(sellers: picked));
  }

  /// Chip danh mục: chọn danh mục con hoặc chuyển sang danh mục khác
  Future<void> _pickCategory(BuildContext anchor) async {
    final category = _cubit.state.category;
    if (category == null) return;
    final pick = await showCategoryPicker(
      anchor,
      category: category,
      subcategoryId: _filter.subcategoryId,
    );
    if (pick == null || !mounted) return;
    if (pick.categoryId == category.id) {
      _cubit.selectSubcategory(pick.subcategoryId);
    } else {
      context.pushReplacement(CategoryDetailView.location(pick.categoryId));
    }
  }

  Future<void> _pickSort() async {
    final sort = await showListingSortSheet(
      context,
      selected: _cubit.state.filter.sort,
      options: CategoryDetailState.sortOptions,
    );
    if (sort != null) _cubit.setSort(sort);
  }

  /// Chọn khu vực (kể cả "Gần tôi"), đổi luôn khu vực của cả app
  Future<void> _pickArea() async {
    final filter = await pickListingArea(context, _cubit.state.filter);
    if (filter != null && mounted) _cubit.applyFilter(filter);
  }

  /// Chip tỉnh nhanh: chỉ lọc trang này, bấm lại để bỏ
  void _toggleQuickProvince(String name) {
    final filter = _cubit.state.filter;
    _cubit.applyFilter(
      // So theo mã: nhãn từ trang chọn khu vực có thể khác ("Hồ Chí Minh")
      filter.provinceCode == _quickProvinces[name]
          ? filter.withArea(null)
          : filter.withArea(_quickProvinces[name], label: name),
    );
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
          province: state.filter.areaLabel,
          provinces: _quickProvinces,
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
          onCategoryTap: _pickCategory,
          onSubcategory: _cubit.selectSubcategory,
          onPrice: _pickPrice,
          onAttribute: _pickAttribute,
          onAttributeClear: _clearAttribute,
          onCondition: _pickCondition,
          onSeller: _pickSeller,
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
    required this.onFilters,
    required this.onCategoryTap,
    required this.onSubcategory,
    required this.onPrice,
    required this.onAttribute,
    required this.onAttributeClear,
    required this.onCondition,
    required this.onSeller,
    required this.onClearAll,
    required this.onProvince,
    required this.onSort,
    required this.onGridToggle,
  });

  final CategoryDetailState state;
  final String? province;

  /// Chip tỉnh nhanh: tên → mã tỉnh
  final Map<String, String> provinces;
  final bool grid;
  final bool wide;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onSaveSearch;
  final VoidCallback onArea;
  final VoidCallback onFilters;
  final ValueChanged<BuildContext> onCategoryTap;
  final ValueChanged<String?> onSubcategory;

  /// Các chip "▾" mở popover ngay dưới chip ([BuildContext] của chip)
  final ValueChanged<BuildContext> onPrice;
  final void Function(BuildContext anchor, CategoryAttributeModel attribute)
  onAttribute;
  final ValueChanged<String> onAttributeClear;
  final ValueChanged<BuildContext> onCondition;
  final ValueChanged<BuildContext> onSeller;
  final VoidCallback onClearAll;
  final ValueChanged<String> onProvince;
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
    final category = state.category;
    final categoryName = category?.name.of(context);
    final active = filter.activeCount(defaults);
    // Danh mục đã gộp danh mục con đang chọn: bộ lọc riêng (Hãng, Dung
    // lượng...) thành chip "▾" trên thanh lọc
    final merged = category?.withSubcategory(filter.subcategoryId);
    final filterAttributes = merged?.filterAttributes ?? const [];

    Widget chip({
      required String label,
      required ValueChanged<BuildContext> onTap,
      bool selected = false,
      IconData? leading,
      bool dropdown = false,
      VoidCallback? onClear,
    }) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.textPrimary : _chipFill,
        shape: const StadiumBorder(),
        child: Builder(
          builder: (chipContext) => InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => onTap(chipContext),
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
      ),
    );

    // Hãng đã chọn thành chip riêng "Apple ×" cạnh danh mục
    final brand = filterAttributes
        .where((item) => item.key == 'brand')
        .firstOrNull;
    final brandValues = filter.attributeFilters['brand']?.values ?? const {};
    final brandChip = brand != null && brandValues.length == 1
        ? brand.optionOf(brandValues.first)
        : null;

    Widget scrollRow(List<Widget> children) => SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: children,
      ),
    );

    // Chip tròn của hàng "Khu vực:"; đang chọn thì nền đậm chữ trắng
    Widget areaChip(
      String name, {
      required bool selected,
      required VoidCallback onPressed,
    }) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          backgroundColor: selected
              ? AppColors.textPrimary
              : Colors.transparent,
          foregroundColor: selected ? Colors.white : AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(name),
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
        // Thanh lọc: Lọc · danh mục đang xem (bấm để đổi danh mục
        // con) · Giá · bộ lọc riêng của danh mục con · Tình trạng · Đăng bởi.
        // Mỗi chip ▾ mở riêng mục đó.
        scrollRow([
          chip(
            label: active > 0
                ? '${l10n.listingFilterButton} ($active)'
                : l10n.listingFilterButton,
            leading: AppIcons.filter,
            selected: active > 0,
            onTap: (_) => onFilters(),
          ),
          if (categoryName != null)
            chip(
              label: merged?.subcategory?.name.of(context) ?? categoryName,
              selected: true,
              dropdown: category?.hasSubcategories ?? false,
              onTap: onCategoryTap,
              // Bỏ danh mục con thì về cả danh mục; đang ở cả danh mục thì thoát
              onClear: filter.subcategoryId != null
                  ? () => onSubcategory(null)
                  : onBack,
            ),
          if (brandChip != null)
            chip(
              label: brandChip.label.of(context),
              selected: true,
              onTap: (anchor) => onAttribute(anchor, brand!),
              onClear: () => onAttributeClear('brand'),
            ),
          chip(
            label: t('Giá', 'Price'),
            dropdown: true,
            selected: filter.hasPriceRange,
            onTap: onPrice,
          ),
          for (final attribute in filterAttributes)
            if (brandChip == null || attribute.key != 'brand')
              chip(
                label: attribute.label.of(context),
                dropdown: true,
                selected: filter.attributeFilters.containsKey(attribute.key),
                onTap: (anchor) => onAttribute(anchor, attribute),
              ),
          if (merged?.hasCondition ?? true)
            chip(
              label: l10n.listingFilterCondition,
              dropdown: true,
              selected: filter.conditionGroup != null,
              onTap: onCondition,
            ),
          chip(
            label: l10n.listingFilterSeller,
            dropdown: true,
            selected: filter.sellers.isNotEmpty,
            onTap: onSeller,
          ),
          if (active > 0)
            TextButton(
              onPressed: onClearAll,
              child: Text(
                l10n.filterClear,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        // Hàng "Khu vực:": vài tỉnh / thành chọn nhanh + Xem thêm
        scrollRow([
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                t('Khu vực:', 'Area:'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          // Khu vực chọn từ "Xem thêm" (không nằm trong chip nhanh) hiện đầu
          // hàng, bấm để chọn lại
          if (filter.hasArea &&
              !provinces.containsValue(filter.provinceCode) &&
              province != null)
            areaChip(province!, selected: true, onPressed: onArea),
          for (final MapEntry(key: name, value: code) in provinces.entries)
            areaChip(
              name,
              selected: filter.provinceCode == code,
              onPressed: () => onProvince(name),
            ),
          OutlinedButton(
            onPressed: onArea,
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(t('Xem thêm', 'More')),
          ),
        ]),
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
