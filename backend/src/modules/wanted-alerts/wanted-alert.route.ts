import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { requirePermission } from '../../middlewares/auth.middleware.js';
import { requireJson } from '../../middlewares/require-json.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import * as wantedAlertController from './wanted-alert.controller.js';
import { alertIdParams, draftBody, matchesQuery, previewQuery } from './wanted-alert.validator.js';

/**
 * /api/v1/wanted-alerts: "Báo khi có hàng". Mọi đường dẫn cần đăng nhập (người dùng thường).
 * Khi admin duyệt một tin, backend chấm điểm tin đó với các thông báo và ghi tin khớp
 * (xem wanted-alert.matcher.ts). Lưu / bỏ lưu tin dùng /listings/:id/favorite.
 *
 * Body chung của POST / và POST /preview (WantedAlertDraft):
 *  - keywords: string (2-80) - món cần tìm, VD "máy ảnh film Canon"
 *  - categoryId?: string | null
 *  - minPrice?, maxPrice?: number | null - VND, 0..999 999 999 999
 *  - conditions?: ListingCondition[] - rỗng là mọi tình trạng
 *  - dealTypes?: ('buy' | 'exchange')[] - rỗng là mọi kiểu giao dịch
 *  - area?: { code, level: 'province' | 'ward', label? } | null - null là toàn quốc
 *  - matchLevel?: 'BROAD' | 'BALANCED' | 'STRICT' - mặc định BALANCED
 */
const wantedAlertRouter = Router();
wantedAlertRouter.use(requirePermission(PERMISSION.WANTED_ALERT_MANAGE));

/**
 * Thông báo của tôi, mới tạo trước
 *
 * Trả về: WantedAlertDto[] (thêm matchCount, newMatchCount, previewImages tối đa 3 ảnh)
 */
wantedAlertRouter.get('/', wantedAlertController.listAlerts);

/**
 * Tin hiện có gần giống bản nháp, điểm cao nhất trước. Không lưu gì
 *
 * Query params:
 *  - limit?: number (1-50) - mặc định 20
 *
 * Trả về: (Listing + areaLabel, distanceKm, isFeatured, isFavorite, score 0..1)[]
 */
wantedAlertRouter.post('/preview', requireJson, validate({ query: previewQuery, body: draftBody }), wantedAlertController.preview);

/**
 * Tạo thông báo (tối đa 20 mỗi người, 409 WANTED_ALERT_LIMIT). Chỉ tin được duyệt sau lúc tạo mới được tính là khớp
 *
 * Trả về: 201 WantedAlertDto
 */
wantedAlertRouter.post('/', requireJson, validate({ body: draftBody }), wantedAlertController.createAlert);

/**
 * Một thông báo của tôi (404 WANTED_ALERT_NOT_FOUND nếu không phải của tôi)
 *
 * Trả về: WantedAlertDto
 */
wantedAlertRouter.get('/:id', validate({ params: alertIdParams }), wantedAlertController.getAlert);

/** Xóa thông báo (dừng báo). Trả 204 */
wantedAlertRouter.delete('/:id', validate({ params: alertIdParams }), wantedAlertController.deleteAlert);

/**
 * Tin đã khớp còn hiển thị, khớp gần nhất trước
 *
 * Query params:
 *  - page?: number - từ 1
 *  - limit?: number (1-50) - mặc định 10
 *
 * Trả về: (Listing + areaLabel, isFavorite, score, matchedAt, isNew)[] kèm pagination, meta { page, limit, hasMore }
 */
wantedAlertRouter.get('/:id/matches', validate({ params: alertIdParams, query: matchesQuery }), wantedAlertController.listMatches);

/** Đánh dấu đã xem tin khớp: newMatchCount về 0. Trả 204 */
wantedAlertRouter.post('/:id/seen', validate({ params: alertIdParams }), wantedAlertController.markSeen);

export default wantedAlertRouter;
