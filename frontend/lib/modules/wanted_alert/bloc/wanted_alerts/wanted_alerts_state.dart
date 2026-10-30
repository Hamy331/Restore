import 'package:equatable/equatable.dart';

import '../../models/wanted_alert_item.dart';

enum WantedAlertsStatus { loading, ready, failure }

class WantedAlertsState extends Equatable {
  final WantedAlertsStatus status;
  final List<WantedAlertItem> items;

  const WantedAlertsState({
    this.status = WantedAlertsStatus.loading,
    this.items = const [],
  });

  /// Tổng số tin khớp chưa xem của mọi thông báo
  int get newMatchCount =>
      items.fold(0, (total, item) => total + item.newMatchCount);

  WantedAlertsState copyWith({
    WantedAlertsStatus? status,
    List<WantedAlertItem>? items,
  }) => WantedAlertsState(
    status: status ?? this.status,
    items: items ?? this.items,
  );

  @override
  List<Object?> get props => [status, items];
}
