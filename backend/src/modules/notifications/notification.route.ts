import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { requirePermission } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import * as notificationController from './notification.controller.js';
import { listQuery, notificationIdParams, registerDeviceBody, unregisterDeviceBody } from './notification.validator.js';

/**
 * /api/v1/notifications: thông báo trong app của người đang đăng nhập.
 * Các module khác ghi thông báo qua notify() (notification.service.ts).
 *
 * NotificationDto: { id, type, group, title, body, data {}, imageUrl, link, isRead, readAt, createdAt }
 */
const notificationRouter = Router();
notificationRouter.use(requirePermission(PERMISSION.NOTIFICATION_READ));

/**
 * Thông báo của tôi, mới trước
 *
 * Query params:
 *  - page?: number - từ 1
 *  - limit?: number (1-50) - mặc định 20
 *  - group?: 'listing' | 'wallet' | 'activity' | 'system'
 *  - unread?: boolean - true chỉ lấy chưa đọc
 *
 * Trả về: NotificationDto[] kèm pagination, meta { page, limit, hasMore }
 */
notificationRouter.get('/', validate({ query: listQuery }), notificationController.list);

/** Số thông báo chưa đọc (chấm đỏ trên chuông). Trả về: { count } */
notificationRouter.get('/unread-count', notificationController.unreadCount);

/**
 * Lưu token FCM của thiết bị này để nhận push (gọi sau khi đăng nhập và khi token đổi). Trả 204
 *
 * Body: { token: string (tối đa 512), platform: 'android' | 'ios' | 'web' }
 */
notificationRouter.post('/devices', validate({ body: registerDeviceBody }), notificationController.registerDevice);

/** Gỡ token của thiết bị này (đăng xuất). Body: { token }. Trả 204 */
notificationRouter.delete('/devices', validate({ body: unregisterDeviceBody }), notificationController.unregisterDevice);

/** Đánh dấu tất cả đã đọc. Trả về: { updated } */
notificationRouter.post('/read-all', notificationController.markAllRead);

/** Đánh dấu một thông báo đã đọc (404 NOTIFICATION_NOT_FOUND). Trả 204 */
notificationRouter.post('/:id/read', validate({ params: notificationIdParams }), notificationController.markRead);

/** Xoá một thông báo (404 NOTIFICATION_NOT_FOUND). Trả 204 */
notificationRouter.delete('/:id', validate({ params: notificationIdParams }), notificationController.remove);

export default notificationRouter;
