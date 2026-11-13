import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/shared/models/listing_card_item.dart';

import '../../repositories/shop_following_repository.dart';
import 'following_feed_state.dart';

/// Trang "Shop bạn theo dõi": dải shop đang theo dõi và tin mới của họ
class FollowingFeedCubit extends Cubit<FollowingFeedState> {
  FollowingFeedCubit(this._repository) : super(const FollowingFeedState());

  final ShopFollowingRepository _repository;

  @override
  void emit(FollowingFeedState state) {
    if (!isClosed) super.emit(state);
  }

  /// [showLoading] false khi kéo để làm mới: giữ nội dung cũ tới khi có mới
  Future<void> load({bool showLoading = true}) async {
    if (showLoading) emit(const FollowingFeedState());
    try {
      final (shops, listings) = await (
        _repository.followedShops(),
        _repository.followedListings(),
      ).wait;
      emit(
        FollowingFeedState(
          status: FollowingFeedStatus.ready,
          shops: shops.items,
          shopTotal: shops.totalItems ?? shops.items.length,
          listings: listings.items,
          page: listings.page,
          hasMore: listings.hasMore,
        ),
      );
    } catch (_) {
      if (showLoading || state.status != FollowingFeedStatus.ready) {
        emit(state.copyWith(status: FollowingFeedStatus.failure));
      }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.status != FollowingFeedStatus.ready) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.followedListings(page: state.page + 1);
      emit(
        state.copyWith(
          listings: [...state.listings, ...result.items],
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> toggleFavorite(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = !item.isFavorite;
    syncFavorite(id, favorite);
    try {
      await _repository.setFavorite(id, favorite);
    } catch (_) {
      syncFavorite(id, !favorite);
    }
  }

  void syncFavorite(String listingId, bool favorite) => emit(
    state.copyWith(
      listings: [
        for (final item in state.listings)
          item.listing.id == listingId
              ? item.copyWith(isFavorite: favorite)
              : item,
      ],
    ),
  );
}
