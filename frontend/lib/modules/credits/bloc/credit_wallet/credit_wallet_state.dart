import 'package:equatable/equatable.dart';
import 'package:restore/data/models/credit_transaction_model.dart';

import '../../models/credit_wallet.dart';

enum CreditWalletStatus { loading, ready, failure }

class CreditWalletState extends Equatable {
  final CreditWalletStatus status;
  final CreditWallet wallet;
  final List<CreditTransactionModel> recent;

  const CreditWalletState({
    this.status = CreditWalletStatus.loading,
    this.wallet = const CreditWallet(),
    this.recent = const [],
  });

  CreditWalletState copyWith({CreditWalletStatus? status}) => CreditWalletState(
    status: status ?? this.status,
    wallet: wallet,
    recent: recent,
  );

  @override
  List<Object?> get props => [status, wallet, recent];
}
