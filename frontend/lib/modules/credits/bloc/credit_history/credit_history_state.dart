import 'package:equatable/equatable.dart';
import 'package:restore/data/models/credit_transaction_model.dart';

import '../../models/credit_history_filter.dart';

enum CreditHistoryStatus { loading, ready, failure }

class CreditHistoryState extends Equatable {
  final CreditHistoryFilter filter;
  final CreditHistoryStatus status;
  final List<CreditTransactionModel> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  const CreditHistoryState({
    this.filter = CreditHistoryFilter.all,
    this.status = CreditHistoryStatus.loading,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  CreditHistoryState copyWith({
    CreditHistoryStatus? status,
    List<CreditTransactionModel>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) => CreditHistoryState(
    filter: filter,
    status: status ?? this.status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [
    filter,
    status,
    items,
    page,
    hasMore,
    loadingMore,
  ];
}
