import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/chat_models.dart';
import '../../repositories/chat_repository.dart';
import 'conversation_state.dart';

/// Một cuộc trò chuyện: tải tin, đánh dấu đã đọc, gửi tin và cập nhật khi
/// có sự kiện `message` / `presence` hoặc sau mỗi [refreshInterval].
class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit(
    this._repository,
    this.conversationId, {
    this.refreshInterval = const Duration(seconds: 8),
  }) : super(const ConversationState());

  final ChatRepository _repository;
  final String conversationId;
  final Duration refreshInterval;
  StreamSubscription<String>? _events;
  Timer? _timer;

  void start() {
    unawaited(load());
    _events = _repository.events().listen((event) {
      if (event == 'message' || event == 'presence') {
        unawaited(load(silent: true));
      }
    }, onError: (Object _) {});
    _timer = Timer.periodic(
      refreshInterval,
      (_) => unawaited(load(silent: true)),
    );
  }

  /// [silent]: làm mới ngầm, lỗi thì giữ nguyên nội dung đang hiển thị.
  Future<void> load({bool silent = false}) async {
    try {
      final selfId = state.selfId ?? await _repository.currentUserId();
      final results = await Future.wait<Object>([
        _repository.getConversation(conversationId),
        _repository.getMessages(conversationId),
      ]);
      await _repository.markRead(conversationId);
      if (isClosed) return;
      emit(
        state.copyWith(
          selfId: selfId,
          conversation: results[0] as ChatConversation,
          messages: results[1] as List<ChatMessage>,
          loading: false,
          failed: false,
        ),
      );
    } catch (_) {
      if (!isClosed && !silent) {
        emit(state.copyWith(loading: false, failed: true));
      }
    }
  }

  /// Trả `true` khi gửi thành công để view xoá ô soạn tin.
  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return false;
    emit(state.copyWith(sending: true));
    final clientId =
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
    try {
      await _repository.sendMessage(conversationId, clientId, trimmed);
      if (isClosed) return true;
      emit(state.copyWith(sending: false));
      await load();
      return true;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(sending: false, sendFailed: true));
      return false;
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _events?.cancel();
    return super.close();
  }
}
