import type { ListingCondition, WantedAlertMatchLevel } from '@prisma/client';
import type { DemoListing } from './demo.js';

/*
 * Dữ liệu demo cho "Báo khi có hàng" (chạy cùng `npm run db:seed:demo`).
 *
 * Mỗi thông báo tạo lúc 2 giờ trước nên chưa khớp tin cũ nào ("Chưa có tin khớp").
 * Kèm vài tin CHỜ DUYỆT: duyệt trong trang admin (hoặc chạy `-- --approve`) thì
 * hook chấm điểm chạy và ghi tin khớp. Mỗi tin ghi rõ khớp hay không và vì sao.
 */

export type DemoWantedAlert = {
  /** id = `demo-alert-${key}` */
  key: string;
  keywords: string;
  categoryId: string | null;
  minPrice?: number;
  maxPrice?: number;
  conditions?: ListingCondition[];
  /** 'buy' | 'exchange', rỗng là mọi kiểu */
  dealTypes?: string[];
  /** Giới hạn theo tỉnh của phường này (lấy mã tỉnh từ dữ liệu phường) */
  provinceOfWard?: string;
  areaLabel?: string;
  matchLevel: WantedAlertMatchLevel;
};

export const DEMO_WANTED_ALERTS: DemoWantedAlert[] = [
  // Giống ảnh mẫu: iPhone, Điện thoại, tối đa 500K, Mới, Cân bằng
  { key: 'iphone', keywords: 'iPhone', categoryId: 'phones', maxPrice: 500000, conditions: ['NEW'], matchLevel: 'BALANCED' },
  { key: 'macbook-m2', keywords: 'MacBook Air M2', categoryId: 'electronics', minPrice: 15000000, maxPrice: 20000000, matchLevel: 'BALANCED' },
  { key: 'vision', keywords: 'xe Vision', categoryId: 'vehicles', provinceOfWard: '00235', areaLabel: 'Hà Nội', matchLevel: 'BROAD' },
  { key: 'sofa-swap', keywords: 'sofa', categoryId: 'furniture', dealTypes: ['exchange'], matchLevel: 'STRICT' },
  // Không có tin nào khớp, để xem trạng thái trống
  { key: 'fujifilm', keywords: 'máy ảnh Fujifilm X100V', categoryId: null, matchLevel: 'BALANCED' },
];

/** Ghi chú cho từng tin chờ duyệt: khớp thông báo nào (hoặc vì sao không) */
export type DemoPendingListing = DemoListing & { expect: string };

/** id = `demo-pending-${key}`, tạo 1 giờ trước. Không dùng người bán khoa: khi chạy không có --viewer, khoa là chủ thông báo và tin của chính mình không bao giờ khớp */
export const DEMO_PENDING_LISTINGS: DemoPendingListing[] = [
  {
    key: 'iphone-case', seller: 'demo-seller-ngoc', categoryId: 'phones', expect: 'KHỚP iphone',
    title: 'Ốp lưng iPhone 15 Pro MagSafe mới 100%', description: 'Mua dư 1 cái, còn nguyên seal. Hít MagSafe chắc, viền chống sốc.',
    price: 350000, condition: 'NEW', ward: '26743', attributes: { brand: 'Apple', model: 'iPhone 15 Pro' }, daysAgo: 0,
  },
  {
    key: 'iphone-13-used', seller: 'demo-seller-huy', categoryId: 'phones', expect: 'KHÔNG khớp iphone: tình trạng cũ, giá quá 500K',
    title: 'iPhone 13 128GB xanh, máy cũ', description: 'Máy trầy nhẹ viền, pin 85%. Bán nhanh cho ai cần.',
    price: 6500000, condition: 'USED_GOOD', ward: '00166', attributes: { brand: 'Apple', model: 'iPhone 13', storage: '128 GB' }, daysAgo: 0,
  },
  {
    key: 'macbook-m2-512', seller: 'demo-seller-ha', categoryId: 'electronics', expect: 'KHỚP macbook-m2',
    title: 'MacBook Air M2 16/512 bạc, pin 98%', description: 'Dùng văn phòng nhẹ nhàng, sạc 60 lần. Fullbox, còn bảo hành.',
    price: 19500000, condition: 'LIKE_NEW', ward: '20242', attributes: { device_type: 'laptop', brand: 'Apple', model: 'MacBook Air M2', has_accessories: true }, daysAgo: 0,
  },
  {
    key: 'vision-2023', seller: 'demo-seller-huy', categoryId: 'vehicles', expect: 'KHỚP vision (cùng tỉnh Hà Nội)',
    title: 'Honda Vision 2023 đỏ đen chính chủ', description: 'Đi 5.000 km, bảo dưỡng ở Head. Biển Hà Nội, giấy tờ đầy đủ.',
    price: 31000000, condition: 'LIKE_NEW', ward: '00166', attributes: { vehicle_type: 'motorbike', brand: 'Honda', model: 'Vision', year: 2023, has_papers: true }, daysAgo: 0,
  },
  {
    key: 'vision-hcm', seller: 'demo-seller-ngoc', categoryId: 'vehicles', expect: 'KHÔNG khớp vision: ở TP.HCM',
    title: 'Honda Vision 2021 trắng biển Sài Gòn', description: 'Xe nữ đi, máy êm, đã thay nhớt định kỳ.',
    price: 24000000, condition: 'USED_GOOD', ward: '26743', attributes: { vehicle_type: 'motorbike', brand: 'Honda', model: 'Vision', year: 2021, has_papers: true }, daysAgo: 0,
  },
  {
    key: 'sofa-leather', seller: 'demo-seller-huy', categoryId: 'furniture', expect: 'KHỚP sofa-swap (cho đổi)',
    title: 'Sofa da 3 chỗ màu nâu', description: 'Da công nghiệp còn đẹp, không bong tróc. Nhà chật nên muốn đổi lấy sofa nhỏ hơn.',
    price: 4500000, condition: 'USED_GOOD', ward: '20209', attributes: { home_type: 'furniture', material: 'Da', dimensions: '200 x 85 cm' }, daysAgo: 0,
    allowExchange: true, exchangeWish: 'Đổi sofa 2 chỗ',
  },
  {
    key: 'sofa-sale-only', seller: 'demo-seller-ha', categoryId: 'furniture', expect: 'KHÔNG khớp sofa-swap: chỉ bán, không đổi',
    title: 'Sofa băng nỉ xanh 1m8', description: 'Khung gỗ chắc, nệm còn êm. Chỉ bán, không đổi.',
    price: 2800000, condition: 'USED_GOOD', ward: '00004', attributes: { home_type: 'furniture', material: 'Nỉ', dimensions: '180 x 80 cm' }, daysAgo: 0,
  },
];
