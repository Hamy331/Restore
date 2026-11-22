import { on } from '../../common/events/domain-events.js';
import { onListingModerated } from '../listings/index.js';
import {
  notifyBonusExpiring, notifyListingAutoExtended, notifyListingAutoExtendFailed, notifyListingExpired, notifyListingExpiring,
  notifyListingModerated, notifyListingPublished, notifyOrderRejected, notifyPlanActivated, notifyPlanExpired, notifyPlanExpiring,
  notifyPosterReviewed, notifyPromotionEnded, notifyPromotionStarted, notifyShopReviewed, notifyTopupFailed, notifyTopupPaid,
} from './notification.listeners.js';
import {
  notifyActivityOnModeration, notifyChatMessage, notifyCommentLiked, notifyFeedCommented, notifyFollowersOnPublish,
  notifyListingFavorited, notifyListingSold, notifyPostLiked, notifyUserFollowed, notifyWantedAlertMatched,
} from './notification.activity.js';

// Admin ra quyết định trên tin → báo người bán
onListingModerated(notifyListingModerated);
// Tin hẹn ngày đăng đã hiển thị
on('listing.published', notifyListingPublished);
// Tin sắp hết hạn
on('listing.expiring', notifyListingExpiring);
// Tin hết hạn, tự gia hạn thành công / thiếu xu
on('listing.expired', notifyListingExpired);
on('listing.autoExtended', notifyListingAutoExtended);
on('listing.autoExtendFailed', notifyListingAutoExtendFailed);
// Ví Xu, đẩy tin, gói, poster (mục 2)
on('credit.topupPaid', notifyTopupPaid);
on('credit.topupFailed', notifyTopupFailed);
on('credit.bonusExpiring', notifyBonusExpiring);
on('promotion.started', notifyPromotionStarted);
on('promotion.ended', notifyPromotionEnded);
on('order.rejected', notifyOrderRejected);
on('plan.activated', notifyPlanActivated);
on('plan.expiring', notifyPlanExpiring);
on('plan.expired', notifyPlanExpired);
on('poster.reviewed', notifyPosterReviewed);
on('shop.reviewed', notifyShopReviewed);
// Hoạt động giữa người dùng (mục 3)
on('wantedAlert.matched', notifyWantedAlertMatched);
on('chat.messageSent', notifyChatMessage);
on('user.followed', notifyUserFollowed);
on('listing.favorited', notifyListingFavorited);
onListingModerated(notifyActivityOnModeration);
on('listing.published', notifyFollowersOnPublish);
on('listing.sold', notifyListingSold);
on('feed.postLiked', notifyPostLiked);
on('feed.commentLiked', notifyCommentLiked);
on('feed.commented', notifyFeedCommented);

export { default as notificationRouter } from './notification.route.js';
export { notify } from './notification.service.js';
export type { NotificationInput } from './notification.service.js';
export type { NotificationGroup, NotificationType } from './notification.type.js';
