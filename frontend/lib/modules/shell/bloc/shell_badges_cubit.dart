import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/chat/repositories/chat_repository.dart';

/// Số đếm hiện dạng huy hiệu trên thanh điều hướng (hiện có tin nhắn chưa đọc)
class ShellBadgesCubit extends Cubit<int> {
  ShellBadgesCubit({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(0) {
    _events = chatRepository.events().listen((event) {
      final count = event.data['totalUnread'];
      if (count is int) {
        _revision++;
        emit(count);
      }
      if (event.type == 'sync') unawaited(refresh());
    }, onError: (Object _) {});
  }

  int _revision = 0;
  StreamSubscription<ChatEvent>? _events;

  @override
  Future<void> close() async {
    await _events?.cancel();
    await super.close();
  }

  final ChatRepository _chatRepository;

  /// Lỗi mạng thì giữ số cũ, huy hiệu không quan trọng tới mức báo lỗi
  Future<void> refresh() async {
    final revision = ++_revision;
    try {
      final count = await _chatRepository.getUnreadCount();
      if (!isClosed && revision == _revision) emit(count);
    } catch (_) {}
  }
}
