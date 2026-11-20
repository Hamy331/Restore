import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/data/models/enums/notification_type.dart';
import 'package:restore/data/models/notification_model.dart';
import 'package:restore/l10n/app_localizations.dart';
import 'package:restore/modules/shop_posters/models/shop_poster.dart';
import 'package:restore/modules/shop_posters/utils/poster_labels.dart';

/// Câu chữ, icon và màu của một thông báo theo loại.
///
/// Câu dựng từ l10n + `data` để đổi ngôn ngữ được; thiếu tham số cần thiết
/// (hoặc loại app chưa biết) thì dùng title / body server ghi sẵn.
class NotificationPresenter {
  NotificationPresenter._();

  static String title(
    AppLocalizations l10n,
    NotificationModel item,
  ) => switch (item.type) {
    NotificationType.listingApproved => l10n.notifListingApprovedTitle,
    NotificationType.listingRejected => l10n.notifListingRejectedTitle,
    NotificationType.listingChangesRequested => l10n.notifListingChangesTitle,
    NotificationType.listingRemoved => l10n.notifListingRemovedTitle,
    NotificationType.listingEditApproved => l10n.notifEditApprovedTitle,
    NotificationType.listingEditRejected => l10n.notifEditRejectedTitle,
    NotificationType.listingPublished => l10n.notifListingPublishedTitle,
    NotificationType.listingExpiring => l10n.notifListingExpiringTitle,
    NotificationType.listingExpired => l10n.notifListingExpiredTitle,
    NotificationType.listingAutoExtended => l10n.notifAutoExtendedTitle,
    NotificationType.listingAutoExtendFailed => l10n.notifAutoExtendFailedTitle,
    NotificationType.creditTopupSuccess => l10n.notifTopupSuccessTitle,
    NotificationType.creditTopupFailed => l10n.notifTopupFailedTitle,
    NotificationType.creditRefunded => l10n.notifRefundTitle,
    NotificationType.creditBonusExpiring => l10n.notifBonusExpiringTitle,
    NotificationType.boostStarted =>
      _featured(item)
          ? l10n.notifFeatureStartedTitle
          : l10n.notifBoostStartedTitle,
    NotificationType.boostEnded =>
      _featured(item) ? l10n.notifFeatureEndedTitle : l10n.notifBoostEndedTitle,
    NotificationType.orderRejected => l10n.notifOrderRejectedTitle,
    NotificationType.planActivated => l10n.notifPlanActivatedTitle,
    NotificationType.planExpiring => l10n.notifPlanExpiringTitle,
    NotificationType.planExpired => l10n.notifPlanExpiredTitle,
    NotificationType.posterApproved => l10n.notifPosterApprovedTitle,
    NotificationType.posterRejected => l10n.notifPosterRejectedTitle,
    NotificationType.wantedAlertMatch => l10n.notifWantedMatchTitle,
    NotificationType.newFollower =>
      item.text('shopName') != null
          ? l10n.notifShopFollowerTitle
          : l10n.notifNewFollowerTitle,
    NotificationType.listingFavorited => l10n.notifFavoritedTitle,
    NotificationType.followedNewListing => l10n.notifFollowedListingTitle,
    NotificationType.savedListingPriceDrop => l10n.notifPriceDropTitle,
    NotificationType.savedListingSold =>
      item.data['exchanged'] == true
          ? l10n.notifSavedExchangedTitle
          : l10n.notifSavedSoldTitle,
    NotificationType.feedPostLiked => l10n.notifPostLikedTitle,
    NotificationType.feedPostCommented => l10n.notifPostCommentedTitle,
    NotificationType.feedCommentReplied => l10n.notifCommentRepliedTitle,
    NotificationType.feedCommentLiked => l10n.notifCommentLikedTitle,
    NotificationType.chatMessage => _chatTitle(l10n, item),
    NotificationType.system || NotificationType.unknown => item.title,
  };

  /// Tên người gửi, kèm số tin chưa đọc khi nhiều hơn một
  static String _chatTitle(AppLocalizations l10n, NotificationModel item) {
    final name = item.text('senderName');
    final count = item.number('count');
    if (name == null) return item.title;
    return count != null && count > 1
        ? l10n.notifChatManyTitle(name, count)
        : name;
  }

  /// Giá VND như "199.000 đ"
  static String? _price(NotificationModel item, String key) {
    final value = num.tryParse(item.text(key) ?? '');
    return value == null
        ? null
        : '${NumberFormat.decimalPattern('vi').format(value)} đ';
  }

  static String body(AppLocalizations l10n, NotificationModel item) {
    final text = _body(l10n, item);
    if (text == null) return item.body;
    final reason = item.type == NotificationType.posterRejected
        ? _posterReason(l10n, item)
        : item.text('reason');
    final withReason = reason == null || !_showsReason.contains(item.type)
        ? text
        : '$text ${l10n.notifReason(reason)}';
    // Xu giữ khi gửi tin được hoàn: gộp vào thông báo từ chối
    final refunded = item.number('refunded');
    return refunded == null || refunded <= 0
        ? withReason
        : '$withReason ${l10n.notifRefundIncluded(refunded)}';
  }

  static bool _featured(NotificationModel item) =>
      item.text('kind') == 'FEATURED';

  /// Lý do từ chối poster: nhãn theo mã (đa ngôn ngữ) kèm ghi chú của admin
  static String? _posterReason(AppLocalizations l10n, NotificationModel item) {
    final code = PosterRejectReason.fromApi(item.text('reasonCode'));
    final note = item.text('note');
    final label = code == null ? null : l10n.rejectReason(code);
    final parts = [label, note].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(': ');
  }

  /// Ngày hết hạn của gói (dd/MM/yyyy như trang Gói)
  static String? _date(NotificationModel item) {
    final value = DateTime.tryParse(item.text('endsAt') ?? '');
    return value == null
        ? null
        : DateFormat('dd/MM/yyyy').format(value.toLocal());
  }

  /// Các loại kèm lý do của admin
  static const _showsReason = {
    NotificationType.listingRejected,
    NotificationType.listingChangesRequested,
    NotificationType.listingRemoved,
    NotificationType.listingEditRejected,
    NotificationType.orderRejected,
    NotificationType.posterRejected,
  };

  static String? _body(AppLocalizations l10n, NotificationModel item) {
    final title = item.text('listingTitle');
    final days = item.number('days');
    final amount = item.number('amount');
    final name = item.text('userName');
    final plan = item.text('planName') ?? item.text('packageName');
    final date = _date(item);
    final poster = item.text('posterTitle');
    final comment = item.text('commentText');
    // Thông báo gộp: số người khác ngoài người mới nhất
    final others = ((item.number('count') ?? 1) - 1).clamp(0, 1 << 30).toInt();
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
      NotificationType.listingAutoExtended
          when title != null && days != null && amount != null =>
        l10n.notifAutoExtendedBody(title, days, amount),
      NotificationType.listingAutoExtendFailed when title != null =>
        l10n.notifAutoExtendFailedBody(title),
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
        _featured(item)
            ? l10n.notifFeatureStartedBody(title, days)
            : l10n.notifBoostStartedBody(title, days),
      NotificationType.boostEnded when title != null =>
        _featured(item)
            ? l10n.notifFeatureEndedBody(title)
            : l10n.notifBoostEndedBody(title),
      NotificationType.orderRejected when plan != null =>
        item.text('orderKind') == 'PROMOTION_ORDER'
            ? l10n.notifPromotionOrderRejectedBody(plan, title ?? '')
            : l10n.notifPlanOrderRejectedBody(plan),
      NotificationType.planActivated when plan != null && date != null =>
        l10n.notifPlanActivatedBody(plan, date),
      NotificationType.planExpiring when plan != null && date != null =>
        l10n.notifPlanExpiringBody(plan, date),
      NotificationType.planExpired when plan != null =>
        l10n.notifPlanExpiredBody(plan),
      NotificationType.posterApproved when poster != null =>
        l10n.notifPosterApprovedBody(poster),
      NotificationType.posterRejected when poster != null =>
        l10n.notifPosterRejectedBody(poster),
      NotificationType.wantedAlertMatch
          when title != null && item.text('alertKeywords') != null =>
        l10n.notifWantedMatchBody(title, item.text('alertKeywords')!),
      NotificationType.newFollower
          when name != null && item.text('shopName') != null =>
        l10n.notifShopFollowerBody(name, item.text('shopName')!),
      NotificationType.newFollower when name != null =>
        l10n.notifNewFollowerBody(name),
      NotificationType.listingFavorited
          when name != null && title != null && others > 0 =>
        l10n.notifFavoritedManyBody(name, others, title),
      NotificationType.listingFavorited when name != null && title != null =>
        l10n.notifFavoritedBody(name, title),
      NotificationType.followedNewListing when name != null && title != null =>
        item.data['shop'] == true
            ? l10n.notifFollowedShopListingBody(name, title)
            : l10n.notifFollowedListingBody(name, title),
      NotificationType.savedListingPriceDrop when title != null => switch ((
        _price(item, 'oldPrice'),
        _price(item, 'price'),
      )) {
        (final from?, final to?) => l10n.notifPriceDropBody(title, from, to),
        _ => null,
      },
      NotificationType.savedListingSold when title != null =>
        item.data['exchanged'] == true
            ? l10n.notifSavedExchangedBody(title)
            : l10n.notifSavedSoldBody(title),
      NotificationType.feedPostLiked when name != null =>
        l10n.notifPostLikedBody(name, others),
      NotificationType.feedCommentLiked when name != null =>
        l10n.notifCommentLikedBody(name, others),
      NotificationType.feedPostCommented when name != null && comment != null =>
        l10n.notifPostCommentedBody(name, comment),
      NotificationType.feedCommentReplied
          when name != null && comment != null =>
        l10n.notifCommentRepliedBody(name, comment),
      NotificationType.chatMessage => item.text('text'),
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
    NotificationType.listingAutoExtended => AppIcons.refresh,
    NotificationType.listingAutoExtendFailed => AppIcons.wallet,
    NotificationType.creditTopupSuccess ||
    NotificationType.creditTopupFailed => AppIcons.wallet,
    NotificationType.creditRefunded => AppIcons.refresh,
    NotificationType.creditBonusExpiring => AppIcons.sparkle,
    NotificationType.boostStarted ||
    NotificationType.boostEnded ||
    NotificationType.orderRejected => AppIcons.boost,
    NotificationType.planActivated ||
    NotificationType.planExpiring ||
    NotificationType.planExpired => AppIcons.pro,
    NotificationType.posterApproved ||
    NotificationType.posterRejected => AppIcons.image,
    NotificationType.wantedAlertMatch => AppIcons.wantedAlert,
    NotificationType.newFollower => AppIcons.followUser,
    NotificationType.listingFavorited ||
    NotificationType.feedPostLiked ||
    NotificationType.feedCommentLiked => AppIcons.favoriteActive,
    NotificationType.followedNewListing => AppIcons.store,
    NotificationType.savedListingPriceDrop => AppIcons.priceDown,
    NotificationType.savedListingSold => AppIcons.buy,
    NotificationType.feedPostCommented ||
    NotificationType.feedCommentReplied ||
    NotificationType.chatMessage => AppIcons.chat,
    NotificationType.system ||
    NotificationType.unknown => AppIcons.notification,
  };

  /// Màu nhấn của icon (nền icon là màu này nhạt)
  static Color color(NotificationType type) => switch (type) {
    NotificationType.listingApproved ||
    NotificationType.listingEditApproved ||
    NotificationType.listingPublished ||
    NotificationType.creditTopupSuccess ||
    NotificationType.planActivated ||
    NotificationType.posterApproved => AppColors.success,
    NotificationType.listingRejected ||
    NotificationType.listingRemoved ||
    NotificationType.creditTopupFailed ||
    NotificationType.orderRejected ||
    NotificationType.posterRejected ||
    NotificationType.listingFavorited ||
    NotificationType.feedPostLiked ||
    NotificationType.feedCommentLiked => AppColors.error,
    NotificationType.listingChangesRequested ||
    NotificationType.listingEditRejected ||
    NotificationType.listingExpiring ||
    NotificationType.listingAutoExtendFailed ||
    NotificationType.creditBonusExpiring ||
    NotificationType.planExpiring => AppColors.warning,
    NotificationType.listingExpired ||
    NotificationType.planExpired ||
    NotificationType.savedListingSold => AppColors.textSecondary,
    NotificationType.boostStarted ||
    NotificationType.boostEnded ||
    NotificationType.wantedAlertMatch ||
    NotificationType.followedNewListing => AppColors.primaryDark,
    NotificationType.savedListingPriceDrop => AppColors.success,
    NotificationType.creditRefunded ||
    NotificationType.listingAutoExtended ||
    NotificationType.newFollower ||
    NotificationType.feedPostCommented ||
    NotificationType.feedCommentReplied ||
    NotificationType.chatMessage ||
    NotificationType.system ||
    NotificationType.unknown => AppColors.info,
  };
}
