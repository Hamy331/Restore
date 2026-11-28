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

  /// Danh sách đang hiển thị: chỉ tải lại khi đang hiển thị
  bool _visible = false;

  /// Cần tải lại từ server (chưa tải lần nào, hoặc đã lỡ sự kiện khi mất kết nối)
  bool _stale = true;

  void search(String query) => emit(state.copyWith(searchQuery: query));

  /// Hiển thị danh sách. Giữ dữ liệu khi mở lại; chỉ tải lại khi dữ liệu cũ.
  void start() {
    if (isClosed) return;
    _visible = true;
    _events ??= _repository.events().listen(_onEvent);
    if (_stale || state.failed) unawaited(load());
  }

  void _onEvent(ChatEvent e) {
    if (e.type == 'sync') {
      invalidate();
      return;
    }
    if (_loading != null) _buffer.add(e);
    _apply(e);
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

  /// Ẩn danh sách: vẫn nhận sự kiện realtime để danh sách luôn mới, nhưng
  /// không gọi server; sự kiện `sync` lúc ẩn được bù khi [start] lại.
  Future<void> pause() async => _visible = false;

  void invalidate() {
    _stale = true;
    if (!_visible || isClosed) return;
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
      _stale = false;
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
    _visible = false;
    await _events?.cancel();
    _events = null;
    return super.close();
  }
}
