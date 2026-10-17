import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../repositories/search_repository.dart';
import 'search_results_state.dart';

/// Trang kết quả tìm kiếm theo một từ khoá
class SearchResultsCubit extends Cubit<SearchResultsState> {
  SearchResultsCubit({
    required SearchRepository searchRepository,
    required String query,
  }) : _repository = searchRepository,
       super(SearchResultsState(query: query));

  final SearchRepository _repository;

  /// Tăng mỗi lần tải lại trang đầu để bỏ kết quả của lần tải cũ về muộn
  /// (VD bấm đổi sắp xếp liên tục)
  int _requestId = 0;

  @override
  void emit(SearchResultsState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  Future<void> start() => _reload();

  /// Kéo để làm mới: giữ danh sách cũ tới khi có dữ liệu mới
  Future<void> refresh() => _reload(showLoading: false);

  Future<void> retry() => _reload();

  void setSort(ListingSort sort) {
    if (sort == state.filter.sort) return;
    _applyFilter(state.filter.copyWith(sort: sort));
  }

  void toggleDeal(ListingDealType type) =>
      _applyFilter(state.filter.toggleDeal(type));

  /// Nhận bộ lọc từ trang Bộ lọc đầy đủ
  void applyFilter(ListingFilter filter) {
    if (filter == state.filter) return;
    _applyFilter(filter);
  }

  /// Tải trang tiếp theo; tự bỏ qua khi đang tải hoặc đã hết
  Future<void> loadMore() async {
    if (state.status != SearchResultsStatus.ready ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.search(
        state.query,
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

  /// Tải lại trang đầu theo từ khoá và bộ lọc hiện tại.
  /// [showLoading] false khi kéo để làm mới.
  Future<void> _reload({bool showLoading = true}) async {
    final requestId = ++_requestId;
    if (showLoading) {
      emit(
        state.copyWith(
          status: SearchResultsStatus.loading,
          isLoadingMore: false,
        ),
      );
    }
    try {
      final result = await _repository.search(state.query, state.filter);
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          status: SearchResultsStatus.ready,
          items: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      // Làm mới thất bại thì giữ nội dung đang có
      if (showLoading || state.status != SearchResultsStatus.ready) {
        emit(state.copyWith(status: SearchResultsStatus.failure));
      }
    }
  }
}
