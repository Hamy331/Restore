import 'dart:async';

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
  String? _contextId;
  int _revision = 0;
  bool _paging = false;
  (String, String?)? _pending;
  String? _clientId;

  Future<void> selectProduct(String contextId) {
    _contextId = contextId;
    return load();
  }

  Future<void> older() async {
    if (_paging || !state.hasOlder || state.messages.isEmpty) return;
    _paging = true;
    try {
      final before = state.messages.first.sequence;
      final page = await _repository.getMessages(
        conversationId,
        before: before,
      );
      if (!isClosed && before == state.messages.firstOrNull?.sequence) {
        emit(
          state.copyWith(
            messages: [...page, ...state.messages],
            hasOlder: page.length == 30,
          ),
        );
      }
    } finally {
      _paging = false;
    }
  }

  void start() {
    unawaited(load());
    _events = _repository.events().listen((event) {
      if (event == 'message' || event == 'presence' || event == 'seen') {
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
    final revision = ++_revision;
    try {
      final selfId = state.selfId ?? await _repository.currentUserId();
      final results = await Future.wait<Object>([
        _repository.getConversation(_contextId ?? conversationId),
        _repository.getMessages(conversationId),
      ]);
      final page = results[1] as List<ChatMessage>;
      if (isClosed || revision != _revision) return;
      if (state.conversation == null ||
          state.messages.lastOrNull?.id != page.lastOrNull?.id) {
        await _repository.markRead(
          conversationId,
          through: page.lastOrNull?.sequence ?? 0,
        );
      }
      if (isClosed || revision != _revision) return;
      final overlap = page.isEmpty
          ? -1
          : state.messages.indexWhere((m) => m.id == page.first.id);
      final retained = overlap > 0
          ? state.messages.take(overlap)
          : const <ChatMessage>[];
      emit(
        state.copyWith(
          selfId: selfId,
          conversation: results[0] as ChatConversation,
          messages: [...retained, ...page],
          hasOlder: retained.isEmpty ? page.length == 30 : state.hasOlder,
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
  Future<bool> send(String text, {String? listingId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return false;
    emit(state.copyWith(sending: true));
    if (_pending != (trimmed, listingId)) {
      _pending = (trimmed, listingId);
      _clientId = newChatClientId();
    }
    try {
      await _repository.sendMessage(
        conversationId,
        _clientId!,
        trimmed,
        listingId: listingId,
      );
      _pending = null;
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
