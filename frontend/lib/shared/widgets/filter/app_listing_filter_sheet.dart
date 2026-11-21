import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/formatters/distance_formatter.dart';
import 'package:restore/data/models/category_attribute_model.dart';
import 'package:restore/data/models/enums/listing_condition.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/bloc/listing_filter/listing_filter_cubit.dart';
import 'package:restore/shared/bloc/listing_filter/listing_filter_state.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/repositories/listing_filter_options_repository.dart';
import 'package:restore/shared/widgets/app_action_buttons.dart';
import 'package:restore/shared/widgets/glass/app_glass_sheet.dart';

import 'app_filter_bar.dart';
import 'listing_filter_category_section.dart';
import 'listing_filter_labels.dart';
import 'listing_filter_price_section.dart';
import 'listing_filter_range_section.dart';
import 'listing_filter_section.dart';

/// Mở sheet Bộ lọc đầy đủ cho các trang danh sách tin (gần bạn, kết quả
/// tìm kiếm, danh mục...): danh mục, khoảng giá, tình trạng, hình thức và
/// khoảng cách, cùng các thuộc tính của danh mục đang lọc: dạng chọn
/// (Hãng, Dung lượng...), có/không (Còn giấy tờ) và khoảng số (Năm sản xuất).
/// Thuộc tính chữ tự do (Dòng máy) đã tìm được bằng ô tìm kiếm nên không lọc. Trả về bộ lọc mới khi bấm Áp dụng, null nếu đóng sheet.
///
/// - [defaults]: bộ lọc mặc định của trang, dùng cho nút "Xoá bộ lọc".
/// - [radiusOptions]: các mức bán kính (km); null thì ẩn nhóm Khoảng cách
///   (trang không lọc theo vị trí).
/// - [showCategories]: false ở trang đã cố định một danh mục.
Future<ListingFilter?> showListingFilterSheet(
  BuildContext context, {
  required ListingFilter filter,
  required ListingFilter defaults,
  List<double>? radiusOptions,
  bool showCategories = true,
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
      ),
    ),
  );
}

class _ListingFilterSheetBody extends StatelessWidget {
  final List<double>? radiusOptions;
  final bool showCategories;

  const _ListingFilterSheetBody({
    required this.radiusOptions,
    required this.showCategories,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final cubit = context.read<ListingFilterCubit>();
    final radiusOptions = this.radiusOptions;

    return BlocBuilder<ListingFilterCubit, ListingFilterState>(
      builder: (context, state) {
        final draft = state.draft;
        final count = state.activeCount;
        final attributes = [
          for (final category in state.options.categories)
            if (category.id == draft.categoryId)
              for (final attribute in category.attributes)
                if (attribute.type != AttributeType.text &&
                    (attribute.type != AttributeType.select ||
                        attribute.options.isNotEmpty))
                  attribute,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                children: [
                  if (showCategories)
                    ListingFilterCategorySection(
                      status: state.optionsStatus,
                      categories: state.options.categories,
                      selectedId: draft.categoryId,
                      onSelected: cubit.selectCategory,
                      onRetry: cubit.loadOptions,
                    ),
                  for (final attribute in attributes)
                    _attributeSection(context, cubit, draft, attribute),
                  ListingFilterPriceSection(
                    minPrice: draft.minPrice,
                    maxPrice: draft.maxPrice,
                    presets: state.options.priceRanges,
                    isInvalid: state.isPriceInvalid,
                    onChanged: cubit.setPrice,
                  ),
                  ListingFilterSection(
                    title: l10n.listingFilterCondition,
                    child: ListingFilterChipWrap(
                      children: [
                        for (final condition in ListingCondition.values)
                          AppFilterChip(
                            label: condition.label(l10n),
                            selected: draft.conditions.contains(condition),
                            onTap: () => cubit.toggleCondition(condition),
                          ),
                      ],
                    ),
                  ),
                  ListingFilterSection(
                    title: l10n.listingFilterDeal,
                    child: ListingFilterChipWrap(
                      children: [
                        for (final type in ListingDealType.values)
                          AppFilterChip(
                            label: type.label(l10n),
                            icon: type.icon,
                            selected: draft.dealTypes.contains(type),
                            onTap: () => cubit.toggleDeal(type),
                          ),
                      ],
                    ),
                  ),
                  if (radiusOptions != null)
                    ListingFilterSection(
                      title: l10n.listingFilterDistance,
                      child: ListingFilterChipWrap(
                        children: [
                          for (final km in radiusOptions)
                            AppFilterChip(
                              label: l10n.nearbyRadiusOption(
                                DistanceFormatter.format(
                                  km,
                                  l10n,
                                  locale: locale,
                                ),
                              ),
                              selected: draft.radiusKm == km,
                              onTap: () => cubit.setRadius(km),
                            ),
                        ],
                      ),
                    ),
                ],
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
                      onPressed: state.isInvalid
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

  /// Một nhóm lọc theo thuộc tính: chip cho dạng chọn và có/không, ô Từ/Đến
  /// cho dạng số. Có/không chỉ có chip "Có" vì tin không khai thường để trống.
  Widget _attributeSection(
    BuildContext context,
    ListingFilterCubit cubit,
    ListingFilter draft,
    CategoryAttributeModel attribute,
  ) {
    final key = attribute.key;
    if (attribute.type == AttributeType.number) {
      final range = draft.attributeRanges[key];
      return ListingFilterRangeSection(
        key: ValueKey('range-$key'),
        title: attribute.label.of(context),
        unit: attribute.unit?.of(context),
        min: range?.min,
        max: range?.max,
        onChanged: ({required min, required max}) =>
            cubit.setAttributeRange(key, min: min, max: max),
      );
    }
    final selected = draft.attributes[key] ?? const <String>{};
    final options = attribute.type == AttributeType.boolean
        ? [(value: 'true', label: AppLocalizations.of(context)!.yes)]
        : [
            for (final option in attribute.options)
              (value: option.value, label: option.label.of(context)),
          ];
    return ListingFilterSection(
      title: attribute.label.of(context),
      child: ListingFilterChipWrap(
        children: [
          for (final option in options)
            AppFilterChip(
              label: option.label,
              selected: selected.contains(option.value),
              onTap: () => cubit.toggleAttribute(key, option.value),
            ),
        ],
      ),
    );
  }
}
