import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/listing_card_item.dart';

import '../../models/followed_shop.dart';

enum FollowingFeedStatus { loading, ready, failure }

class FollowingFeedState extends Equatable {
  const FollowingFeedState({
    this.status = FollowingFeedStatus.loading,
    this.shops = const [],
    this.shopTotal = 0,
    this.listings = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final FollowingFeedStatus status;

  /// Trang đầu các shop đang theo dõi, hiện thành một dải ở đầu trang
  final List<FollowedShop> shops;
  final int shopTotal;

  /// Tin mới nhất của các shop đó
  final List<ListingCardItem> listings;
  final int page;
  final bool hasMore, isLoadingMore;

  FollowingFeedState copyWith({
    FollowingFeedStatus? status,
    List<FollowedShop>? shops,
    int? shopTotal,
    List<ListingCardItem>? listings,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => FollowingFeedState(
    status: status ?? this.status,
    shops: shops ?? this.shops,
    shopTotal: shopTotal ?? this.shopTotal,
    listings: listings ?? this.listings,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    status,
    shops,
    shopTotal,
    listings,
    page,
    hasMore,
    isLoadingMore,
  ];
}
