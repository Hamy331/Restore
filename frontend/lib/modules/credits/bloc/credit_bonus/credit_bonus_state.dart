import 'package:equatable/equatable.dart';

import '../../models/credit_bonus_batch.dart';

enum CreditBonusStatus { loading, ready, failure }

class CreditBonusState extends Equatable {
  final CreditBonusStatus status;

  /// Từng lần tặng còn xu, gần hết hạn trước
  final List<CreditBonusBatch> items;

  const CreditBonusState({
    this.status = CreditBonusStatus.loading,
    this.items = const [],
  });

  /// Tổng xu tặng còn trong ví
  int get total => items.fold(0, (sum, item) => sum + item.amount);

  @override
  List<Object?> get props => [status, items];
}
