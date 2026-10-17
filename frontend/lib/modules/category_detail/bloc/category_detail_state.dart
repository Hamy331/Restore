import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

enum CategoryDetailStatus {
  /// Đang tải trang đầu (lần đầu hoặc vừa đổi bộ lọc)
  loading,
  ready,
  failure,
}

class CategoryDetailState extends Equatable {
  /// Cách sắp xếp trang hỗ trợ (không có từ khoá và vị trí nên bỏ
  /// "Phù hợp nhất" và "Gần nhất")
  static const List<ListingSort> sortOptions = [
    ListingSort.newest,
    ListingSort.priceLow,
    ListingSort.priceHigh,
  ];

  final String categoryId;

  /// null khi mở bằng đường dẫn và chưa tải xong thông tin danh mục
  final CategoryModel? category;
  final CategoryDetailStatus status;
  final ListingFilter filter;
  final List<ListingCardItem> items;

  /// Trang cuối đã tải của [items]
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  CategoryDetailState({
    required this.categoryId,
    this.category,
    this.status = CategoryDetailStatus.loading,
    ListingFilter? filter,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  }) : filter = filter ?? defaultFilterFor(categoryId);

  /// Bộ lọc mặc định: khoá danh mục của trang, tin mới nhất trước
  static ListingFilter defaultFilterFor(String categoryId) =>
      ListingFilter(categoryId: categoryId);

  ListingFilter get defaultFilter => defaultFilterFor(categoryId);

  /// Đang bật tiêu chí nào ngoài danh mục của trang
  bool get hasActiveFilters => filter.activeCount(defaultFilter) > 0;

  CategoryDetailState copyWith({
    CategoryModel? category,
    CategoryDetailStatus? status,
    ListingFilter? filter,
    List<ListingCardItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => CategoryDetailState(
    categoryId: categoryId,
    category: category ?? this.category,
    status: status ?? this.status,
    filter: filter ?? this.filter,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    categoryId,
    category,
    status,
    filter,
    items,
    page,
    hasMore,
    isLoadingMore,
  ];
}
