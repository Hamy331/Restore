import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/shared/models/listing_filter.dart';
import 'package:restore/shared/models/listing_filter_options.dart';

enum ListingFilterOptionsStatus { loading, ready, failure }

class ListingFilterState extends Equatable {
  /// Bộ lọc đang chỉnh trong sheet, chỉ trả về trang khi bấm Áp dụng
  final ListingFilter draft;

  /// Bộ lọc mặc định của trang, dùng khi bấm "Xoá bộ lọc" và để đếm
  final ListingFilter defaults;
  final ListingFilterOptionsStatus optionsStatus;
  final ListingFilterOptions options;

  const ListingFilterState({
    required this.draft,
    required this.defaults,
    this.optionsStatus = ListingFilterOptionsStatus.loading,
    this.options = const ListingFilterOptions(),
  });

  int get activeCount => draft.activeCount(defaults);

  /// Giá thấp nhất lớn hơn giá cao nhất thì chưa cho áp dụng
  bool get isPriceInvalid {
    final min = draft.minPrice;
    final max = draft.maxPrice;
    return min != null && max != null && min > max;
  }

  /// Có khoảng (giá hoặc thuộc tính số) đầu dưới lớn hơn đầu trên
  bool get hasInvalidRange =>
      isPriceInvalid ||
      draft.attributeFilters.values.any(
        (value) =>
            value.min != null && value.max != null && value.min! > value.max!,
      );

  /// Danh mục đang lọc (null khi chưa chọn hoặc danh mục chưa tải xong)
  CategoryModel? get selectedCategory {
    for (final category in options.categories) {
      if (category.id == draft.categoryId) return category;
    }
    return null;
  }

  ListingFilterState copyWith({
    ListingFilter? draft,
    ListingFilterOptionsStatus? optionsStatus,
    ListingFilterOptions? options,
  }) => ListingFilterState(
    draft: draft ?? this.draft,
    defaults: defaults,
    optionsStatus: optionsStatus ?? this.optionsStatus,
    options: options ?? this.options,
  );

  @override
  List<Object?> get props => [draft, defaults, optionsStatus, options];
}
