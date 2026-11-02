import { Role } from '@prisma/client';
import { Router } from 'express';
import { optionalAuth, requireAuth } from '../../middlewares/auth.middleware.js';
import { requireJson } from '../../middlewares/require-json.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import * as homeController from './home.controller.js';
import { parseAreaQuery, parseBannerBody, parseBannerId } from './home.validation.js';

/**
 * Module home, gắn tại /api/v1/home
 * Header chung: Accept: application/json
 */
const router = Router();

/**
 * GET /api/v1/home/area
 * Mô tả:    Tên khu vực hiển thị trên đầu trang chủ.
 * Quyền:    Công khai (khách xem được). Có gửi token thì token phải hợp lệ.
 * Header:   Authorization: Bearer <accessToken>   (không bắt buộc)
 * Query:    provinceCode?  mã tỉnh/thành, VD "79"            (ưu tiên nếu có)
 *           latitude?, longitude?  tọa độ GPS, phải gửi đủ cả hai
 * Trả về:   200 { success, data: { code: string | null, name: string } }
 *           Không xác định được khu vực thì trả { code: null, name: "Toàn quốc" }.
 * Lỗi:      400 INVALID_LOCATION | INVALID_INPUT, 404 AREA_NOT_FOUND
 */
router.get('/area', optionalAuth, validate({ query: parseAreaQuery }), homeController.getArea);

/**
 * GET /api/v1/home/banners
 * Mô tả:    Banner đang chạy ở trang chủ, xếp theo sortOrder tăng dần. Ảnh tỉ lệ 1200 × 600.
 * Quyền:    Công khai.
 * Header:   Không yêu cầu thêm.
 * Tham số:  Không có.
 * Trả về:   200 { success, data: [{ id, imageUrl: string | null, route: string | null }] }
 */
router.get('/banners', homeController.getBanners);

/* ------------------------- Quản trị banner (ADMIN) ------------------------- */

/**
 * GET /api/v1/home/admin/banners
 * Mô tả:    Toàn bộ banner kể cả đã tắt/hết hạn, để admin quản lý.
 * Quyền:    ADMIN.
 * Header:   Authorization: Bearer <accessToken>
 * Trả về:   200 { success, data: HomeBanner[] }  (đủ cột: title, sortOrder, active, startsAt, endsAt...)
 * Lỗi:      401, 403 FORBIDDEN
 */
router.get('/admin/banners', ...requireAuth(Role.ADMIN), homeController.adminListBanners);

/**
 * POST /api/v1/home/admin/banners
 * Mô tả:    Tạo banner mới. Ghi AdminAudit.
 * Quyền:    ADMIN.
 * Header:   Authorization: Bearer <accessToken>, Content-Type: application/json
 * Body:     { title: string (1-120)            bắt buộc, tên nội bộ cho admin
 *             imageUrl?: string | null         URL http(s) hoặc "/..."
 *             route?: string | null            đường dẫn trong app, bắt đầu bằng "/"
 *             sortOrder?: number (0-1000)      mặc định 0
 *             active?: boolean                 mặc định true
 *             startsAt?, endsAt?: ISO 8601 | null
 *             reason?: string (≤300)           ghi chú audit }
 * Trả về:   201 { success, data: HomeBanner }
 * Lỗi:      400 INVALID_INPUT, 401, 403, 415 UNSUPPORTED_MEDIA_TYPE
 */
router.post(
  '/admin/banners',
  ...requireAuth(Role.ADMIN),
  requireJson,
  validate({ body: parseBannerBody(false) }),
  homeController.adminCreateBanner,
);

/**
 * PUT /api/v1/home/admin/banners/:id
 * Mô tả:    Sửa banner, chỉ cập nhật các trường được gửi. Ghi AdminAudit.
 * Quyền:    ADMIN.
 * Header:   Authorization: Bearer <accessToken>, Content-Type: application/json
 * Params:   id  mã banner
 * Body:     giống POST nhưng mọi trường đều không bắt buộc (cần ít nhất một trường).
 * Trả về:   200 { success, data: HomeBanner }
 * Lỗi:      400 INVALID_INPUT, 401, 403, 404 BANNER_NOT_FOUND, 415
 */
router.put(
  '/admin/banners/:id',
  ...requireAuth(Role.ADMIN),
  requireJson,
  validate({ params: parseBannerId, body: parseBannerBody(true) }),
  homeController.adminUpdateBanner,
);

/**
 * DELETE /api/v1/home/admin/banners/:id
 * Mô tả:    Xóa banner. Ghi AdminAudit.
 * Quyền:    ADMIN.
 * Header:   Authorization: Bearer <accessToken>
 * Params:   id  mã banner
 * Trả về:   204 (không có body)
 * Lỗi:      401, 403, 404 BANNER_NOT_FOUND
 */
router.delete(
  '/admin/banners/:id',
  ...requireAuth(Role.ADMIN),
  validate({ params: parseBannerId }),
  homeController.adminDeleteBanner,
);

export default router;
