/*
 * Đơn vị hành chính toàn quốc: 34 tỉnh/thành và 3.321 phường/xã/đặc khu (sau sắp xếp 2025, cập nhật 2026).
 * Dữ liệu tĩnh, đọc lúc chạy (không lưu DB), sinh bởi scripts/locations/build.py.
 */

export { PROVINCES, WARDS } from './location.units.js';

/**
 * Mã phường của bộ dữ liệu mẫu cũ ("79-SG"...) -> mã chính thức.
 * Tin và nháp tạo trước khi đổi dữ liệu vẫn gửi lại được mã cũ.
 */
export const LEGACY_WARD_CODES: Readonly<Record<string, string>> = {
  '79-SG': '26740', '79-BT': '26743', '79-TD': '26737', '79-BC': '27154', '79-XH': '27139', '79-GV': '26884',
  '79-AK': '27094', '79-THD': '26824', '01-HK': '00070', '01-CN': '00082', '01-BD': '00004', '01-NH': '00008',
  '01-DD': '00235', '01-CG': '00166', '01-HBT': '00256', '48-HC': '20242', '48-HCU': '20257', '48-TK': '20209',
  '48-ST': '20263', '48-NHS': '20285', '31-HB': '11311', '31-LC': '11383', '31-NQ': '11329', '92-NK': '31135',
  '92-CK': '31120', '92-BTH': '31168', '46-PX': '19753', '46-TH': '19789',
};
