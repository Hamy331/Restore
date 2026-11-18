import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';
import 'package:restore/data/models/notification_model.dart';

import '../../models/notification_filter.dart';
import '../../repositories/notification_repository.dart';
import '../notification_badge/notification_badge_cubit.dart';
import 'notifications_state.dart';

/// Danh sách thông báo theo bộ lọc, tải thêm theo trang. Đọc / xoá cập nhật
/// ngay trên màn hình rồi mới gọi API, lỗi thì tải lại.
///
/// [updates] (push FCM tới khi đang mở trang) làm danh sách tự tải lại.
class NotificationsCubit extends Cubit<NotificationsState>
    with SafeEmit<NotificationsState> {
  NotificationsCubit({
    required NotificationRepository repository,
    NotificationBadgeCubit? badge,
    Stream<Object?>? updates,
  }) : _repository = repository,
       _badge = badge,
       super(const NotificationsState()) {
    _updates = updates?.listen((_) => load());
  }

  final NotificationRepository _repository;
  final NotificationBadgeCubit? _badge;
  StreamSubscription<Object?>? _updates;

  @override
  Future<void> close() async {
    await _updates?.cancel();
    return super.close();
  }

  Future<void> load([NotificationFilter? filter]) async {
    final target = filter ?? state.filter;
    // Làm mới cùng bộ lọc thì giữ danh sách cũ trong lúc tải
    final keep = target == state.filter && state.items.isNotEmpty;
    emit(
      keep
          ? state
          : NotificationsState(
              filter: target,
              status: NotificationsStatus.loading,
            ),
    );
    try {
      final page = await _repository.getNotifications(filter: target);
      if (state.filter != target) return;
      emit(
        state.copyWith(
          status: NotificationsStatus.ready,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
        ),
      );
      // Đồng bộ chấm đỏ với số chưa đọc thật trên server
      await _badge?.refresh();
    } catch (_) {
      if (state.filter != target) return;
      emit(state.copyWith(status: NotificationsStatus.failure));
    }
  }

  void filterChanged(NotificationFilter filter) {
    if (filter != state.filter) load(filter);
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != NotificationsStatus.ready) {
      return;
    }
    final filter = state.filter;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.getNotifications(
        page: state.page + 1,
        filter: filter,
      );
      if (state.filter != filter) return;
      final known = {for (final item in state.items) item.id};
      emit(
        state.copyWith(
          items: [
            ...state.items,
            ...page.items.where((item) => !known.contains(item.id)),
          ],
          page: page.page,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (state.filter != filter) return;
      emit(state.copyWith(loadingMore: false));
    }
  }

  /// Bấm vào thông báo: đánh dấu đã đọc (trang mở link do view lo)
  Future<void> markRead(NotificationModel item) async {
    if (item.isRead) return;
    final now = DateTime.now();
    _replace(item.id, (old) => old.markRead(now));
    _badge?.set(_badge.state - 1);
    try {
      await _repository.markRead(item.id);
    } catch (_) {
      _badge?.refresh();
    }
  }

  Future<void> markAllRead() async {
    if (!state.hasUnread) return;
    final now = DateTime.now();
    emit(
      state.copyWith(
        items: [for (final item in state.items) item.markRead(now)],
      ),
    );
    _badge?.clear();
    try {
      await _repository.markAllRead();
    } catch (_) {
      await load();
    }
  }

  /// Xoá khỏi danh sách; trả về false nếu API lỗi (thông báo được trả lại)
  Future<bool> delete(NotificationModel item) async {
    final before = state.items;
    emit(
      state.copyWith(
        items: [
          for (final row in before)
            if (row.id != item.id) row,
        ],
      ),
    );
    if (!item.isRead) _badge?.set(_badge.state - 1);
    try {
      await _repository.delete(item.id);
      return true;
    } catch (_) {
      emit(state.copyWith(items: before));
      _badge?.refresh();
      return false;
    }
  }

  void _replace(String id, NotificationModel Function(NotificationModel) map) {
    emit(
      state.copyWith(
        items: [
          for (final item in state.items) item.id == id ? map(item) : item,
        ],
      ),
    );
  }
}
