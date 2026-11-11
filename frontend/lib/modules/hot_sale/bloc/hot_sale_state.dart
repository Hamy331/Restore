import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/listing_card_item.dart';

enum HotSaleStatus { loading, ready, failure }

class HotSaleState extends Equatable {
  const HotSaleState({
    this.status = HotSaleStatus.loading,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final HotSaleStatus status;
  final List<ListingCardItem> items;

  /// Trang cuối đã tải
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  HotSaleState copyWith({
    HotSaleStatus? status,
    List<ListingCardItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => HotSaleState(
    status: status ?? this.status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [status, items, page, hasMore, isLoadingMore];
}
