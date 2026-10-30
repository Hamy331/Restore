import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/wanted_alert_item.dart';
import '../../repositories/wanted_alert_repository.dart';
import 'wanted_alerts_state.dart';

/// Trang quản lý thông báo "Báo khi có hàng" của người dùng
class WantedAlertsCubit extends Cubit<WantedAlertsState> {
  WantedAlertsCubit({required WantedAlertRepository repository})
    : _repository = repository,
      super(const WantedAlertsState());

  final WantedAlertRepository _repository;

  @override
  void emit(WantedAlertsState state) {
    if (!isClosed) super.emit(state);
  }

  /// [showLoading] false khi kéo để làm mới hoặc quay lại từ trang khác:
  /// giữ danh sách cũ tới khi có dữ liệu mới
  Future<void> load({bool showLoading = true}) async {
    if (showLoading) emit(state.copyWith(status: WantedAlertsStatus.loading));
    try {
      final items = await _repository.getAlerts();
      emit(state.copyWith(status: WantedAlertsStatus.ready, items: items));
    } catch (_) {
      if (showLoading || state.status != WantedAlertsStatus.ready) {
        emit(state.copyWith(status: WantedAlertsStatus.failure));
      }
    }
  }

  Future<void> refresh() => load(showLoading: false);

  /// Thêm thông báo vừa tạo lên đầu danh sách
  void added(WantedAlertItem item) => emit(
    state.copyWith(
      status: WantedAlertsStatus.ready,
      items: [item, ...state.items.where((other) => other.id != item.id)],
    ),
  );

  /// Đã mở xem tin khớp ở trang chi tiết: bỏ số đếm tin mới
  void seen(String id) => emit(
    state.copyWith(
      items: [
        for (final item in state.items) item.id == id ? item.markSeen() : item,
      ],
    ),
  );

  /// Bỏ khỏi danh sách (đã xoá ở trang chi tiết)
  void removed(String id) => emit(
    state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id != id) item,
      ],
    ),
  );

  /// Xoá ngay trên UI, lỗi API thì trả lại vị trí cũ. Trả về false khi lỗi.
  Future<bool> delete(WantedAlertItem item) async {
    final before = state.items;
    removed(item.id);
    try {
      await _repository.delete(item.id);
      return true;
    } catch (_) {
      emit(state.copyWith(items: before));
      return false;
    }
  }
}
