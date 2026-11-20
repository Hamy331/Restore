import { onListingApproved } from '../listings/index.js';
import { on } from '../../common/events/domain-events.js';
import { matchApprovedListing, notifyScheduledMatches } from './wanted-alert.service.js';

// Admin duyệt tin → chấm điểm với các thông báo "Báo khi có hàng"
onListingApproved(matchApprovedListing);
// Tin hẹn ngày đăng tới ngày hiển thị → báo người có thông báo đã khớp
on('listing.published', notifyScheduledMatches);

export { default as wantedAlertRouter } from './wanted-alert.route.js';
export { matchApprovedListing };
