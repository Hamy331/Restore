import 'package:equatable/equatable.dart';

import '../../models/wanted_alert_item.dart';
import '../../models/wanted_alert_match.dart';

enum WantedAlertDetailStatus { loading, ready, failure }

class WantedAlertDetailState extends Equatable {
  final String alertId;
  final WantedAlertDetailStatus status;

  /// Có sẵn khi mở từ trang quản lý, nếu không thì tải cùng tin khớp
  final WantedAlertItem? alert;
  final List<WantedAlertMatch> matches;

  /// Trang cuối đã tải của [matches]
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isDeleting;

  const WantedAlertDetailState({
    required this.alertId,
    this.status = WantedAlertDetailStatus.loading,
    this.alert,
    this.matches = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isDeleting = false,
  });

  WantedAlertDetailState copyWith({
    WantedAlertDetailStatus? status,
    WantedAlertItem? alert,
    List<WantedAlertMatch>? matches,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isDeleting,
  }) => WantedAlertDetailState(
    alertId: alertId,
    status: status ?? this.status,
    alert: alert ?? this.alert,
    matches: matches ?? this.matches,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isDeleting: isDeleting ?? this.isDeleting,
  );

  @override
  List<Object?> get props => [
    alertId,
    status,
    alert,
    matches,
    page,
    hasMore,
    isLoadingMore,
    isDeleting,
  ];
}
