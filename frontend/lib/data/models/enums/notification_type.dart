/// Nhóm thông báo, khớp `group` của API `/notifications` (bộ lọc trang Thông báo)
enum NotificationGroup {
  listing('listing'),
  wallet('wallet'),
  activity('activity'),
  system('system');

  const NotificationGroup(this.apiValue);

  final String apiValue;

  static NotificationGroup fromApi(String? value) => values.firstWhere(
    (group) => group.apiValue == value,
    orElse: () => NotificationGroup.system,
  );
}

/// Loại thông báo (cột Notification.type). Loại backend thêm sau mà app chưa
/// biết thành [unknown]: app hiện title/body server ghi sẵn.
enum NotificationType {
  listingApproved('LISTING_APPROVED', NotificationGroup.listing),
  listingRejected('LISTING_REJECTED', NotificationGroup.listing),
  listingChangesRequested(
    'LISTING_CHANGES_REQUESTED',
    NotificationGroup.listing,
  ),
  listingRemoved('LISTING_REMOVED', NotificationGroup.listing),
  listingEditApproved('LISTING_EDIT_APPROVED', NotificationGroup.listing),
  listingEditRejected('LISTING_EDIT_REJECTED', NotificationGroup.listing),
  listingPublished('LISTING_PUBLISHED', NotificationGroup.listing),
  listingExpiring('LISTING_EXPIRING', NotificationGroup.listing),
  listingExpired('LISTING_EXPIRED', NotificationGroup.listing),
  listingAutoExtended('LISTING_AUTO_EXTENDED', NotificationGroup.listing),
  listingAutoExtendFailed(
    'LISTING_AUTO_EXTEND_FAILED',
    NotificationGroup.listing,
  ),
  creditTopupSuccess('CREDIT_TOPUP_SUCCESS', NotificationGroup.wallet),
  creditTopupFailed('CREDIT_TOPUP_FAILED', NotificationGroup.wallet),
  creditRefunded('CREDIT_REFUNDED', NotificationGroup.wallet),
  creditBonusExpiring('CREDIT_BONUS_EXPIRING', NotificationGroup.wallet),
  boostStarted('BOOST_STARTED', NotificationGroup.wallet),
  boostEnded('BOOST_ENDED', NotificationGroup.wallet),
  orderRejected('ORDER_REJECTED', NotificationGroup.wallet),
  planActivated('STORE_PLAN_ACTIVATED', NotificationGroup.wallet),
  planExpiring('STORE_PLAN_EXPIRING', NotificationGroup.wallet),
  planExpired('STORE_PLAN_EXPIRED', NotificationGroup.wallet),
  posterApproved('SHOP_POSTER_APPROVED', NotificationGroup.wallet),
  posterRejected('SHOP_POSTER_REJECTED', NotificationGroup.wallet),
  wantedAlertMatch('WANTED_ALERT_MATCH', NotificationGroup.activity),
  newFollower('NEW_FOLLOWER', NotificationGroup.activity),
  listingFavorited('LISTING_FAVORITED', NotificationGroup.activity),
  system('SYSTEM', NotificationGroup.system),
  unknown('', NotificationGroup.system);

  const NotificationType(this.apiValue, this.group);

  final String apiValue;
  final NotificationGroup group;

  static NotificationType fromApi(String? value) => values.firstWhere(
    (type) => type.apiValue == value && type != unknown,
    orElse: () => NotificationType.unknown,
  );
}
