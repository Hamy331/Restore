import { DASHBOARD_LOG_COUNT } from '../admin.type.js';
import * as dashboardRepository from '../repositories/dashboard.repository.js';

/** Việc đang chờ (tin mới, bản sửa chờ duyệt, báo cáo, đơn), số thành viên / tin đang hoạt động, doanh thu đẩy tin đã xác nhận, 10 dòng nhật ký mới nhất kèm người xử lý */
export const getOverview = () => dashboardRepository.countOverview(DASHBOARD_LOG_COUNT);
