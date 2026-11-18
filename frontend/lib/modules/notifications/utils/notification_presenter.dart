import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/notification_type.dart';
import 'package:restore/data/models/notification_model.dart';
import 'package:restore/l10n/app_localizations.dart';

/// Câu chữ, icon và màu của một thông báo theo loại.
///
/// Câu dựng từ l10n + `data` để đổi ngôn ngữ được; thiếu tham số cần thiết
/// (hoặc loại app chưa biết) thì dùng title / body server ghi sẵn.
class NotificationPresenter {
  NotificationPresenter._();

  static String title(AppLocalizations l10n, NotificationModel item) =>
      switch (item.type) {
        NotificationType.listingApproved => l10n.notifListingApprovedTitle,
        NotificationType.listingRejected => l10n.notifListingRejectedTitle,
        NotificationType.listingChangesRequested =>
          l10n.notifListingChangesTitle,
        NotificationType.listingRemoved => l10n.notifListingRemovedTitle,
        NotificationType.listingEditApproved => l10n.notifEditApprovedTitle,
        NotificationType.listingEditRejected => l10n.notifEditRejectedTitle,
        NotificationType.listingPublished => l10n.notifListingPublishedTitle,
        NotificationType.listingExpiring => l10n.notifListingExpiringTitle,
        NotificationType.listingExpired => l10n.notifListingExpiredTitle,
        NotificationType.creditTopupSuccess => l10n.notifTopupSuccessTitle,
        NotificationType.creditTopupFailed => l10n.notifTopupFailedTitle,
        NotificationType.creditRefunded => l10n.notifRefundTitle,
        NotificationType.creditBonusExpiring => l10n.notifBonusExpiringTitle,
        NotificationType.boostStarted => l10n.notifBoostStartedTitle,
        NotificationType.boostEnded => l10n.notifBoostEndedTitle,
        NotificationType.wantedAlertMatch => l10n.notifWantedMatchTitle,
        NotificationType.newFollower => l10n.notifNewFollowerTitle,
        NotificationType.listingFavorited => l10n.notifFavoritedTitle,
        NotificationType.system || NotificationType.unknown => item.title,
      };

  static String body(AppLocalizations l10n, NotificationModel item) {
    final text = _body(l10n, item);
    if (text == null) return item.body;
    final reason = item.text('reason');
    return reason == null || !_showsReason.contains(item.type)
        ? text
        : '$text ${l10n.notifReason(reason)}';
  }

  /// Các loại kèm lý do của admin
  static const _showsReason = {
    NotificationType.listingRejected,
    NotificationType.listingChangesRequested,
    NotificationType.listingRemoved,
    NotificationType.listingEditRejected,
  };

  static String? _body(AppLocalizations l10n, NotificationModel item) {
    final title = item.text('listingTitle');
    final days = item.number('days');
    final amount = item.number('amount');
    final name = item.text('userName');
    return switch (item.type) {
      NotificationType.listingApproved when title != null =>
        item.data['scheduled'] == true
            ? l10n.notifListingScheduledBody(title)
            : l10n.notifListingApprovedBody(title),
      NotificationType.listingRejected when title != null =>
        l10n.notifListingRejectedBody(title),
      NotificationType.listingChangesRequested when title != null =>
        l10n.notifListingChangesBody(title),
      NotificationType.listingRemoved when title != null =>
        l10n.notifListingRemovedBody(title),
      NotificationType.listingEditApproved when title != null =>
        l10n.notifEditApprovedBody(title),
      NotificationType.listingEditRejected when title != null =>
        l10n.notifEditRejectedBody(title),
      NotificationType.listingPublished when title != null =>
        l10n.notifListingPublishedBody(title),
      NotificationType.listingExpiring when title != null && days != null =>
        l10n.notifListingExpiringBody(title, days),
      NotificationType.listingExpired when title != null =>
        l10n.notifListingExpiredBody(title),
      NotificationType.creditTopupSuccess when amount != null => switch (item
          .number('bonus')) {
        final bonus? when bonus > 0 => l10n.notifTopupSuccessBonusBody(
          amount,
          bonus,
        ),
        _ => l10n.notifTopupSuccessBody(amount),
      },
      NotificationType.creditTopupFailed when item.text('topupCode') != null =>
        l10n.notifTopupFailedBody(item.text('topupCode')!),
      NotificationType.creditRefunded when amount != null =>
        l10n.notifRefundBody(amount),
      NotificationType.creditBonusExpiring
          when amount != null && days != null =>
        l10n.notifBonusExpiringBody(amount, days),
      NotificationType.boostStarted when title != null && days != null =>
        l10n.notifBoostStartedBody(title, days),
      NotificationType.boostEnded when title != null =>
        l10n.notifBoostEndedBody(title),
      NotificationType.wantedAlertMatch
          when title != null && item.text('alertKeywords') != null =>
        l10n.notifWantedMatchBody(title, item.text('alertKeywords')!),
      NotificationType.newFollower when name != null =>
        l10n.notifNewFollowerBody(name),
      NotificationType.listingFavorited when name != null && title != null =>
        l10n.notifFavoritedBody(name, title),
      _ => null,
    };
  }

  static IconData icon(NotificationType type) => switch (type) {
    NotificationType.listingApproved ||
    NotificationType.listingEditApproved ||
    NotificationType.listingPublished => AppIcons.checkCircle,
    NotificationType.listingRejected ||
    NotificationType.listingRemoved => AppIcons.block,
    NotificationType.listingChangesRequested ||
    NotificationType.listingEditRejected => AppIcons.edit,
    NotificationType.listingExpiring ||
    NotificationType.listingExpired => AppIcons.clock,
    NotificationType.creditTopupSuccess ||
    NotificationType.creditTopupFailed => AppIcons.wallet,
    NotificationType.creditRefunded => AppIcons.refresh,
    NotificationType.creditBonusExpiring => AppIcons.sparkle,
    NotificationType.boostStarted ||
    NotificationType.boostEnded => AppIcons.boost,
    NotificationType.wantedAlertMatch => AppIcons.wantedAlert,
    NotificationType.newFollower => AppIcons.followUser,
    NotificationType.listingFavorited => AppIcons.favoriteActive,
    NotificationType.system ||
    NotificationType.unknown => AppIcons.notification,
  };

  /// Màu nhấn của icon (nền icon là màu này nhạt)
  static Color color(NotificationType type) => switch (type) {
    NotificationType.listingApproved ||
    NotificationType.listingEditApproved ||
    NotificationType.listingPublished ||
    NotificationType.creditTopupSuccess => AppColors.success,
    NotificationType.listingRejected ||
    NotificationType.listingRemoved ||
    NotificationType.creditTopupFailed ||
    NotificationType.listingFavorited => AppColors.error,
    NotificationType.listingChangesRequested ||
    NotificationType.listingEditRejected ||
    NotificationType.listingExpiring ||
    NotificationType.creditBonusExpiring => AppColors.warning,
    NotificationType.listingExpired => AppColors.textSecondary,
    NotificationType.boostStarted ||
    NotificationType.boostEnded ||
    NotificationType.wantedAlertMatch => AppColors.primaryDark,
    NotificationType.creditRefunded ||
    NotificationType.newFollower ||
    NotificationType.system ||
    NotificationType.unknown => AppColors.info,
  };
}
