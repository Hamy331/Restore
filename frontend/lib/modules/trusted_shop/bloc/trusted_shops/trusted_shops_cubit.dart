import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../../models/trusted_shop_item.dart';
import '../../repositories/trusted_shop_repository.dart';
import 'trusted_shops_state.dart';

/// Trang Shop uy tín: banner sự kiện, các khu shop / sản phẩm nổi bật và
/// lưới mọi sản phẩm của các shop đã xác minh
class TrustedShopsCubit extends Cubit<TrustedShopsState> {
  TrustedShopsCubit({required TrustedShopRepository repository})
    : _repository = repository,
      super(const TrustedShopsState());

  final TrustedShopRepository _repository;

  /// Tăng mỗi lần tải lại để bỏ kết quả của lần tải cũ về muộn
  /// (VD bấm đổi bộ lọc liên tục)
  int _requestId = 0;

  @override
  void emit(TrustedShopsState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  Future<void> start() => _reload();

  /// Kéo để làm mới: giữ nội dung cũ tới khi có dữ liệu mới
  Future<void> refresh() => _reload(showLoading: false);

  Future<void> retry() => _reload();

  /// Chọn danh mục của lưới sản phẩm, null là "Tất cả"
  Future<void> selectCategory(String? categoryId) {
    if (categoryId == state.categoryId) return Future.value();
    return _reloadProducts(state.copyWith(categoryId: () => categoryId));
  }

  /// Bật / tắt chỉ xem tin đang giảm giá
  Future<void> setOnSale(bool onSale) {
    if (onSale == state.onSale) return Future.value();
    return _reloadProducts(state.copyWith(onSale: onSale));
  }

  Future<void> setSort(ListingSort sort) {
    if (sort == state.sort) return Future.value();
    return _reloadProducts(state.copyWith(sort: sort));
  }

  /// Đổi bộ lọc chỉ tải lại lưới sản phẩm, giữ các khu phía trên. Lỗi thì
  /// giữ danh sách và bộ lọc cũ.
  Future<void> _reloadProducts(TrustedShopsState next) async {
    final previous = state;
    final requestId = ++_requestId;
    emit(next.copyWith(isLoadingProducts: true, isLoadingMore: false));
    try {
      final result = await _repository.getListings(
        state.filter,
        onSale: state.onSale,
      );
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          products: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingProducts: false,
        ),
      );
    } catch (_) {
      if (requestId == _requestId) {
        emit(
          state.copyWith(
            categoryId: () => previous.categoryId,
            onSale: previous.onSale,
            sort: previous.sort,
            isLoadingProducts: false,
          ),
        );
      }
    }
  }

  /// Tải trang tiếp theo của lưới sản phẩm; tự bỏ qua khi đang tải hoặc đã hết
  Future<void> loadMore() async {
    if (state.status != TrustedShopsStatus.ready ||
        state.isLoadingProducts ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.getListings(
        state.filter,
        page: state.page + 1,
        onSale: state.onSale,
      );
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          products: [...state.products, ...result.items],
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
  Future<void> toggleFollow(TrustedShopItem item) async {
    final id = item.shop.id;
    final following = !item.isFollowing;
    syncFollowing(id, following);
    try {
      await _repository.setFollowing(id, following);
    } catch (_) {
      syncFollowing(id, !following);
    }
  }

  /// Cập nhật thẻ shop sau khi theo dõi / bỏ theo dõi ở trang của shop
  void syncFollowing(String shopId, bool following) => emit(
    state.copyWith(overview: state.overview.withFollowing(shopId, following)),
  );

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

  /// Cập nhật thẻ tin ở mọi khu và lưới phía dưới
  void syncFavorite(String listingId, bool favorite) => emit(
    state.copyWith(
      overview: state.overview.withFavorite(listingId, favorite),
      products: [
        for (final item in state.products)
          item.listing.id == listingId
              ? item.copyWith(isFavorite: favorite)
              : item,
      ],
    ),
  );

  /// Tải lại các khu phía trên và trang đầu của lưới sản phẩm theo bộ lọc
  /// đang chọn. [showLoading] false khi kéo để làm mới.
  Future<void> _reload({bool showLoading = true}) async {
    final requestId = ++_requestId;
    if (showLoading) {
      emit(
        state.copyWith(
          status: TrustedShopsStatus.loading,
          isLoadingMore: false,
          isLoadingProducts: false,
        ),
      );
    }
    try {
      final (overview, result) = await (
        _repository.getOverview(),
        _repository.getListings(state.filter, onSale: state.onSale),
      ).wait;
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          status: TrustedShopsStatus.ready,
          overview: overview,
          products: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
          isLoadingProducts: false,
        ),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      // Làm mới thất bại thì giữ nội dung đang có
      if (showLoading || state.status != TrustedShopsStatus.ready) {
        emit(state.copyWith(status: TrustedShopsStatus.failure));
      }
    }
  }
}
