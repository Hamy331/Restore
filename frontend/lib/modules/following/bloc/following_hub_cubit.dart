import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/account/repositories/profile_repository.dart';
import 'package:restore/modules/feeds/models/feed_models.dart';
import 'package:restore/modules/feeds/repositories/feeds_repository.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/modules/trusted_shop/repositories/shop_following_repository.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/paged_result.dart';

import 'following_hub_state.dart';

/// Trang "Đang theo dõi" (lối tắt ở trang chủ): tin mới của shop đang theo
/// dõi, lọc theo từng shop, người đang theo dõi và gợi ý shop. Chưa theo
/// dõi shop nào thì là màn gợi ý.
class FollowingHubCubit extends Cubit<FollowingHubState> {
  FollowingHubCubit(
    this._shops, {
    ProfileRepository? profiles,
    FeedsRepository? feeds,
  }) : _profiles = profiles,
       _feeds = feeds,
       super(const FollowingHubState());

  /// Số bài đăng của người mình theo dõi hiện trên trang
  static const int postCount = 6;

  final ShopFollowingRepository _shops;

  /// Null thì bỏ qua khu "Người bạn theo dõi"
  final ProfileRepository? _profiles;

  /// Null thì bỏ qua khu bài đăng của người mình theo dõi
  final FeedsRepository? _feeds;
  final Set<String> _pending = {};

  /// Tăng mỗi lần tải lưới tin để bỏ kết quả về muộn
  int _requestId = 0;

  @override
  void emit(FollowingHubState state) {
    if (!isClosed) super.emit(state);
  }

  /// [showLoading] false khi kéo để làm mới. Giữ shop đang lọc nếu vẫn còn
  /// theo dõi.
  Future<void> load({bool showLoading = true}) async {
    if (showLoading) emit(state.copyWith(status: FollowingHubStatus.loading));
    final requestId = ++_requestId;
    try {
      final (shops, suggestions, people, posts) = await (
        _shops.followedShops(),
        _shops.suggestions().catchError((_) => const <ShopSuggestion>[]),
        _loadPeople(),
        _loadPosts(),
      ).wait;
      final selected = shops.items.any((s) => s.id == state.selectedShopId)
          ? state.selectedShopId
          : null;
      final listings = shops.items.isEmpty
          ? const PagedResult<ListingCardItem>.empty()
          : await _listings(selected, 1);
      if (requestId != _requestId) return;
      emit(
        FollowingHubState(
          status: FollowingHubStatus.ready,
          shops: shops.items,
          shopTotal: shops.totalItems ?? shops.items.length,
          people: people?.items ?? const [],
          peopleTotal: people?.total ?? 0,
          myId: people?.myId,
          suggestions: suggestions,
          posts: posts,
          selectedShopId: selected,
          listings: listings.items,
          page: listings.page,
          hasMore: listings.hasMore,
        ),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      if (showLoading || state.status != FollowingHubStatus.ready) {
        emit(state.copyWith(status: FollowingHubStatus.failure));
      }
    }
  }

  Future<({List<FollowUser> items, int total, String myId})?>
  _loadPeople() async {
    final profiles = _profiles;
    if (profiles == null) return null;
    try {
      final me = await profiles.getMe();
      final page = await profiles.follows(me.id, FollowListKind.following);
      return (items: page.items, total: me.followingCount, myId: me.id);
    } catch (_) {
      return null;
    }
  }

  /// Lỗi bảng tin không làm hỏng cả trang, chỉ ẩn khu bài đăng
  Future<List<FeedPost>> _loadPosts() async {
    final feeds = _feeds;
    if (feeds == null) return const [];
    try {
      final page = await feeds.posts(following: true);
      return page.items.take(postCount).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<PagedResult<ListingCardItem>> _listings(String? shopId, int page) =>
      shopId == null
      ? _shops.followedListings(page: page)
      : _shops.shopListings(shopId, page: page);

  /// Lọc lưới tin theo shop [shopId], null là mọi shop
  Future<void> selectShop(String? shopId) async {
    if (shopId == state.selectedShopId) return;
    final requestId = ++_requestId;
    emit(
      state.copyWith(
        selectedShopId: () => shopId,
        isLoadingListings: true,
        isLoadingMore: false,
      ),
    );
    try {
      final result = await _listings(shopId, 1);
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          listings: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingListings: false,
        ),
      );
    } catch (_) {
      if (requestId == _requestId) {
        emit(state.copyWith(isLoadingListings: false));
      }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.isLoadingListings ||
        state.status != FollowingHubStatus.ready) {
      return;
    }
    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _listings(state.selectedShopId, state.page + 1);
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          listings: [...state.listings, ...result.items],
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId == _requestId) emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// Theo dõi / bỏ theo dõi một shop gợi ý ngay trên thẻ
  Future<void> toggleSuggestion(ShopSuggestion suggestion) async {
    if (!_pending.add(suggestion.id)) return;
    final following = !suggestion.item.isFollowing;
    syncSuggestion(suggestion.id, following);
    try {
      await _shops.setFollowing(suggestion.id, following);
    } catch (_) {
      syncSuggestion(suggestion.id, !following);
    } finally {
      _pending.remove(suggestion.id);
    }
  }

  /// Cập nhật thẻ gợi ý khi đổi theo dõi ở nơi khác (VD trang của shop)
  void syncSuggestion(String shopId, bool following) => emit(
    state.copyWith(
      suggestions: [
        for (final s in state.suggestions)
          s.id == shopId ? s.withFollowing(following) : s,
      ],
    ),
  );

  Future<void> toggleFavorite(ListingCardItem item) async {
    final id = item.listing.id;
    final favorite = !item.isFavorite;
    syncFavorite(id, favorite);
    try {
      await _shops.setFavorite(id, favorite);
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
