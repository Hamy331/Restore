import { DASHBOARD_LOG_COUNT } from '../admin.type.js';
import * as dashboardRepository from '../repositories/dashboard.repository.js';

/** Việc đang chờ, số thành viên / tin đang hoạt động, doanh thu đẩy tin đã xác nhận, 10 dòng nhật ký mới nhất */
export async function getOverview() {
  const [pendingListings, openReports, activeUsers, activeListings, pendingStores, pendingPromotions, revenue, logs] =
    await dashboardRepository.countOverview(DASHBOARD_LOG_COUNT);
  return {
    pendingListings, openReports, activeUsers, activeListings, pendingStores, pendingPromotions,
    promotionRevenue: revenue._sum.amount ?? '0', logs,
  };
}
