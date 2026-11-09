import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/credit_repository.dart';
import 'credit_wallet_state.dart';

/// Trang ví xu: số dư và vài giao dịch gần nhất
class CreditWalletCubit extends Cubit<CreditWalletState> {
  CreditWalletCubit({required CreditRepository repository})
    : _repository = repository,
      super(const CreditWalletState());

  final CreditRepository _repository;

  static const int recentCount = 3;

  /// Tải lại cả ví; đang có dữ liệu thì giữ nguyên trên màn hình khi tải
  Future<void> load() async {
    if (state.status != CreditWalletStatus.ready) {
      emit(state.copyWith(status: CreditWalletStatus.loading));
    }
    try {
      final (wallet, recent) = await (
        _repository.getWallet(),
        _repository.getTransactions(limit: recentCount),
      ).wait;
      if (isClosed) return;
      emit(
        CreditWalletState(
          status: CreditWalletStatus.ready,
          wallet: wallet,
          recent: recent.items,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: CreditWalletStatus.failure));
    }
  }
}
