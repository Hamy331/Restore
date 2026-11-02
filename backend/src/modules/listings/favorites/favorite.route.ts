import { Role } from '@prisma/client';
import { Router } from 'express';
import { requireAuth } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as favoriteController from './favorite.controller.js';
import { parseFavoritesQuery, parseListingId } from './favorite.validation.js';

/**
 * Lưu tin (yêu thích), gắn tại /api/v1/listings
 * Mọi API ở đây: bắt buộc đăng nhập, vai trò USER.
 * Header chung: Authorization: Bearer <accessToken>, Accept: application/json
 * Lỗi chung:    401 AUTH_REQUIRED | INVALID_ACCESS_TOKEN | SESSION_REVOKED | ACCOUNT_UNAVAILABLE,
 *               403 FORBIDDEN (tài khoản ADMIN)
 */
const router = Router();
const userOnly = requireAuth(Role.USER);
const withListingId = validate({ params: parseListingId });

/**
 * GET /api/v1/listings/favorites
 * Mô tả:    Tin người dùng đã lưu và vẫn còn hiển thị, mới lưu trước.
 * Query:    page? (mặc định 1), limit? 1-100 (mặc định 20)
 * Trả về:   200 { success, data: Listing[] (isFavorite = true), pagination, meta }
 */
router.get('/favorites', ...userOnly, validate({ query: parseFavoritesQuery }), favoriteController.listFavorites);

/**
 * GET /api/v1/listings/:id/favorite
 * Mô tả:    Người dùng đã lưu tin này chưa.
 * Params:   id  mã tin
 * Trả về:   200 { success, data: boolean }
 */
router.get('/:id/favorite', ...userOnly, withListingId, favoriteController.getFavorite);

/**
 * POST /api/v1/listings/:id/favorite   (PUT cũng được, giữ cho màn hình cũ)
 * Mô tả:    Lưu tin. Gọi lại nhiều lần không tạo bản ghi trùng.
 * Params:   id  mã tin
 * Body:     Không có.
 * Trả về:   200 { success, data: { listingId, isFavorite: true } }
 * Lỗi:      404 LISTING_NOT_FOUND (tin đã ẩn/bán/xóa)
 */
router.post('/:id/favorite', ...userOnly, withListingId, favoriteController.addFavorite);
router.put('/:id/favorite', ...userOnly, withListingId, favoriteController.addFavorite);

/**
 * DELETE /api/v1/listings/:id/favorite
 * Mô tả:    Bỏ lưu tin. Tin chưa được lưu thì vẫn trả thành công.
 * Params:   id  mã tin
 * Trả về:   204 (không có body)
 */
router.delete('/:id/favorite', ...userOnly, withListingId, favoriteController.removeFavorite);

export default router;
