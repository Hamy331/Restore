import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/shared/models/listing_card_item.dart';

import '../repositories/hot_sale_repository.dart';
import 'hot_sale_state.dart';

/// Trang Hot sale: tải theo trang, kéo để làm mới, lưu tin
class HotSaleCubit extends Cubit<HotSaleState> {
  HotSaleCubit({required HotSaleRepository repository})
    : _repository = repository,
      super(const HotSaleState());

  final HotSaleRepository _repository;

  /// Tăng mỗi lần tải lại trang đầu để bỏ kết quả cũ về muộn
  int _requestId = 0;

  @override
  void emit(HotSaleState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  Future<void> start() => _reload();

  Future<void> retry() => _reload();

  /// Kéo để làm mới: giữ danh sách cũ tới khi có dữ liệu mới
  Future<void> refresh() => _reload(showLoading: false);

  Future<void> loadMore() async {
    if (state.status != HotSaleStatus.ready ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.getPage(page: state.page + 1);
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

  Future<void> _reload({bool showLoading = true}) async {
    final requestId = ++_requestId;
    if (showLoading) {
      emit(state.copyWith(status: HotSaleStatus.loading, isLoadingMore: false));
    }
    try {
      final result = await _repository.getPage();
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          status: HotSaleStatus.ready,
          items: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      if (showLoading || state.status != HotSaleStatus.ready) {
        emit(state.copyWith(status: HotSaleStatus.failure));
      }
    }
  }
}
