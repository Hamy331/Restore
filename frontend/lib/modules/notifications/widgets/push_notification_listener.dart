import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:toastification/toastification.dart';

import '../bloc/notification_badge/notification_badge_cubit.dart';
import '../repositories/notification_repository.dart';
import '../services/push_messaging_service.dart';
import '../utils/notification_presenter.dart';

/// Nghe push FCM cho cả app (đặt trong main.dart, dưới các provider):
/// - Push tới khi app đang mở: cập nhật chấm đỏ, hiện banner (bấm để mở).
/// - Bấm thông báo hệ thống: đánh dấu đã đọc rồi mở route của thông báo.
class PushNotificationListener extends StatefulWidget {
  const PushNotificationListener({
    super.key,
    required this.router,
    required this.child,
  });

  /// Router của app: lấy context dưới MaterialApp để hiện banner và mở trang
  final GoRouter router;
  final Widget child;

  @override
  State<PushNotificationListener> createState() =>
      _PushNotificationListenerState();
}

class _PushNotificationListenerState extends State<PushNotificationListener> {
  final List<StreamSubscription<PushNotification>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    final push = context.read<PushMessagingService>();
    _subscriptions
      ..add(push.received.listen(_onReceived))
      ..add(push.opened.listen(_onOpened));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _syncBadge(PushNotification push) {
    final badge = context.read<NotificationBadgeCubit>();
    final count = push.unreadCount;
    count == null ? badge.refresh() : badge.set(count);
  }

  void _onReceived(PushNotification push) {
    if (!mounted) return;
    _syncBadge(push);
    // Context của Navigator nằm trên Overlay của nó, nên đưa thẳng overlay
    // cho toastification (app không bọc ToastificationWrapper)
    final navigator = widget.router.routerDelegate.navigatorKey.currentState;
    final overlay = navigator?.overlay;
    final appContext = overlay?.context;
    if (overlay == null || appContext == null || !appContext.mounted) return;
    final l10n = AppLocalizations.of(appContext);
    if (l10n == null) return;
    final item = push.notification;
    final color = NotificationPresenter.color(item.type);
    toastification.show(
      overlayState: overlay,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      primaryColor: color,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      icon: Icon(
        NotificationPresenter.icon(item.type),
        size: 24.w,
        color: color,
      ),
      title: Text(
        NotificationPresenter.title(l10n, item),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
      ),
      description: Text(
        NotificationPresenter.body(l10n, item),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13.sp),
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 5),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      borderRadius: BorderRadius.circular(12.r),
      showProgressBar: false,
      closeOnClick: false,
      callbacks: ToastificationCallbacks(
        onTap: (toast) {
          toastification.dismiss(toast);
          _onOpened(push);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _onOpened(PushNotification push) async {
    if (!mounted) return;
    final repository = context.read<NotificationRepository>();
    final badge = context.read<NotificationBadgeCubit>();
    final link = push.link;
    if (link != null && link.startsWith('/')) widget.router.push(link);
    try {
      await repository.markRead(push.notification.id);
    } catch (_) {
      // Không đánh dấu được thì để chưa đọc
    }
    await badge.refresh();
  }
}
