import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/area_option.dart';
import '../../repositories/area_search_repository.dart';
import 'area_search_state.dart';

/// Trang chọn khu vực: tìm phường/xã, tỉnh/thành theo tên và danh sách
/// khu vực đã chọn gần đây
class AreaSearchCubit extends Cubit<AreaSearchState> {
  AreaSearchCubit({required AreaSearchRepository repository})
    : _repository = repository,
      super(const AreaSearchState());

  final AreaSearchRepository _repository;

  /// Chờ người dùng ngừng gõ một chút rồi mới tìm
  static const Duration _debounce = Duration(milliseconds: 250);
  Timer? _debounceTimer;

  @override
  void emit(AreaSearchState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> start() async {
    try {
      final recent = await _repository.getRecent();
      emit(state.copyWith(recent: recent));
    } catch (_) {
      // Không có danh sách gần đây thì ẩn phần đó
    }
  }

  void queryChanged(String text) {
    final query = text.trim();
    if (query == state.query) return;
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          query: query,
          status: AreaSearchStatus.idle,
          results: const [],
        ),
      );
      return;
    }
    emit(state.copyWith(query: query, status: AreaSearchStatus.searching));
    _debounceTimer = Timer(_debounce, () => _search(query));
  }

  Future<void> retry() => _search(state.query);

  /// Ghi nhớ khu vực vừa chọn; lỗi cũng không chặn việc chọn
  Future<void> remember(AreaOption area) async {
    try {
      await _repository.saveRecent(area);
    } catch (_) {
      // Bỏ qua
    }
  }

  /// Xoá ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> removeRecent(AreaOption area) async {
    final before = state.recent;
    emit(state.copyWith(recent: [...before]..remove(area)));
    try {
      await _repository.deleteRecent(area.code);
    } catch (_) {
      emit(state.copyWith(recent: before));
    }
  }

  Future<void> _search(String query) async {
    try {
      final results = await _repository.search(query);
      // Người dùng đã gõ tiếp thì bỏ kết quả cũ
      if (query != state.query) return;
      emit(state.copyWith(status: AreaSearchStatus.ready, results: results));
    } catch (_) {
      if (query != state.query) return;
      emit(state.copyWith(status: AreaSearchStatus.failure));
    }
  }
}
