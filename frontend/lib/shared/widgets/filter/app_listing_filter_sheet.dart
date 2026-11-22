import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/distance_formatter.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/bloc/listing_filter/listing_filter_cubit.dart';
import 'package:restore/shared/bloc/listing_filter/listing_filter_state.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/repositories/listing_filter_options_repository.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

import 'app_filter_bar.dart';
import 'listing_filter_attribute_sections.dart';
import 'listing_filter_category_section.dart';
import 'listing_filter_labels.dart';
import 'listing_filter_price_section.dart';
import 'listing_filter_section.dart';

/// Mở sheet Bộ lọc cho các trang danh sách tin (danh mục, tìm kiếm, gần
/// bạn...), gồm: danh mục, loại (danh mục con),
/// khoảng giá, bộ lọc riêng của danh mục con theo ux_type (chip chọn một /
/// chọn nhiều, danh sách có ô tìm, khoảng số), tình trạng theo nhóm, đăng bởi
/// và khoảng cách. Trả về bộ lọc mới khi bấm Áp dụng, null nếu đóng sheet.
///
/// - [defaults]: bộ lọc mặc định của trang, dùng cho nút "Xoá bộ lọc".
/// - [radiusOptions]: các mức bán kính (km); null thì ẩn nhóm Khoảng cách.
/// - [showCategories]: false ở trang đã cố định một danh mục.
///
/// Từng mục riêng (chip "Giá ▾", "Hãng ▾"...) mở bằng popover trong
/// filter_popover.dart.
Future<ListingFilter?> showListingFilterSheet(
  BuildContext context, {
  required ListingFilter filter,
  required ListingFilter defaults,
  List<double>? radiusOptions,
  bool showCategories = true,
  bool subcategories = true,
  bool attributes = true,
  bool showSeller = true,
  ListingFilterOptionsRepository? repository,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showAppGlassSheet<ListingFilter>(
    context,
    title: l10n.listingFilterTitle,
    icon: AppIcons.filter,
    heightFactor: 0.88,
    builder: (_) => BlocProvider(
      create: (_) => ListingFilterCubit(
        repository:
            repository ??
            (AppEnvironment.useMockData
                ? MockListingFilterOptionsRepository()
                : ApiListingFilterOptionsRepository()),
        initial: filter,
        defaults: defaults,
      )..loadOptions(),
      child: _ListingFilterSheetBody(
        radiusOptions: radiusOptions,
        showCategories: showCategories,
        subcategories: subcategories,
        attributes: attributes,
        showSeller: showSeller,
      ),
    ),
  );
}

class _ListingFilterSheetBody extends StatelessWidget {
  final List<double>? radiusOptions;
  final bool showCategories;

  /// false: không có danh mục con, bộ lọc riêng và "Còn bảo hành"
  final bool subcategories;

  /// false: có danh mục con nhưng không có bộ lọc riêng và "Còn bảo hành"
  /// (Báo khi có hàng lưu danh mục con, chưa lưu được thuộc tính)
  final bool attributes;
  final bool showSeller;

  const _ListingFilterSheetBody({
    required this.radiusOptions,
    required this.showCategories,
    required this.subcategories,
    required this.attributes,
    required this.showSeller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ListingFilterCubit>();

    return BlocBuilder<ListingFilterCubit, ListingFilterState>(
      builder: (context, state) {
        final draft = state.draft;
        final count = state.activeCount;
        final parent = state.selectedCategory;
        // Danh mục đã gộp danh mục con: bộ lọc riêng, tình trạng, giá tối đa
        final category = subcategories
            ? parent?.withSubcategory(draft.subcategoryId)
            : null;
        final sections = _sections(context, state, parent, category);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                children: sections,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryActionButton(
                      label: l10n.listingFilterReset,
                      onPressed: count == 0 ? null : cubit.reset,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppPrimaryActionButton(
                      label: count == 0
                          ? l10n.listingFilterApply
                          : l10n.listingFilterApplyCount(count),
                      onPressed: state.hasInvalidRange
                          ? null
                          : () => Navigator.of(context).pop(draft),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _sections(
    BuildContext context,
    ListingFilterState state,
    CategoryModel? parent,
    CategoryModel? category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final cubit = context.read<ListingFilterCubit>();
    final draft = state.draft;

    final subcategoryRow =
        subcategories && parent != null && parent.hasSubcategories
        ? ListingFilterSubcategorySection(
            category: parent,
            selectedId: draft.subcategoryId,
            onSelected: cubit.selectSubcategory,
          )
        : null;
    final price = ListingFilterPriceSection(
      minPrice: draft.minPrice,
      maxPrice: draft.maxPrice,
      presets: state.options.priceRanges,
      isInvalid: state.isPriceInvalid,
      priceMax: category?.priceMax,
      onChanged: cubit.setPrice,
    );

    // Tình trạng theo nhóm: Điện tử có "Còn bảo hành"; danh mục
    // không hỏi tình trạng (thú cưng) thì ẩn
    final groups = ListingConditionGroup.available(
      warranty: attributes && (category?.hasWarranty ?? false),
    );
    final condition = (category?.hasCondition ?? true)
        ? ListingFilterSection(
            title: l10n.listingFilterCondition,
            child: ListingFilterChipWrap(
              children: [
                for (final group in groups)
                  AppFilterChip(
                    label: group.label(l10n),
                    selected: draft.conditionGroup == group,
                    onTap: () => cubit.selectConditionGroup(group),
                  ),
              ],
            ),
          )
        : null;
    final seller = ListingFilterSection(
      title: l10n.listingFilterSeller,
      child: ListingFilterChipWrap(
        children: [
          for (final kind in ListingSellerKind.values)
            AppFilterChip(
              label: kind.label(l10n),
              selected: draft.sellers.contains(kind),
              onTap: () => cubit.toggleSeller(kind),
            ),
        ],
      ),
    );

    final radiusOptions = this.radiusOptions;
    return [
      if (showCategories)
        ListingFilterCategorySection(
          status: state.optionsStatus,
          categories: state.options.categories,
          selectedId: draft.categoryId,
          onSelected: cubit.selectCategory,
          onRetry: cubit.loadOptions,
        ),
      ?subcategoryRow,
      price,
      if (attributes && category != null)
        ListingFilterAttributeSections(
          category: category,
          values: draft.attributeFilters,
          onToggle: cubit.toggleAttributeValue,
          onSelect: cubit.selectAttributeValue,
          onRange: cubit.setAttributeRange,
        ),
      ?condition,
      if (showSeller) seller,
      if (radiusOptions != null)
        ListingFilterSection(
          title: l10n.listingFilterDistance,
          child: ListingFilterChipWrap(
            children: [
              for (final km in radiusOptions)
                AppFilterChip(
                  label: l10n.nearbyRadiusOption(
                    DistanceFormatter.format(km, l10n, locale: locale),
                  ),
                  selected: draft.radiusKm == km,
                  onTap: () => cubit.setRadius(km),
                ),
            ],
          ),
        ),
    ];
  }
}
