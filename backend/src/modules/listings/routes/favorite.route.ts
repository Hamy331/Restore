import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as favoriteController from '../controllers/favorite.controller.js';
import { favoriteIdParams, favoritesQuery } from '../listing.validator.js';

/** Lưu tin (yêu thích), gắn tại /api/v1/listings */
const favoriteRouter = Router();
const canRead = requirePermission(PERMISSION.FAVORITE_READ);
const canWrite = requirePermission(PERMISSION.FAVORITE_WRITE);
const withListingId = validate({ params: favoriteIdParams });

/**
 * Tin đã lưu và vẫn còn hiển thị, mới lưu trước
 *
 * Query params:
 *  - page?: number (mặc định 1)
 *  - limit?: number (1-100, mặc định 20)
 *
 * Trả về: Listing[] (isFavorite = true) + pagination, meta
 */
favoriteRouter.get('/favorites', canRead, validate({ query: favoritesQuery }), favoriteController.listFavorites);

/**
 * Đã lưu tin này chưa
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Trả về: boolean
 */
favoriteRouter.get('/:id/favorite', canRead, withListingId, favoriteController.getFavorite);

/**
 * Lưu tin; gọi lại nhiều lần không tạo trùng. PUT giữ cho màn hình cũ
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Trả về: { listingId, isFavorite: true }
 */
favoriteRouter.post('/:id/favorite', canWrite, withListingId, favoriteController.addFavorite);
favoriteRouter.put('/:id/favorite', canWrite, withListingId, favoriteController.addFavorite);

/**
 * Bỏ lưu tin; tin chưa lưu vẫn trả thành công. Trả 204
 *
 * Path params:
 *  - id: string - mã tin
 */
favoriteRouter.delete('/:id/favorite', canWrite, withListingId, favoriteController.removeFavorite);

export default favoriteRouter;
