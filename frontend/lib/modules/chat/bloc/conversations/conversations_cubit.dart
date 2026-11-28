import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/chat_models.dart';
import '../../repositories/chat_repository.dart';
import 'conversations_state.dart';

class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(this._repository) : super(const ConversationsState());
  final ChatRepository _repository;
  StreamSubscription<ChatEvent>? _events;
  Future<void>? _loading;
  final _buffer = <ChatEvent>[];
  bool _reload = false;

  void search(String query) => emit(state.copyWith(searchQuery: query));
  void start() {
    if (_events != null || isClosed) return;
    _events = _repository.events().listen((e) {
      if (e.type == 'sync') {
        invalidate();
        return;
      }
      if (_loading != null) _buffer.add(e);
      _apply(e);
    });
    unawaited(load());
  }

  void _apply(ChatEvent e) {
    final rows = List.of(state.conversations);
    if (e.type == 'presence') {
      emit(
        state.copyWith(
          conversations: rows.map((c) => c.presence(e.data)).toList(),
        ),
      );
      return;
    }
    final raw = e.data['summary'];
    if (raw is! Map) return;
    final summary = ChatConversation.fromJson(Map.from(raw));
    final index = rows.indexWhere((c) => c.id == summary.id);
    if (index >= 0) rows.removeAt(index);
    if (raw['hidden'] != true) {
      final bump = e.data['message'] != null || index < 0;
      rows.insert(bump ? 0 : index, summary);
    }
    emit(state.copyWith(conversations: rows));
  }

  Future<void> pause() async {
    final sub = _events;
    _events = null;
    await sub?.cancel();
  }

  void invalidate() {
    if (_events == null) return;
    if (_loading != null) {
      _reload = true;
      return;
    }
    unawaited(load());
  }

  Future<void> load() => _loading ??= _fetch().whenComplete(() {
    _loading = null;
    if (_reload && !isClosed) {
      _reload = false;
      invalidate();
    }
  });
  Future<void> _fetch() async {
    try {
      final rows = await _repository.listConversations();
      if (isClosed) return;
      emit(state.copyWith(conversations: rows, loading: false, failed: false));
      for (final e in _buffer) {
        _apply(e);
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loading: false, failed: true));
    } finally {
      _buffer.clear();
    }
  }

  @override
  Future<void> close() async {
    await pause();
    return super.close();
  }
}
