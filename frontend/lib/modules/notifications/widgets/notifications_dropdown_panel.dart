import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/notification_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';

import '../bloc/notification_badge/notification_badge_cubit.dart';
import '../bloc/notifications/notifications_cubit.dart';
import '../bloc/notifications/notifications_state.dart';
import '../models/notification_filter.dart';
import '../services/push_messaging_service.dart';
import '../views/notifications/notifications_view.dart';
import '../views/notifications/widgets/notification_filter_chips.dart';
import '../views/notifications/widgets/notification_tile.dart';

/// Khung thông báo thả xuống từ chuông trên header web desktop: tiêu đề + đánh
/// dấu đã đọc hết, chip lọc, danh sách cuộn và "Xem tất cả" mở trang đầy đủ.
/// Dựng khi mở khung nên mỗi lần mở là một lần tải mới.
class NotificationsDropdownPanel extends StatelessWidget {
  const NotificationsDropdownPanel({super.key, required this.onClose});

  /// Đóng khung (bấm thông báo hoặc "Xem tất cả")
  final VoidCallback onClose;

  static const double width = 420;
  static const double height = 560;

  @override
  Widget build(BuildContext context) {
    NotificationBadgeCubit? badge;
    PushMessagingService? push;
    try {
      badge = context.read<NotificationBadgeCubit>();
      push = context.read<PushMessagingService>();
    } catch (_) {
      // Ngoài app chính (test): không có chấm đỏ / push
    }
    return BlocProvider(
      create: (_) => NotificationsCubit(
        repository: NotificationsView.createRepository(),
        badge: badge,
        updates: push?.received,
      )..load(),
      child: _Panel(onClose: onClose),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.onClose});
  final VoidCallback onClose;

  /// Bấm thông báo: đánh dấu đã đọc, đóng khung rồi mở trang liên quan
  void _open(BuildContext context, NotificationModel item) {
    context.read<NotificationsCubit>().markRead(item);
    final link = item.link;
    onClose();
    if (link != null && link.startsWith('/')) context.push(link);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    final cubit = context.read<NotificationsCubit>();
    return SizedBox(
      width: NotificationsDropdownPanel.width,
      height: NotificationsDropdownPanel.height,
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.notifications,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.notificationsMarkAllRead,
                    onPressed: state.hasUnread ? cubit.markAllRead : null,
                    icon: Icon(
                      AppIcons.readAll,
                      size: 21,
                      color: state.hasUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            NotificationFilterChips(
              selected: state.filter,
              onChanged: cubit.filterChanged,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _body(context, l10n, state)),
            const Divider(height: 1, color: AppColors.border),
            TextButton(
              onPressed: () {
                onClose();
                context.push(NotificationsView.path);
              },
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: AppColors.primaryDark,
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                vi ? 'Xem tất cả' : 'View all',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    NotificationsState state,
  ) {
    final cubit = context.read<NotificationsCubit>();
    switch (state.status) {
      case NotificationsStatus.loading:
        return const Center(child: AppLoadingIndicator());
      case NotificationsStatus.failure:
        return Center(
          child: TextButton(
            onPressed: cubit.load,
            child: Text(l10n.notificationsLoadError),
          ),
        );
      case NotificationsStatus.ready when state.items.isEmpty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              state.filter == NotificationFilter.all
                  ? l10n.notificationsEmptyTitle
                  : l10n.notificationsEmptyFiltered,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        );
      case NotificationsStatus.ready:
        final today = DateUtils.dateOnly(DateTime.now());
        final recent = [
          for (final i in state.items)
            if (!i.createdAt.isBefore(today)) i,
        ];
        final earlier = [
          for (final i in state.items)
            if (i.createdAt.isBefore(today)) i,
        ];
        Widget label(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        );
        Widget tiles(List<NotificationModel> items) => Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: AppColors.border,
                ),
              NotificationTile(
                item: items[i],
                onTap: () => _open(context, items[i]),
              ),
            ],
          ],
        );
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 200) {
              cubit.loadMore();
            }
            return false;
          },
          child: ListView(
            children: [
              if (recent.isNotEmpty) ...[
                label(l10n.notificationsToday),
                tiles(recent),
              ],
              if (earlier.isNotEmpty) ...[
                label(l10n.notificationsEarlier),
                tiles(earlier),
              ],
              AppLoadMoreFooter(
                isLoading: state.loadingMore,
                hasMore: state.hasMore,
              ),
            ],
          ),
        );
    }
  }
}
