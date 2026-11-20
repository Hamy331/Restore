import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/modules/notifications/bloc/notification_badge/notification_badge_cubit.dart';
import 'package:restore/shared/widgets/app_count_badge.dart';

import 'home_header_icon_button.dart';

/// Nút chuông ở đầu trang chủ kèm số thông báo chưa đọc
class HomeNotificationButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;

  const HomeNotificationButton({
    super.key,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final button = HomeHeaderIconButton(
      icon: AppIcons.notification,
      tooltip: tooltip,
      onTap: onTap,
    );
    NotificationBadgeCubit? badge;
    try {
      badge = context.read<NotificationBadgeCubit>();
    } catch (_) {
      // Màn hình test / xem trước không cấp cubit: chỉ hiện chuông
    }
    if (badge == null) return button;
    return BlocBuilder<NotificationBadgeCubit, int>(
      bloc: badge,
      builder: (context, count) => AppCountBadge(count: count, child: button),
    );
  }
}
