import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/blocs/safe_emit.dart';

import '../../repositories/notification_repository.dart';

/// Số thông báo chưa đọc cho chấm đỏ trên chuông, dùng chung toàn app
/// (cấp trong main.dart). State là số chưa đọc.
///
/// Hiện tải lại khi đăng nhập, khi mở trang chủ và khi đọc / xoá thông báo.
/// Khi có gửi real-time, chỗ nhận sự kiện chỉ cần gọi [refresh] hoặc [set].
class NotificationBadgeCubit extends Cubit<int> with SafeEmit<int> {
  NotificationBadgeCubit({required NotificationRepository repository})
    : _repository = repository,
      super(0);

  final NotificationRepository _repository;

  Future<void> refresh() async {
    try {
      emit(await _repository.getUnreadCount());
    } catch (_) {
      // Lỗi mạng: giữ số cũ, lần sau tải lại
    }
  }

  void set(int count) => emit(count < 0 ? 0 : count);

  /// Đăng xuất: không còn thông báo của ai
  void clear() => emit(0);
}
