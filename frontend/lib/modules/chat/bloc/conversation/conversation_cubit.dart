import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/chat_models.dart';
import '../../repositories/chat_repository.dart';
import 'conversation_state.dart';

class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit(this._repository, this.conversationId, {this.visible})
    : super(const ConversationState());
  final ChatRepository _repository;
  final String conversationId;
  final bool Function()? visible;
  StreamSubscription<ChatEvent>? _events;
  final _buffer = <ChatEvent>[];
  final _drafts = <String, ({String text, String? listing})>{};
  Timer? _readTimer;
  bool _paging = false;
  int _revision = 0, _read = 0;
  int? _cursor;
  bool _syncing = false;
  String? _contextId;

  List<ChatMessage> _merge(Iterable<ChatMessage> incoming) {
    final rows = {for (final m in state.messages) m.id: m};
    for (final m in incoming) {
      if (m.clientId != null && rows[m.clientId]?.senderId == m.senderId) {
        rows.remove(m.clientId);
      }
      rows[m.id] = m;
    }
    return rows.values.toList()..sort((a, b) {
      if (a.sequence == null && b.sequence == null) {
        return a.createdAt.compareTo(b.createdAt);
      }
      return (a.sequence ?? 0x7fffffff).compareTo(b.sequence ?? 0x7fffffff);
    });
  }

  void start() {
    _events ??= _repository.events().listen((e) {
      if (e.type == 'sync') {
        unawaited(load(silent: true));
        return;
      }
      if (_syncing) {
        _buffer.add(e);
      } else {
        _apply(e);
      }
    });
    unawaited(load());
  }

  void _apply(ChatEvent e) {
    final current = state.conversation;
    if (current == null) return;
    if (e.type == 'presence') {
      emit(state.copyWith(conversation: current.presence(e.data)));
      return;
    }
    if (e.data['threadId'] != current.id) return;
    final raw = e.data['summary'];
    var summary = raw is Map
        ? ChatConversation.fromJson(Map.from(raw))
        : current;
    if (_contextId != null && summary.trade?.contextId != _contextId) {
      summary = summary.updated(selectedTrade: current.trade);
    }
    final msg = e.data['message'];
    emit(
      state.copyWith(
        conversation: summary,
        messages: msg is Map
            ? _merge([ChatMessage.fromJson(Map.from(msg))])
            : null,
      ),
    );
    if (msg is Map && msg['sequence'] is int) {
      final sequence = msg['sequence'] as int;
      if (sequence > (_cursor ?? 0)) _cursor = sequence;
      _scheduleRead();
    }
    if (e.type == 'trade.updated' && _contextId == e.data['contextId']) {
      unawaited(_refreshContext());
    }
  }

  Future<void> _refreshContext() async {
    final selected = _contextId;
    try {
      final result = await _repository.getConversation(
        selected ?? conversationId,
      );
      if (!isClosed && _contextId == selected) {
        emit(state.copyWith(conversation: result));
      }
    } catch (_) {}
  }

  Future<void> selectProduct(String contextId) async {
    _contextId = contextId;
    await _refreshContext();
  }

  Future<void> older() async {
    final before = state.messages.firstOrNull?.sequence;
    if (_paging || !state.hasOlder || before == null) return;
    _paging = true;
    try {
      final page = await _repository.getMessages(
        conversationId,
        before: before,
      );
      if (!isClosed) {
        emit(
          state.copyWith(messages: _merge(page), hasOlder: page.length == 30),
        );
      }
    } finally {
      _paging = false;
    }
  }

  Future<void> load({bool silent = false}) async {
    final revision = ++_revision;
    _syncing = true;
    final cursor = _cursor;
    try {
      final self = state.selfId ?? await _repository.currentUserId();
      final convo = await _repository.getConversation(
        _contextId ?? conversationId,
      );
      var after = cursor;
      final received = <ChatMessage>[];
      do {
        final page = await _repository.getMessages(
          conversationId,
          after: after,
        );
        if (isClosed || revision != _revision) return;
        received.addAll(page);
        if (after == null || page.length < 30) break;
        after = page.last.sequence!;
      } while (true);
      emit(
        state.copyWith(
          conversation: convo,
          selfId: self,
          messages: _merge(received),
          loading: false,
          failed: false,
          hasOlder: cursor == null ? received.length == 30 : state.hasOlder,
        ),
      );
      _cursor = received.lastOrNull?.sequence ?? cursor ?? 0;
      for (final e in List.of(_buffer)) {
        _apply(e);
      }
      _scheduleRead();
    } catch (_) {
      if (!isClosed && revision == _revision) {
        for (final e in _buffer) {
          _apply(e);
        }
      }
      if (!isClosed && revision == _revision && !silent) {
        emit(state.copyWith(loading: false, failed: true));
      }
    } finally {
      if (revision == _revision) {
        _syncing = false;
        _buffer.clear();
      }
    }
  }

  void _scheduleRead() {
    if (visible?.call() == false) return;
    if (state.messages.every(
      (m) => m.sequence == null || m.sequence! <= _read,
    )) {
      return;
    }
    _readTimer?.cancel();
    _readTimer = Timer(const Duration(milliseconds: 180), () async {
      if (isClosed || visible?.call() == false) return;
      final seq =
          state.messages
              .where((m) => m.sequence != null)
              .lastOrNull
              ?.sequence ??
          0;
      if (seq <= _read) return;
      try {
        await _repository.markRead(conversationId, through: seq);
        if (seq > _read) _read = seq;
      } catch (_) {}
    });
  }

  void acceptMessage(ChatMessage message) {
    if (!isClosed) emit(state.copyWith(messages: _merge([message])));
  }

  void markVisible() => _scheduleRead();
  Future<bool> send(String text, {String? listingId}) async {
    if (text.trim().isEmpty || state.selfId == null) return false;
    final id = newChatClientId();
    _drafts[id] = (text: text.trim(), listing: listingId);
    return _deliver(id);
  }

  Future<bool> retry(String id) => _deliver(id);
  Future<bool> _deliver(String id) async {
    final draft = _drafts[id];
    if (draft == null || isClosed) return false;
    final created =
        state.messages.where((m) => m.id == id).firstOrNull?.createdAt ??
        DateTime.now();
    ChatMessage local(String status, {bool retryable = false}) => ChatMessage(
      id: id,
      clientId: id,
      senderId: state.selfId!,
      text: draft.text,
      createdAt: created,
      delivery: status,
      retryable: retryable,
    );
    emit(state.copyWith(messages: _merge([local('Đang gửi')])));
    try {
      final saved = await _repository.sendMessage(
        conversationId,
        id,
        draft.text,
        listingId: draft.listing,
      );
      _drafts.remove(id);
      if (!isClosed) {
        emit(
          state.copyWith(
            messages: _merge([
              saved,
            ]).where((m) => m.id != id || id == saved.id).toList(),
          ),
        );
      }
      return true;
    } catch (error) {
      if (isClosed) return false;
      if (state.messages.any((m) => m.clientId == id && m.delivery == null)) {
        return true;
      }
      final data = error is DioException ? error.response?.data : null;
      final reason = data is Map && data['error'] is String
          ? data['error'] as String
          : 'Chạm để thử lại';
      emit(
        state.copyWith(
          messages: _merge([
            local(
              'Lỗi · $reason',
              retryable:
                  data is! Map ||
                  !const {
                    'CHAT_BLOCKED',
                    'LISTING_UNAVAILABLE',
                    'INVALID_MESSAGE',
                    'CLIENT_ID_REUSED',
                  }.contains(data['code']),
            ),
          ]),
          sendFailed: true,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() async {
    _readTimer?.cancel();
    await _events?.cancel();
    return super.close();
  }
}
