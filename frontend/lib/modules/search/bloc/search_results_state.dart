import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

enum SearchResultsStatus {
  /// Đang tải trang đầu (lần đầu hoặc vừa đổi bộ lọc)
  loading,
  ready,
  failure,
}

class SearchResultsState extends Equatable {
  /// Cách sắp xếp trang hỗ trợ (chưa có "Gần nhất" vì không dùng vị trí)
  static const List<ListingSort> sortOptions = [
    ListingSort.relevance,
    ListingSort.newest,
    ListingSort.priceLow,
    ListingSort.priceHigh,
  ];

  static const ListingFilter defaultFilter = ListingFilter(
    sort: ListingSort.relevance,
  );

  final String query;
  final SearchResultsStatus status;
  final ListingFilter filter;
  final List<ListingCardItem> items;

  /// Trang cuối đã tải của [items]
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const SearchResultsState({
    required this.query,
    this.status = SearchResultsStatus.loading,
    this.filter = defaultFilter,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  SearchResultsState copyWith({
    SearchResultsStatus? status,
    ListingFilter? filter,
    List<ListingCardItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => SearchResultsState(
    query: query,
    status: status ?? this.status,
    filter: filter ?? this.filter,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    query,
    status,
    filter,
    items,
    page,
    hasMore,
    isLoadingMore,
  ];
}
