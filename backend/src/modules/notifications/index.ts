import { on } from '../../common/events/domain-events.js';
import { onListingModerated } from '../listings/index.js';
import { notifyListingExpiring, notifyListingModerated, notifyListingPublished } from './notification.listeners.js';

// Admin ra quyết định trên tin → báo người bán
onListingModerated(notifyListingModerated);
// Tin hẹn ngày đăng đã hiển thị
on('listing.published', notifyListingPublished);
// Tin sắp hết hạn
on('listing.expiring', notifyListingExpiring);

export { default as notificationRouter } from './notification.route.js';
export { notify } from './notification.service.js';
export type { NotificationInput } from './notification.service.js';
export type { NotificationGroup, NotificationType } from './notification.type.js';
