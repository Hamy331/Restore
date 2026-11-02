import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { optionalAuth, requirePermission } from '../../middlewares/auth.middleware.js';
import { requireJson } from '../../middlewares/require-json.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import * as homeController from './home.controller.js';
import { areaQuery, bannerBody, bannerIdParams } from './home.validator.js';

/** /api/v1/home */
const homeRouter = Router();

/**
 * Tên khu vực ở đầu trang chủ. Ưu tiên provinceCode, rồi tới GPS, không có thì "Toàn quốc"
 *
 * Query params:
 *  - provinceCode?: string - mã tỉnh/thành, VD "79"
 *  - latitude?, longitude?: number - phải gửi đủ cả hai
 *
 * Trả về: AreaDto { code: string | null, name }
 */
homeRouter.get('/area', optionalAuth, validate({ query: areaQuery }), homeController.getArea);

/**
 * Banner đang chạy, xếp theo sortOrder tăng dần. Ảnh tỉ lệ 1200 × 600
 *
 * Trả về: HomeBannerDto[] { id, imageUrl, route }
 */
homeRouter.get('/banners', homeController.getBanners);

/* ---------- Quản trị banner ---------- */

const manageBanners = requirePermission(PERMISSION.BANNER_MANAGE);

/**
 * Toàn bộ banner, kể cả đã tắt hoặc hết hạn
 *
 * Trả về: HomeBanner[] (đủ cột)
 */
homeRouter.get('/admin/banners', manageBanners, homeController.adminListBanners);

/**
 * Tạo banner, ghi AdminAudit
 *
 * Body:
 *  - title: string (1-120) - tên nội bộ cho admin
 *  - imageUrl?: string | null - URL http(s) hoặc "/..."
 *  - route?: string | null - đường dẫn trong app, bắt đầu bằng "/"
 *  - sortOrder?: number (0-1000) - mặc định 0
 *  - active?: boolean - mặc định true
 *  - startsAt?, endsAt?: ISO 8601 | null
 *  - reason?: string (≤300) - ghi chú audit
 */
homeRouter.post('/admin/banners', manageBanners, requireJson, validate({ body: bannerBody(false) }), homeController.adminCreateBanner);

/**
 * Sửa banner, chỉ cập nhật trường được gửi (cần ít nhất một trường), ghi AdminAudit
 *
 * Path params:
 *  - id: string - mã banner
 *
 * Body: như khi tạo, mọi trường đều không bắt buộc
 */
homeRouter.put(
  '/admin/banners/:id',
  manageBanners,
  requireJson,
  validate({ params: bannerIdParams, body: bannerBody(true) }),
  homeController.adminUpdateBanner,
);

/**
 * Xóa banner, ghi AdminAudit. Trả 204
 *
 * Path params:
 *  - id: string - mã banner
 */
homeRouter.delete('/admin/banners/:id', manageBanners, validate({ params: bannerIdParams }), homeController.adminDeleteBanner);

export default homeRouter;
