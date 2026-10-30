import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';

/// Số đếm hiện dạng huy hiệu trên thanh điều hướng (hiện có tin nhắn chưa đọc)
class ShellBadgesCubit extends Cubit<int> {
  ShellBadgesCubit({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(0) {
    if (chatRepository is ApiChatRepository) {
      _events = chatRepository.events(_cancel).listen(
        (event) {
          if (event == 'message' || event == 'read') unawaited(refresh());
        },
        onError: (Object _) {},
      );
    }
  }

  final _cancel = CancelToken();
  StreamSubscription<String>? _events;

  @override
  Future<void> close() async {
    _cancel.cancel();
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
