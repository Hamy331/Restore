import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { authorizePermission } from '../../../middlewares/auth.middleware.js';
import * as dashboardController from '../controllers/dashboard.controller.js';

/** Tổng quan quản trị, gắn tại /api/v1/admin */
const dashboardRouter = Router();

/**
 * Tổng quan
 *
 * Trả về: { pendingListings, openReports, activeUsers, activeListings, pendingStores, pendingPromotions,
 *           promotionRevenue: string, logs: AdminAudit[10] }
 */
dashboardRouter.get('/dashboard', authorizePermission(PERMISSION.ADMIN_ACCESS), dashboardController.getOverview);

dashboardRouter.get('/dashboard/insights', authorizePermission(PERMISSION.ADMIN_ACCESS), dashboardController.insights);

export default dashboardRouter;
