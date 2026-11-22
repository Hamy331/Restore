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
  Future<void>? _inFlight;
  DateTime? _lastLoadedAt;
  bool _dirty = true;

  void search(String query) {
    if (isClosed || query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
  }

  /// Chỉ chạy khi danh sách đang hiển thị. Giữ dữ liệu khi mở lại.
  void start() {
    if (isClosed || _timer != null) return;
    _timer = Timer.periodic(refreshInterval, (_) => unawaited(load()));
    _events = _repository.events().listen((event) {
      if (event == 'message' || event == 'read') invalidate();
    }, onError: (Object _) {});
    final lastLoaded = _lastLoadedAt;
    if (_dirty ||
        state.failed ||
        lastLoaded == null ||
        DateTime.now().difference(lastLoaded) >= refreshInterval) {
      unawaited(load());
    }
  }

  Future<void> pause() async {
    _timer?.cancel();
    _timer = null;
    final events = _events;
    _events = null;
    await events?.cancel();
  }

  void invalidate() {
    _dirty = true;
    if (_timer != null) unawaited(load());
  }

  Future<void> load() {
    if (isClosed) return Future.value();
    return _inFlight ??= _fetch().whenComplete(() {
      _inFlight = null;
      if (_dirty && _timer != null) unawaited(load());
    });
  }

  Future<void> _fetch() async {
    _dirty = false;
    try {
      final items = await _repository.listConversations();
      if (!isClosed) {
        _lastLoadedAt = DateTime.now();
        emit(
          state.copyWith(conversations: items, loading: false, failed: false),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(loading: false, failed: true));
      }
    }
  }

  @override
  Future<void> close() async {
    final paused = pause();
    await super.close();
    await paused;
  }
}
