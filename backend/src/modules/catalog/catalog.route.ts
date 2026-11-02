import { Router } from 'express';
import { validate } from '../../middlewares/validate.middleware.js';
import * as catalogController from './catalog.controller.js';
import { provinceParams, reverseGeocodeQuery } from './catalog.validator.js';

/** Dữ liệu tham chiếu công khai, gắn tại /api/v1/catalog */
const catalogRouter = Router();

/**
 * Tình trạng sản phẩm đang dùng
 *
 * Trả về: ConditionPolicy[] { condition, name, active, updatedAt }
 */
catalogRouter.get('/conditions', catalogController.listConditions);

/**
 * Danh mục đang dùng, theo thứ tự hiển thị
 *
 * Trả về: [{ id, name: { vi, en }, description, icon, imageUrl, attributes: [...] }]
 */
catalogRouter.get('/categories', catalogController.listCategories);

/**
 * Tỉnh/thành có dữ liệu
 *
 * Trả về: { data: Unit[], coverage: 'sample' }
 */
catalogRouter.get('/locations/provinces', catalogController.listProvinces);

/**
 * Phường/xã của một tỉnh
 *
 * Path params:
 *  - code: string - mã tỉnh
 *
 * Trả về: { data: Unit[] (kèm center), coverage: 'sample' }; 404 LOCATION_NOT_FOUND nếu chưa có dữ liệu
 */
catalogRouter.get('/locations/provinces/:code/wards', validate({ params: provinceParams }), catalogController.listWards);

/**
 * Phường gần GPS nhất (trong 30 km)
 *
 * Query params:
 *  - latitude: number
 *  - longitude: number
 *
 * Trả về: { data: { province, ward }, coverage: 'sample' }; 404 LOCATION_NOT_FOUND nếu ngoài vùng dữ liệu
 */
catalogRouter.get('/locations/reverse-geocode', validate({ query: reverseGeocodeQuery }), catalogController.reverseGeocode);

export default catalogRouter;
