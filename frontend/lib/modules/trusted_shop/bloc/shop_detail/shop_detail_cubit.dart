import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../../models/trusted_shop_item.dart';
import '../../repositories/trusted_shop_repository.dart';
import 'shop_detail_state.dart';

/// Trang của một shop uy tín: hồ sơ, chứng nhận và các tin đang bán
class ShopDetailCubit extends Cubit<ShopDetailState> {
  ShopDetailCubit({
    required TrustedShopRepository repository,
    required String shopId,
    TrustedShopItem? shop,
  }) : _repository = repository,
       super(ShopDetailState(shopId: shopId, shop: shop));

  final TrustedShopRepository _repository;

  /// Tăng mỗi lần tải lại trang đầu để bỏ kết quả của lần tải cũ về muộn
  int _requestId = 0;

  @override
  void emit(ShopDetailState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  /// Lần đầu luôn tải lại thông tin shop để số liệu (theo dõi, số tin) mới
  Future<void> start() => _reload(reloadShop: true);

  /// Kéo để làm mới: giữ nội dung cũ tới khi có dữ liệu mới
  Future<void> refresh() => _reload(showLoading: false, reloadShop: true);

  Future<void> retry() => _reload(reloadShop: true);

  void setSort(ListingSort sort) {
    if (sort == state.filter.sort) return;
    _applyFilter(state.filter.copyWith(sort: sort));
  }

  void toggleDeal(ListingDealType type) =>
      _applyFilter(state.filter.toggleDeal(type));

  /// Nhận bộ lọc từ sheet Bộ lọc đầy đủ
  void applyFilter(ListingFilter filter) {
    if (filter == state.filter) return;
    _applyFilter(filter);
  }

  /// Xoá mọi tiêu chí, giữ cách sắp xếp
  void clearFilters() =>
      applyFilter(state.filter.resetTo(ShopDetailState.defaultFilter));

  /// Tải trang tiếp theo; tự bỏ qua khi đang tải hoặc đã hết
  Future<void> loadMore() async {
    if (state.status != ShopDetailStatus.ready ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.getShopListings(
        state.shopId,
        state.filter,
        page: state.page + 1,
      );
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          items: [...state.items, ...result.items],
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId == _requestId) emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// Theo dõi / bỏ theo dõi ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> toggleFollow() async {
    final shop = state.shop;
    if (shop == null) return;
    final following = !shop.isFollowing;
    _setFollowing(following);
    try {
      await _repository.setFollowing(shop.shop.id, following);
    } catch (_) {
      _setFollowing(!following);
    }
  }

  void _setFollowing(bool following) {
    final shop = state.shop;
    if (shop != null) emit(state.copyWith(shop: shop.withFollowing(following)));
  }

  /// Đổi trạng thái lưu tin ngay trên UI, lỗi API thì trả lại như cũ
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

  /// Cập nhật thẻ tin sau khi lưu / bỏ lưu ở trang chi tiết
  void syncFavorite(String listingId, bool favorite) => emit(
    state.copyWith(
      items: [
        for (final item in state.items)
          item.listing.id == listingId
              ? item.copyWith(isFavorite: favorite)
              : item,
      ],
    ),
  );

  void _applyFilter(ListingFilter filter) {
    emit(state.copyWith(filter: filter));
    _reload();
  }

  /// Tải lại trang đầu theo bộ lọc hiện tại; [reloadShop] để lấy lại cả
  /// thông tin shop. [showLoading] false khi kéo để làm mới.
  Future<void> _reload({
    bool showLoading = true,
    bool reloadShop = false,
  }) async {
    final requestId = ++_requestId;
    if (showLoading) {
      emit(
        state.copyWith(status: ShopDetailStatus.loading, isLoadingMore: false),
      );
    }
    try {
      final shop = state.shop;
      final loadShop = reloadShop || shop == null;
      final (loadedShop, banners, result) = await (
        loadShop ? _repository.getShop(state.shopId) : Future.value(shop),
        // Banner chỉ là phần thêm: lỗi thì giữ banner đang có
        loadShop
            ? _repository
                  .getShopBanners(state.shopId)
                  .catchError((Object _) => state.banners)
            : Future.value(state.banners),
        _repository.getShopListings(state.shopId, state.filter),
      ).wait;
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          shop: loadedShop,
          banners: banners,
          status: ShopDetailStatus.ready,
          items: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      // Làm mới thất bại thì giữ nội dung đang có
      if (showLoading || state.status != ShopDetailStatus.ready) {
        emit(state.copyWith(status: ShopDetailStatus.failure));
      }
    }
  }
}
