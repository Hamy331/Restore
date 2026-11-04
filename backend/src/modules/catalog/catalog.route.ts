import { Router } from 'express';
import { validate } from '../../middlewares/validate.middleware.js';
import * as catalogController from './catalog.controller.js';
import { addressSuggestQuery, areaSearchQuery, provinceParams, reverseGeocodeQuery } from './catalog.validator.js';

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
 * 34 tỉnh/thành (tên đầy đủ name, tên ngắn shortName)
 *
 * Trả về: { data: Unit[], coverage: 'full' }
 */
catalogRouter.get('/locations/provinces', catalogController.listProvinces);

/**
 * Phường/xã của một tỉnh
 *
 * Path params:
 *  - code: string - mã tỉnh
 *
 * Trả về: { data: Unit[] (kèm center), coverage: 'full' }; 404 LOCATION_NOT_FOUND nếu sai mã tỉnh
 */
catalogRouter.get('/locations/provinces/:code/wards', validate({ params: provinceParams }), catalogController.listWards);

/**
 * Phường/xã và tỉnh chứa điểm GPS (theo ranh giới; ngoài khơi gần bờ lấy phường gần nhất trong 30 km)
 *
 * Query params:
 *  - latitude: number
 *  - longitude: number
 *
 * Trả về: { data: { province, ward }, coverage: 'full' }; 404 LOCATION_NOT_FOUND nếu ngoài Việt Nam
 */
catalogRouter.get('/locations/reverse-geocode', validate({ query: reverseGeocodeQuery }), catalogController.reverseGeocode);

/**
 * Tìm tỉnh/thành, phường/xã theo tên (không phân biệt dấu), cho trang chọn khu vực
 *
 * Query params:
 *  - q: string - 1 đến 100 ký tự
 *  - limit: number - 1 đến 50, mặc định 20
 *
 * Trả về: { data: [{ code, name, shortName, level, parentName?, center }], coverage: 'full' }
 */
catalogRouter.get('/locations/search', validate({ query: areaSearchQuery }), catalogController.searchAreas);

/**
 * Gợi ý số nhà, tên đường khi nhập địa chỉ (nguồn chọn bằng ADDRESS_PROVIDER: photon | off; Photon/OpenStreetMap miễn phí)
 *
 * Query params:
 *  - q: string - 2 đến 120 ký tự
 *  - provinceCode, wardCode: string - tuỳ chọn, ưu tiên kết quả quanh đó (Photon lọc theo tỉnh)
 *  - limit: number - 1 đến 10, mặc định 6
 *
 * Trả về: [{ label, description, provinceCode?, wardCode?, latitude?, longitude? }];
 * 502 ADDRESS_SUGGEST_UNAVAILABLE khi nguồn gợi ý lỗi hoặc quá 4 giây
 */
catalogRouter.get('/locations/address-suggest', validate({ query: addressSuggestQuery }), catalogController.suggestAddress);

export default catalogRouter;
