import 'package:restore/data/models/enums/notification_type.dart';

/// Bộ lọc trang Thông báo, khớp query `group` / `unread` của `GET /notifications`
enum NotificationFilter {
  all,
  unread,
  listing(NotificationGroup.listing),
  wallet(NotificationGroup.wallet),
  activity(NotificationGroup.activity);

  const NotificationFilter([this.group]);

  final NotificationGroup? group;

  bool get unreadOnly => this == NotificationFilter.unread;
}
