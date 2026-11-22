import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/shared/models/listing_card_item.dart';

import '../repositories/saved_listings_repository.dart';

enum SavedListingsStatus { loading, ready, failure }

class SavedListingsState extends Equatable {
  const SavedListingsState({
    this.status = SavedListingsStatus.loading,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final SavedListingsStatus status;
  final List<ListingCardItem> items;

  /// Trang cuối đã tải
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  SavedListingsState copyWith({
    SavedListingsStatus? status,
    List<ListingCardItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => SavedListingsState(
    status: status ?? this.status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [status, items, page, hasMore, isLoadingMore];
}

/// Trang Tin đã lưu: tải theo trang, kéo để làm mới, bỏ lưu / lưu lại.
/// Bỏ lưu thì thẻ vẫn ở lại (trái tim rỗng) để bấm lưu lại được;
/// lần làm mới sau tin đó mới biến mất.
class SavedListingsCubit extends Cubit<SavedListingsState> {
  SavedListingsCubit({required SavedListingsRepository repository})
    : _repository = repository,
      super(const SavedListingsState());

  final SavedListingsRepository _repository;

  /// Tăng mỗi lần tải lại trang đầu để bỏ kết quả cũ về muộn
  int _requestId = 0;

  @override
  void emit(SavedListingsState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  Future<void> start() => _reload();

  Future<void> retry() => _reload();

  /// Kéo để làm mới: giữ danh sách cũ tới khi có dữ liệu mới
  Future<void> refresh() => _reload(showLoading: false);

  Future<void> loadMore() async {
    if (state.status != SavedListingsStatus.ready ||
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

  /// Đổi trạng thái lưu ngay trên UI, lỗi API thì trả lại như cũ
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
      emit(
        state.copyWith(
          status: SavedListingsStatus.loading,
          isLoadingMore: false,
        ),
      );
    }
    try {
      final result = await _repository.getPage();
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          status: SavedListingsStatus.ready,
          items: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId != _requestId) return;
      if (showLoading || state.status != SavedListingsStatus.ready) {
        emit(state.copyWith(status: SavedListingsStatus.failure));
      }
    }
  }
}
