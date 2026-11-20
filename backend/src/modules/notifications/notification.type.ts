/**
 * Loại thông báo trong app. Cột Notification.type là chuỗi nên thêm loại mới không cần migration;
 * app dựng câu chữ theo type (đa ngôn ngữ), loại lạ thì hiện title/body server ghi sẵn.
 *
 * Nhóm (group) dùng cho bộ lọc ở trang Thông báo:
 *  - listing: tin đăng của tôi (duyệt, từ chối, bản sửa, hết hạn...)
 *  - wallet: ví Xu, đẩy tin, gói
 *  - activity: người khác tương tác (tin khớp "Báo khi có hàng", theo dõi, lưu tin...)
 *  - system: ReStore gửi chung
 */
export const NOTIFICATION_GROUPS = ['listing', 'wallet', 'activity', 'system'] as const;
export type NotificationGroup = (typeof NOTIFICATION_GROUPS)[number];

export const NOTIFICATION_TYPES = {
  LISTING_APPROVED: 'listing',
  LISTING_REJECTED: 'listing',
  LISTING_CHANGES_REQUESTED: 'listing',
  LISTING_REMOVED: 'listing',
  LISTING_EDIT_APPROVED: 'listing',
  LISTING_EDIT_REJECTED: 'listing',
  LISTING_PUBLISHED: 'listing',
  LISTING_EXPIRING: 'listing',
  LISTING_EXPIRED: 'listing',
  LISTING_AUTO_EXTENDED: 'listing',
  LISTING_AUTO_EXTEND_FAILED: 'listing',
  CREDIT_TOPUP_SUCCESS: 'wallet',
  CREDIT_TOPUP_FAILED: 'wallet',
  CREDIT_REFUNDED: 'wallet',
  CREDIT_BONUS_EXPIRING: 'wallet',
  BOOST_STARTED: 'wallet',
  BOOST_ENDED: 'wallet',
  ORDER_REJECTED: 'wallet',
  STORE_PLAN_ACTIVATED: 'wallet',
  STORE_PLAN_EXPIRING: 'wallet',
  STORE_PLAN_EXPIRED: 'wallet',
  SHOP_POSTER_APPROVED: 'wallet',
  SHOP_POSTER_REJECTED: 'wallet',
  WANTED_ALERT_MATCH: 'activity',
  NEW_FOLLOWER: 'activity',
  LISTING_FAVORITED: 'activity',
  FOLLOWED_NEW_LISTING: 'activity',
  SAVED_LISTING_PRICE_DROP: 'activity',
  SAVED_LISTING_SOLD: 'activity',
  FEED_POST_LIKED: 'activity',
  FEED_POST_COMMENTED: 'activity',
  FEED_COMMENT_REPLIED: 'activity',
  FEED_COMMENT_LIKED: 'activity',
  SYSTEM: 'system',
} as const satisfies Record<string, NotificationGroup>;

export type NotificationType = keyof typeof NOTIFICATION_TYPES;

/**
 * Loại chỉ hiện trong trang Thông báo (cột Push = Không trong tài liệu luồng): ghi sẵn pushedAt nên job không đẩy lên máy.
 * Tin nhắn chat (3.2) thì ngược lại: chỉ push, không ghi dòng nào (xem notifyChatMessage).
 */
export const IN_APP_ONLY_TYPES: ReadonlySet<NotificationType> = new Set<NotificationType>([
  'NEW_FOLLOWER', 'LISTING_FAVORITED', 'FOLLOWED_NEW_LISTING', 'SAVED_LISTING_SOLD',
  'FEED_POST_LIKED', 'FEED_POST_COMMENTED', 'FEED_COMMENT_LIKED',
]);

/** Các loại thuộc nhóm [group] */
export const typesOfGroup = (group: NotificationGroup) =>
  (Object.keys(NOTIFICATION_TYPES) as NotificationType[]).filter((type) => NOTIFICATION_TYPES[type] === group);

/** Nhóm của một loại; loại không có trong danh sách coi là system */
export const groupOf = (type: string): NotificationGroup =>
  (NOTIFICATION_TYPES as Record<string, NotificationGroup>)[type] ?? 'system';

/** Mỗi người giữ tối đa chừng này thông báo, cũ hơn thì xoá khi ghi thêm */
export const MAX_NOTIFICATIONS_PER_USER = 300;
