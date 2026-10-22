import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/wanted_alert_item.dart';
import '../../models/wanted_alert_match.dart';
import '../../repositories/wanted_alert_repository.dart';
import 'wanted_alert_detail_state.dart';

/// Trang một thông báo: tiêu chí và các tin đã khớp
class WantedAlertDetailCubit extends Cubit<WantedAlertDetailState> {
  WantedAlertDetailCubit({
    required WantedAlertRepository repository,
    required String alertId,
    WantedAlertItem? alert,
  }) : _repository = repository,
       super(WantedAlertDetailState(alertId: alertId, alert: alert));

  final WantedAlertRepository _repository;

  /// Bỏ kết quả của lần tải cũ về muộn
  int _requestId = 0;

  @override
  void emit(WantedAlertDetailState state) {
    if (!isClosed) super.emit(state);
  }

  Future<void> start() => _reload();

  Future<void> refresh() => _reload(showLoading: false);

  Future<void> retry() => _reload();

  Future<void> loadMore() async {
    if (state.status != WantedAlertDetailStatus.ready ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }
    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.getMatches(
        state.alertId,
        page: state.page + 1,
      );
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          matches: [...state.matches, ...result.items],
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (requestId == _requestId) emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// Xoá thông báo (dừng gửi tin khớp). Trả về false khi lỗi.
  Future<bool> delete() async {
    emit(state.copyWith(isDeleting: true));
    try {
      await _repository.delete(state.alertId);
      return true;
    } catch (_) {
      emit(state.copyWith(isDeleting: false));
      return false;
    }
  }

  /// Đổi trạng thái lưu tin ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> toggleFavorite(WantedAlertMatch match) async {
    final favorite = !match.item.isFavorite;
    syncFavorite(match.listingId, favorite);
    try {
      await _repository.setFavorite(match.listingId, favorite);
    } catch (_) {
      syncFavorite(match.listingId, !favorite);
    }
  }

  void syncFavorite(String listingId, bool favorite) => emit(
    state.copyWith(
      matches: [
        for (final match in state.matches)
          match.listingId == listingId
              ? match.copyWith(item: match.item.copyWith(isFavorite: favorite))
              : match,
      ],
    ),
  );

  Future<void> _reload({bool showLoading = true}) async {
    final requestId = ++_requestId;
    if (showLoading) {
      emit(
        state.copyWith(
          status: WantedAlertDetailStatus.loading,
          isLoadingMore: false,
        ),
      );
    }
    try {
      final (alert, matches) = await (
        _repository.getAlert(state.alertId),
        _repository.getMatches(state.alertId),
      ).wait;
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          status: WantedAlertDetailStatus.ready,
          alert: alert,
          matches: matches.items,
          page: matches.page,
          hasMore: matches.hasMore,
          isLoadingMore: false,
        ),
      );
      // Nhãn "Mới" vẫn hiện trong lần xem này, lần sau mới mất
      if (alert.newMatchCount > 0) {
        await _repository.markSeen(state.alertId);
      }
    } catch (_) {
      if (requestId != _requestId) return;
      if (showLoading || state.status != WantedAlertDetailStatus.ready) {
        emit(state.copyWith(status: WantedAlertDetailStatus.failure));
      }
    }
  }
}
