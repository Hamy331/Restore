import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/credit_history_filter.dart';
import '../../repositories/credit_repository.dart';
import 'credit_history_state.dart';

/// Lịch sử xu theo bộ lọc, tải thêm theo trang
class CreditHistoryCubit extends Cubit<CreditHistoryState> {
  CreditHistoryCubit({required CreditRepository repository})
    : _repository = repository,
      super(const CreditHistoryState());

  final CreditRepository _repository;

  Future<void> load([CreditHistoryFilter? filter]) async {
    final target = filter ?? state.filter;
    emit(
      CreditHistoryState(filter: target, status: CreditHistoryStatus.loading),
    );
    try {
      final page = await _repository.getTransactions(filter: target);
      if (isClosed || state.filter != target) return;
      emit(
        state.copyWith(
          status: CreditHistoryStatus.ready,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
        ),
      );
    } catch (_) {
      if (isClosed || state.filter != target) return;
      emit(state.copyWith(status: CreditHistoryStatus.failure));
    }
  }

  void filterChanged(CreditHistoryFilter filter) {
    if (filter != state.filter) load(filter);
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.loadingMore ||
        state.status != CreditHistoryStatus.ready) {
      return;
    }
    final filter = state.filter;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.getTransactions(
        page: state.page + 1,
        filter: filter,
      );
      if (isClosed || state.filter != filter) return;
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (isClosed || state.filter != filter) return;
      emit(state.copyWith(loadingMore: false));
    }
  }
}
