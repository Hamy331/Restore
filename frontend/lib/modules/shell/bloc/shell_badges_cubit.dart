import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';

/// Số đếm hiện dạng huy hiệu trên thanh điều hướng (hiện có tin nhắn chưa đọc)
class ShellBadgesCubit extends Cubit<int> {
  ShellBadgesCubit({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(0);

  final ChatRepository _chatRepository;

  /// Lỗi mạng thì giữ số cũ, huy hiệu không quan trọng tới mức báo lỗi
  Future<void> refresh() async {
    try {
      final count = await _chatRepository.getUnreadCount();
      if (!isClosed) emit(count);
    } catch (_) {}
  }
}
