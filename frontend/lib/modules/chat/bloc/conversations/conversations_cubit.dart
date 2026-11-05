import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/chat_repository.dart';
import 'conversations_state.dart';

/// Danh sách cuộc trò chuyện; tải lại khi có sự kiện realtime và định kỳ
/// [refreshInterval] để bù khi mất kết nối SSE.
class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(
    this._repository, {
    this.refreshInterval = const Duration(seconds: 12),
  }) : super(const ConversationsState());

  final ChatRepository _repository;
  final Duration refreshInterval;
  StreamSubscription<String>? _events;
  Timer? _timer;

  /// Tải lần đầu và bắt đầu lắng nghe thay đổi.
  void start() {
    unawaited(load());
    _events = _repository.events().listen(
      (_) => unawaited(load()),
      onError: (Object _) {},
    );
    _timer = Timer.periodic(refreshInterval, (_) => unawaited(load()));
  }

  Future<void> load() async {
    try {
      final items = await _repository.listConversations();
      if (!isClosed) {
        emit(ConversationsState(conversations: items, loading: false));
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          ConversationsState(
            conversations: state.conversations,
            loading: false,
            failed: true,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _events?.cancel();
    return super.close();
  }
}
