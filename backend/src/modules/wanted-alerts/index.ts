import { onListingApproved } from '../listings/index.js';
import { matchApprovedListing } from './wanted-alert.service.js';

// Admin duyệt tin → chấm điểm với các thông báo "Báo khi có hàng"
onListingApproved(matchApprovedListing);

export { default as wantedAlertRouter } from './wanted-alert.route.js';
export { matchApprovedListing };
