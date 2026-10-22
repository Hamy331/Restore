import 'package:equatable/equatable.dart';

import '../../models/area_option.dart';

enum AreaSearchStatus { idle, searching, ready, failure }

class AreaSearchState extends Equatable {
  /// Nội dung đang gõ (đã bỏ khoảng trắng hai đầu)
  final String query;
  final AreaSearchStatus status;
  final List<AreaOption> results;
  final List<AreaOption> recent;

  const AreaSearchState({
    this.query = '',
    this.status = AreaSearchStatus.idle,
    this.results = const [],
    this.recent = const [],
  });

  bool get isTyping => query.isNotEmpty;

  AreaSearchState copyWith({
    String? query,
    AreaSearchStatus? status,
    List<AreaOption>? results,
    List<AreaOption>? recent,
  }) => AreaSearchState(
    query: query ?? this.query,
    status: status ?? this.status,
    results: results ?? this.results,
    recent: recent ?? this.recent,
  );

  @override
  List<Object?> get props => [query, status, results, recent];
}
