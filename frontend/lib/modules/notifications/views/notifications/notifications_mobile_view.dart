import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/data/models/notification_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_page_header.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/app_load_error_view.dart';
import 'package:restore/shared/widgets/glass/app_glass_background.dart';
import 'package:restore/shared/widgets/loading/app_load_more.dart';
import 'package:restore/shared/widgets/loading/app_loading_indicator.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/notifications/notifications_cubit.dart';
import '../../bloc/notifications/notifications_state.dart';
import '../../models/notification_filter.dart';
import 'widgets/notification_filter_chips.dart';
import 'widgets/notification_section.dart';

class NotificationsMobileView extends StatelessWidget {
  const NotificationsMobileView({super.key});

  /// Bấm thông báo: đánh dấu đã đọc rồi mở trang liên quan (nếu có)
  void _open(BuildContext context, NotificationModel item) {
    context.read<NotificationsCubit>().markRead(item);
    final link = item.link;
    if (link != null && link.startsWith('/')) context.push(link);
  }

  Future<void> _delete(BuildContext context, NotificationModel item) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await context.read<NotificationsCubit>().delete(item);
    if (!context.mounted) return;
    if (ok) {
      TSnackBarHelper.showSuccess(context, message: l10n.notificationsDeleted);
    } else {
      TSnackBarHelper.showError(
        context,
        message: l10n.notificationsDeleteFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NotificationsCubit>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGlassBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: AppPageTitleRow(
                    title: l10n.notifications,
                    onBack: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    trailing: IconButton(
                      tooltip: l10n.notificationsMarkAllRead,
                      onPressed: state.hasUnread ? cubit.markAllRead : null,
                      icon: Icon(
                        AppIcons.readAll,
                        size: 22,
                        color: state.hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                NotificationFilterChips(
                  selected: state.filter,
                  onChanged: cubit.filterChanged,
                ),
                const SizedBox(height: 12),
                Expanded(child: _body(context, l10n, state)),
              ],
            ),
          ),
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
        return AppLoadErrorView(
          title: l10n.notificationsLoadError,
          onRetry: cubit.load,
        );
      case NotificationsStatus.ready when state.items.isEmpty:
        return AppPullToRefresh(
          onRefresh: cubit.load,
          child: ListView(
            children: [
              SizedBox(
                height: 420,
                child: FeedbackView(
                  icon: AppIcons.notification,
                  title: state.filter == NotificationFilter.all
                      ? l10n.notificationsEmptyTitle
                      : l10n.notificationsEmptyFiltered,
                  message: state.filter == NotificationFilter.all
                      ? l10n.notificationsEmptyMessage
                      : '',
                ),
              ),
            ],
          ),
        );
      case NotificationsStatus.ready:
        final today = DateUtils.dateOnly(DateTime.now());
        final recent = [
          for (final item in state.items)
            if (!item.createdAt.isBefore(today)) item,
        ];
        final earlier = [
          for (final item in state.items)
            if (item.createdAt.isBefore(today)) item,
        ];
        return AppPullToRefresh(
          onRefresh: cubit.load,
          child: AppLoadMoreListener(
            onLoadMore: cubit.loadMore,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                if (recent.isNotEmpty)
                  NotificationSection(
                    label: l10n.notificationsToday,
                    items: recent,
                    onTap: (item) => _open(context, item),
                    onDelete: (item) => _delete(context, item),
                  ),
                if (recent.isNotEmpty && earlier.isNotEmpty)
                  const SizedBox(height: 16),
                if (earlier.isNotEmpty)
                  NotificationSection(
                    label: l10n.notificationsEarlier,
                    items: earlier,
                    onTap: (item) => _open(context, item),
                    onDelete: (item) => _delete(context, item),
                  ),
                AppLoadMoreFooter(
                  isLoading: state.loadingMore,
                  hasMore: state.hasMore,
                ),
              ],
            ),
          ),
        );
    }
  }
}
