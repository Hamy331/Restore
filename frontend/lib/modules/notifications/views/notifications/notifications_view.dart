import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/ui/layouts/t_responsive_layout.dart';

import '../../bloc/notification_badge/notification_badge_cubit.dart';
import '../../bloc/notifications/notifications_cubit.dart';
import '../../repositories/notification_repository.dart';
import '../../services/push_messaging_service.dart';
import 'notifications_mobile_view.dart';

/// Route `/notifications`: thông báo của tôi, lọc theo nhóm, đọc / xoá
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key, this.repository});

  static const String path = '/notifications';

  final NotificationRepository? repository;

  /// Repository theo USE_MOCK_DATA (dùng chung cho chấm đỏ trên chuông)
  static NotificationRepository createRepository() => AppEnvironment.useMockData
      ? MockNotificationRepository()
      : ApiNotificationRepository();

  @override
  Widget build(BuildContext context) {
    final repository = this.repository ?? createRepository();
    NotificationBadgeCubit? badge;
    PushMessagingService? push;
    try {
      badge = context.read<NotificationBadgeCubit>();
      push = context.read<PushMessagingService>();
    } catch (_) {
      // Trang mở ngoài app chính (test, admin preview): không có chấm đỏ / push
    }
    return BlocProvider(
      create: (_) => NotificationsCubit(
        repository: repository,
        badge: badge,
        updates: push?.received,
      )..load(),
      child: const TResponsiveLayout(mobile: NotificationsMobileView()),
    );
  }
}
