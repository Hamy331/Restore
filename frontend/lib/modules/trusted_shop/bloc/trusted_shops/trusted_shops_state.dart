import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../../models/trusted_shops_overview.dart';

enum TrustedShopsStatus {
  /// Đang tải trang lần đầu (hoặc thử lại sau lỗi)
  loading,
  ready,
  failure,
}

class TrustedShopsState extends Equatable {
  /// Cách sắp xếp lưới "Tất cả sản phẩm"
  static const List<ListingSort> sortOptions = [
    ListingSort.newest,
    ListingSort.priceLow,
    ListingSort.priceHigh,
  ];

  final TrustedShopsStatus status;

  final TrustedShopsOverview overview;

  /// Bộ lọc lưới "Tất cả sản phẩm": danh mục (null là "Tất cả"), chỉ tin
  /// đang giảm giá và cách sắp xếp
  final String? categoryId;
  final bool onSale;
  final ListingSort sort;

  /// Lưới "Tất cả sản phẩm"
  final List<ListingCardItem> products;

  /// Trang cuối đã tải của [products]
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Đang tải lại riêng lưới sản phẩm (vừa đổi bộ lọc)
  final bool isLoadingProducts;

  const TrustedShopsState({
    this.status = TrustedShopsStatus.loading,
    this.overview = const TrustedShopsOverview(),
    this.categoryId,
    this.onSale = false,
    this.sort = ListingSort.newest,
    this.products = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isLoadingProducts = false,
  });

  /// Bộ lọc gửi API cho lưới sản phẩm
  ListingFilter get filter => ListingFilter(categoryId: categoryId, sort: sort);

  /// Các trường có thể null nhận hàm trả giá trị để xoá được về null
  TrustedShopsState copyWith({
    TrustedShopsStatus? status,
    TrustedShopsOverview? overview,
    String? Function()? categoryId,
    bool? onSale,
    ListingSort? sort,
    List<ListingCardItem>? products,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isLoadingProducts,
  }) => TrustedShopsState(
    status: status ?? this.status,
    overview: overview ?? this.overview,
    categoryId: categoryId == null ? this.categoryId : categoryId(),
    onSale: onSale ?? this.onSale,
    sort: sort ?? this.sort,
    products: products ?? this.products,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
  );

  @override
  List<Object?> get props => [
    status,
    overview,
    categoryId,
    onSale,
    sort,
    products,
    page,
    hasMore,
    isLoadingMore,
    isLoadingProducts,
  ];
}
