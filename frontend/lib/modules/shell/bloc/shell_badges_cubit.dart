import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';

/// Số đếm hiện dạng huy hiệu trên thanh điều hướng (hiện có tin nhắn chưa đọc)
class ShellBadgesCubit extends Cubit<int> {
  ShellBadgesCubit({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(0) {
    _events = chatRepository.events().listen((event) {
      if (event == 'message' || event == 'read') unawaited(refresh());
    }, onError: (Object _) {});
  }

  StreamSubscription<String>? _events;

  @override
  Future<void> close() async {
    await _events?.cancel();
    await super.close();
  }

  final ChatRepository _chatRepository;

  /// Lỗi mạng thì giữ số cũ, huy hiệu không quan trọng tới mức báo lỗi
  Future<void> refresh() async {
    try {
      final count = await _chatRepository.getUnreadCount();
      if (!isClosed) emit(count);
    } catch (_) {}
  }
}
