import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/search_history_entry.dart';
import '../repositories/search_repository.dart';
import 'search_state.dart';

/// Trang tìm kiếm: gợi ý tìm nhanh, lịch sử và gợi ý theo nội dung đang gõ
class SearchCubit extends Cubit<SearchState> {
  SearchCubit({required SearchRepository searchRepository, String query = ''})
    : _repository = searchRepository,
      super(SearchState(query: query.trim()));

  final SearchRepository _repository;

  /// Chờ người dùng ngừng gõ một chút rồi mới hỏi gợi ý
  static const Duration _debounce = Duration(milliseconds: 250);
  Timer? _debounceTimer;

  @override
  void emit(SearchState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  /// Mở trang: tải gợi ý tìm nhanh và lịch sử. Lỗi thì để trống phần đó,
  /// ô tìm kiếm vẫn dùng được.
  Future<void> start() async {
    if (state.isTyping) _loadSuggestions(state.query);
    await Future.wait([_loadTrending(), loadHistory()]);
  }

  Future<void> loadHistory() async {
    try {
      final history = await _repository.getHistory();
      emit(state.copyWith(history: history));
    } catch (_) {
      // Giữ lịch sử đang hiện
    }
  }

  void queryChanged(String text) {
    final query = text.trim();
    if (query == state.query) return;
    emit(state.copyWith(query: query));
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      emit(state.copyWith(suggestions: const [], suggestionsQuery: ''));
      return;
    }
    _debounceTimer = Timer(_debounce, () => _loadSuggestions(query));
  }

  /// Xoá ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> removeHistory(SearchHistoryEntry entry) async {
    final before = state.history;
    emit(state.copyWith(history: [...before]..remove(entry)));
    try {
      await _repository.deleteHistory(entry.id);
    } catch (_) {
      emit(state.copyWith(history: before));
    }
  }

  Future<void> clearHistory() async {
    final before = state.history;
    emit(state.copyWith(history: const []));
    try {
      await _repository.clearHistory();
    } catch (_) {
      emit(state.copyWith(history: before));
    }
  }

  Future<void> _loadTrending() async {
    try {
      final trending = await _repository.getTrending();
      emit(state.copyWith(trending: trending));
    } catch (_) {
      // Không có gợi ý thì ẩn phần này
    }
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final suggestions = await _repository.getSuggestions(query);
      // Người dùng đã gõ tiếp thì bỏ kết quả cũ
      if (query != state.query) return;
      emit(state.copyWith(suggestions: suggestions, suggestionsQuery: query));
    } catch (_) {
      // Không có gợi ý vẫn tìm được bằng nút "Tìm ..."
    }
  }
}
