/**
 * Đơn vị hành chính: tỉnh/thành (province) hoặc phường/xã (ward, có tọa độ tâm).
 * name là tên đầy đủ ("Thành phố Hồ Chí Minh", "Phường Sài Gòn"), shortName là tên ngắn ("Hồ Chí Minh").
 */
export type Unit = {
  code: string;
  name: string;
  shortName?: string;
  level: string;
  parentCode?: string;
  center?: { latitude: number; longitude: number };
};

export type Coordinates = { latitude: number; longitude: number };

/** Dữ liệu địa chỉ phủ toàn quốc; API địa chỉ trả kèm coverage để app biết */
export const LOCATION_COVERAGE = 'full';

/** GPS nằm ngoài mọi ranh giới phường (biển, sát biên) mà xa tâm phường gần nhất quá mức này thì coi như ngoài Việt Nam */
export const MAX_REVERSE_GEOCODE_KM = 30;

/** Trường được phép trong location của tin */
export const LOCATION_KEYS = ['provinceCode', 'wardCode', 'streetAddress', 'latitude', 'longitude', 'geoSource'];

/**
 * Thứ tự hiển thị danh mục mặc định (khớp prisma/seed/categories.ts, seed.ts kiểm tra).
 * Danh mục admin tạo thêm đứng sau, theo tên.
 */
export const CATEGORY_ORDER = ['phones', 'electronics', 'vehicles', 'fashion', 'appliances', 'pets', 'furniture', 'books', 'sports', 'other'];
