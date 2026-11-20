import 'package:equatable/equatable.dart';
import 'package:restore/data/models/notification_model.dart';

import '../../models/notification_filter.dart';

enum NotificationsStatus { loading, ready, failure }

class NotificationsState extends Equatable {
  final NotificationFilter filter;
  final NotificationsStatus status;
  final List<NotificationModel> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  const NotificationsState({
    this.filter = NotificationFilter.all,
    this.status = NotificationsStatus.loading,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  bool get hasUnread => items.any((item) => !item.isRead);

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationModel>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) => NotificationsState(
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
