import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/credit_repository.dart';
import 'credit_bonus_state.dart';

/// Trang "Xu tặng và hạn dùng"
class CreditBonusCubit extends Cubit<CreditBonusState> {
  CreditBonusCubit({required CreditRepository repository})
    : _repository = repository,
      super(const CreditBonusState());

  final CreditRepository _repository;

  /// Tải lại; đang có dữ liệu thì giữ trên màn hình khi tải (kéo để làm mới)
  Future<void> load() async {
    if (state.status != CreditBonusStatus.ready) {
      emit(const CreditBonusState());
    }
    try {
      final items = await _repository.getBonusBatches();
      if (isClosed) return;
      emit(CreditBonusState(status: CreditBonusStatus.ready, items: items));
    } catch (_) {
      if (isClosed) return;
      emit(
        CreditBonusState(status: CreditBonusStatus.failure, items: state.items),
      );
    }
  }
}
