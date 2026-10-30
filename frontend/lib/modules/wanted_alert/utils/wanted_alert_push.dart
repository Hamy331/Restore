/// Thông báo đẩy (FCM) backend gửi khi có tin mới khớp một thông báo
/// "Báo khi có hàng". `data` của thông báo:
/// `{ type: 'WANTED_ALERT_MATCH', alertId, listingId, score }`.
/// Bấm vào thông báo thì mở thẳng trang chi tiết tin.
class WantedAlertPush {
  WantedAlertPush._();

  static const String type = 'WANTED_ALERT_MATCH';

  /// Route cần mở cho [data] của thông báo, null nếu không phải loại này
  static String? routeFor(Map<String, dynamic> data) {
    final listingId = data['listingId'];
    if (data['type'] != type || listingId == null) return null;
    return '/listings/$listingId';
  }
}
