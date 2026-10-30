import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/utils/helpers/t_snackbar_helper.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/shared/widgets/app_bottom_action_bar.dart';
import 'package:restore/shared/widgets/app_circle_icon_button.dart';
import 'package:restore/shared/widgets/feedback_view.dart';
import 'package:restore/shared/widgets/loading/app_pull_to_refresh.dart';

import '../../bloc/wanted_alerts/wanted_alerts_cubit.dart';
import '../../bloc/wanted_alerts/wanted_alerts_state.dart';
import '../../models/wanted_alert_item.dart';
import '../../widgets/wanted_alert_delete_sheet.dart';
import '../../widgets/wanted_alert_glass_scaffold.dart';
import '../../widgets/wanted_alert_page_header.dart';
import '../wanted_alert_create/wanted_alert_create_view.dart';
import '../wanted_alert_detail/wanted_alert_detail_view.dart';
import 'widgets/wanted_alert_card.dart';
import 'widgets/wanted_alerts_skeleton.dart';

class WantedAlertsMobileView extends StatefulWidget {
  const WantedAlertsMobileView({super.key});

  @override
  State<WantedAlertsMobileView> createState() => _WantedAlertsMobileViewState();
}

class _WantedAlertsMobileViewState extends State<WantedAlertsMobileView> {
  void _back() => context.canPop() ? context.pop() : context.go('/home');

  /// Mở trang tạo; tạo xong thì thêm lên đầu danh sách
  Future<void> _create() async {
    final cubit = context.read<WantedAlertsCubit>();
    final item = await context.push<WantedAlertItem>(
      WantedAlertCreateView.location(fromAlerts: true),
    );
    if (item != null) cubit.added(item);
  }

  /// Mở chi tiết; trang chi tiết trả về true nếu đã xoá thông báo
  Future<void> _open(WantedAlertItem item) async {
    final cubit = context.read<WantedAlertsCubit>();
    final deleted = await context.push<bool>(
      WantedAlertDetailView.location(item.id),
      extra: item,
    );
    if (deleted == true) {
      cubit.removed(item.id);
    } else {
      cubit.seen(item.id);
    }
  }

  Future<bool> _confirmDelete(WantedAlertItem item) =>
      confirmDeleteWantedAlert(context, keywords: item.alert.keywords);

  Future<void> _delete(WantedAlertItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final deleted = await context.read<WantedAlertsCubit>().delete(item);
    if (!mounted) return;
    deleted
        ? TSnackBarHelper.showSuccess(context, message: l10n.wantedAlertDeleted)
        : TSnackBarHelper.showError(
            context,
            message: l10n.wantedAlertDeleteError,
          );
  }

  Future<void> _deleteWithConfirm(WantedAlertItem item) async {
    if (await _confirmDelete(item)) await _delete(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<WantedAlertsCubit, WantedAlertsState>(
      builder: (context, state) {
        final hasItems =
            state.status == WantedAlertsStatus.ready && state.items.isNotEmpty;
        return WantedAlertGlassScaffold(
          header: WantedAlertPageHeader(
            title: l10n.wantedAlertTitle,
            subtitle: hasItems
                ? l10n.wantedAlertActiveCount(state.items.length)
                : l10n.wantedAlertSubtitle,
            onBack: _back,
            trailing: AppCircleIconButton(
              icon: AppIcons.add,
              tooltip: l10n.wantedAlertNew,
              iconColor: AppColors.primaryDark,
              onTap: _create,
            ),
          ),
          bodyBuilder: (context, topInset) => _content(state, topInset),
          bottomNavigationBar: hasItems
              ? AppBottomActionBar(
                  primaryLabel: l10n.wantedAlertNew,
                  primaryIcon: AppIcons.wantedAlert,
                  onPrimary: _create,
                )
              : null,
        );
      },
    );
  }

  Widget _content(WantedAlertsState state, double topInset) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<WantedAlertsCubit>();

    switch (state.status) {
      case WantedAlertsStatus.loading:
        return WantedAlertsSkeleton(topInset: topInset);
      case WantedAlertsStatus.failure:
        return _below(
          topInset,
          FeedbackView(
            icon: AppIcons.offline,
            title: l10n.wantedAlertLoadErrorTitle,
            message: l10n.wantedAlertLoadErrorBody,
            action: FilledButton(
              onPressed: cubit.load,
              child: Text(l10n.retry),
            ),
          ),
        );
      case WantedAlertsStatus.ready:
        break;
    }

    if (state.items.isEmpty) {
      return _below(
        topInset,
        FeedbackView(
          icon: AppIcons.wantedAlert,
          title: l10n.wantedAlertEmptyTitle,
          message: l10n.wantedAlertEmptyBody,
          action: FilledButton.icon(
            onPressed: _create,
            icon: const Icon(AppIcons.add, size: 18),
            label: Text(l10n.wantedAlertCreate),
          ),
        ),
      );
    }

    return AppPullToRefresh(
      onRefresh: cubit.refresh,
      indicatorTop: topInset + 8,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 24),
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(item),
            onDismissed: (_) => _delete(item),
            background: const _DeleteBackground(),
            child: WantedAlertCard(
              item: item,
              onTap: () => _open(item),
              onDelete: () => _deleteWithConfirm(item),
            ),
          );
        },
      ),
    );
  }

  /// Nội dung không cuộn (lỗi, trống) đặt dưới phần header nổi
  Widget _below(double topInset, Widget child) => Padding(
    padding: EdgeInsets.only(top: topInset),
    child: child,
  );
}

/// Nền đỏ nhạt hiện ra khi vuốt thẻ sang trái để xoá
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(AppIcons.delete, color: AppColors.error),
    );
  }
}
