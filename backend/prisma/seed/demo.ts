import type { ListingCondition } from '@prisma/client';

/*
 * Dữ liệu demo cho trang chủ, tìm kiếm, gần bạn (chạy bằng `npm run db:seed:demo`).
 * Mọi bản ghi có id / email riêng (tiền tố demo-, đuôi @demo.restore.vn) để chạy lại
 * hay xóa (`--remove`) không đụng dữ liệu thật.
 */

/** Mật khẩu chung của các tài khoản demo */
export const DEMO_PASSWORD = 'Password@123';

export type DemoSeller = { id: string; email: string; fullName: string; username: string; phone: string; ratingAverage: number; ratingCount: number };

export const DEMO_SELLERS: DemoSeller[] = [
  { id: 'demo-seller-ngoc', email: 'ngoc@demo.restore.vn', fullName: 'Trần Bảo Ngọc', username: 'baongoc', phone: '0903111222', ratingAverage: 4.8, ratingCount: 36 },
  { id: 'demo-seller-huy', email: 'huy@demo.restore.vn', fullName: 'Lê Quang Huy', username: 'quanghuy', phone: '0912333444', ratingAverage: 4.6, ratingCount: 21 },
  { id: 'demo-seller-ha', email: 'ha@demo.restore.vn', fullName: 'Phạm Thu Hà', username: 'thuha', phone: '0935555666', ratingAverage: 4.9, ratingCount: 58 },
  { id: 'demo-seller-khoa', email: 'khoa@demo.restore.vn', fullName: 'Võ Minh Khoa', username: 'minhkhoa', phone: '0987777888', ratingAverage: 4.3, ratingCount: 9 },
];

export type DemoListing = {
  /** id = `demo-listing-${key}` */
  key: string;
  seller: string;
  categoryId: string;
  title: string;
  description: string;
  price: number;
  condition: ListingCondition;
  /** provinceCode-wardCode, xem src/modules/catalog/catalog.data.ts */
  ward: string;
  attributes: Record<string, string | number | boolean>;
  /** Số ngày trước khi đăng (0 = hôm nay) */
  daysAgo: number;
  allowExchange?: boolean;
  exchangeWish?: string;
  isNegotiable?: boolean;
  /** Gắn gói Tin ưu tiên 7 ngày để hiện ở "Dành cho bạn" */
  featured?: boolean;
  imageCount?: number;
};

export const DEMO_LISTINGS: DemoListing[] = [
  // Điện thoại
  { key: 'iphone-14-pro', seller: 'demo-seller-ngoc', categoryId: 'phones', title: 'iPhone 14 Pro 256GB tím, pin 89%', description: 'Máy dùng kỹ, luôn dán cường lực và ốp. Face ID, True Tone đầy đủ. Tặng kèm sạc nhanh 20W.', price: 15900000, condition: 'USED_GOOD', ward: '79-BT', attributes: { brand: 'Apple', model: 'iPhone 14 Pro', storage: '256 GB', color: 'purple', origin: 'vn_a', battery_health: 89, warranty: 'none' }, daysAgo: 0, featured: true },
  { key: 'galaxy-s23', seller: 'demo-seller-huy', categoryId: 'phones', title: 'Samsung Galaxy S23 128GB đen như mới', description: 'Mua tháng 3, còn bảo hành hãng tới tháng 3 năm sau. Fullbox, không trầy xước.', price: 11500000, condition: 'LIKE_NEW', ward: '01-CG', attributes: { brand: 'Samsung', model: 'Galaxy S23', storage: '128 GB', color: 'black', origin: 'vn_a', warranty: 'manufacturer' }, daysAgo: 1, allowExchange: true, exchangeWish: 'Đổi iPhone 13 bù thêm' },
  { key: 'redmi-note-13', seller: 'demo-seller-khoa', categoryId: 'phones', title: 'Xiaomi Redmi Note 13 8/256 xanh', description: 'Máy zin, pin trâu, phù hợp cho học sinh sinh viên. Có hộp và cáp.', price: 3900000, condition: 'USED_GOOD', ward: '48-HC', attributes: { brand: 'Xiaomi', model: 'Redmi Note 13', storage: '256 GB', color: 'green', origin: 'international', warranty: 'store' }, daysAgo: 2 },
  { key: 'iphone-11', seller: 'demo-seller-ha', categoryId: 'phones', title: 'iPhone 11 64GB trắng, máy phụ cho ba mẹ', description: 'Pin đã thay mới 100%, màn zin. Máy chạy mượt, phù hợp nghe gọi, Zalo.', price: 4500000, condition: 'USED_FAIR', ward: '79-GV', attributes: { brand: 'Apple', model: 'iPhone 11', storage: '64 GB', color: 'white', origin: 'vn_a', battery_health: 100 }, daysAgo: 4 },

  // Đồ điện tử
  { key: 'macbook-air-m2', seller: 'demo-seller-ngoc', categoryId: 'electronics', title: 'MacBook Air M2 8/256 Midnight', description: 'Sạc 42 lần, còn AppleCare tới cuối năm. Kèm túi chống sốc và sạc zin.', price: 18500000, condition: 'LIKE_NEW', ward: '79-SG', attributes: { device_type: 'laptop', brand: 'Apple', model: 'MacBook Air M2', warranty: 'manufacturer', has_accessories: true }, daysAgo: 0, featured: true },
  { key: 'sony-a6400', seller: 'demo-seller-huy', categoryId: 'electronics', title: 'Máy ảnh Sony A6400 kèm lens kit 16-50', description: 'Shot count 8k, cảm biến sạch. Tặng thẻ 64GB, pin phụ và túi đeo.', price: 14200000, condition: 'USED_GOOD', ward: '01-HK', attributes: { device_type: 'camera', brand: 'Sony', model: 'A6400', warranty: 'none', has_accessories: true }, daysAgo: 1, featured: true },
  { key: 'airpods-pro-2', seller: 'demo-seller-khoa', categoryId: 'electronics', title: 'AirPods Pro 2 USB-C chính hãng', description: 'Nghe chống ồn tốt, pin còn khỏe. Mua ở TGDĐ, còn hóa đơn.', price: 4300000, condition: 'LIKE_NEW', ward: '48-TK', attributes: { device_type: 'audio', brand: 'Apple', model: 'AirPods Pro 2', warranty: 'store' }, daysAgo: 3 },
  { key: 'ipad-gen-9', seller: 'demo-seller-ha', categoryId: 'electronics', title: 'iPad Gen 9 64GB wifi cho bé học online', description: 'Máy đẹp 98%, đã dán màn nhám vẽ. Kèm ốp và bút cảm ứng.', price: 5200000, condition: 'USED_GOOD', ward: '79-TD', attributes: { device_type: 'tablet', brand: 'Apple', model: 'iPad Gen 9', has_accessories: true }, daysAgo: 5, allowExchange: true, exchangeWish: 'Đổi Kindle hoặc máy đọc sách' },
  { key: 'ps5-slim', seller: 'demo-seller-ngoc', categoryId: 'electronics', title: 'PS5 Slim bản đĩa + 2 tay cầm', description: 'Chơi cuối tuần nên còn rất mới. Tặng 3 đĩa game: FC 24, Spider-Man 2, It Takes Two.', price: 11000000, condition: 'LIKE_NEW', ward: '79-THD', attributes: { device_type: 'gaming', brand: 'Sony', model: 'PS5 Slim', has_accessories: true }, daysAgo: 6 },

  // Xe cộ
  { key: 'vision-2022', seller: 'demo-seller-huy', categoryId: 'vehicles', title: 'Honda Vision 2022 trắng, biển Hà Nội', description: 'Xe chính chủ, đi 12.000 km, bảo dưỡng định kỳ ở Head. Giấy tờ đầy đủ.', price: 28500000, condition: 'USED_GOOD', ward: '01-DD', attributes: { vehicle_type: 'motorbike', brand: 'Honda', model: 'Vision', year: 2022, mileage: 12000, engine_cc: 110, has_papers: true }, daysAgo: 2, featured: true },
  { key: 'giant-escape', seller: 'demo-seller-khoa', categoryId: 'vehicles', title: 'Xe đạp Giant Escape 3 size M', description: 'Đạp đi làm 1 năm, đã thay lốp mới. Phù hợp người cao 1m65 đến 1m78.', price: 5500000, condition: 'USED_GOOD', ward: '48-ST', attributes: { vehicle_type: 'bicycle', brand: 'Giant', model: 'Escape 3', year: 2023 }, daysAgo: 7, allowExchange: true, exchangeWish: 'Đổi xe đạp gấp' },
  { key: 'vinfast-evo', seller: 'demo-seller-ha', categoryId: 'vehicles', title: 'Xe máy điện VinFast Evo200 Lite', description: 'Pin LFP đi được khoảng 200 km mỗi lần sạc. Xe nữ dùng, còn rất mới.', price: 15000000, condition: 'LIKE_NEW', ward: '79-XH', attributes: { vehicle_type: 'ebike', brand: 'VinFast', model: 'Evo200 Lite', year: 2024, mileage: 3500, has_papers: true }, daysAgo: 3 },

  // Thời trang
  { key: 'nike-af1', seller: 'demo-seller-ngoc', categoryId: 'fashion', title: 'Giày Nike Air Force 1 trắng size 42', description: 'Mang 3 lần, mua nhầm size. Fullbox kèm bill.', price: 1650000, condition: 'LIKE_NEW', ward: '79-BC', attributes: { product_type: 'shoes', gender: 'unisex', size: '42', brand: 'Nike' }, daysAgo: 1 },
  { key: 'coach-bag', seller: 'demo-seller-ha', categoryId: 'fashion', title: 'Túi Coach Tabby 26 da thật màu nâu', description: 'Hàng auth mua ở Mỹ, đeo vài lần. Kèm dustbag và thẻ.', price: 6800000, condition: 'LIKE_NEW', ward: '48-HCU', attributes: { product_type: 'bags', gender: 'women', brand: 'Coach', material: 'Da bò' }, daysAgo: 4, featured: true },
  { key: 'uniqlo-jacket', seller: 'demo-seller-huy', categoryId: 'fashion', title: 'Áo khoác Uniqlo lông vũ nam size L', description: 'Mặc 1 mùa đông, giặt sạch. Rất ấm, nhẹ, gấp gọn được.', price: 650000, condition: 'USED_GOOD', ward: '01-BD', attributes: { product_type: 'clothes', gender: 'men', size: 'L', brand: 'Uniqlo', material: 'Lông vũ' }, daysAgo: 8 },
  { key: 'casio-watch', seller: 'demo-seller-khoa', categoryId: 'fashion', title: 'Đồng hồ Casio G-Shock GA-2100 đen', description: 'Bản CasiOak, máy chạy chuẩn, dây còn đẹp.', price: 1900000, condition: 'USED_GOOD', ward: '79-AK', attributes: { product_type: 'watch', gender: 'men', brand: 'Casio' }, daysAgo: 9, allowExchange: true, exchangeWish: 'Đổi Seiko 5' },

  // Đồ gia dụng
  { key: 'panasonic-fridge', seller: 'demo-seller-ha', categoryId: 'appliances', title: 'Tủ lạnh Panasonic Inverter 322L', description: 'Chuyển nhà nên bán. Làm lạnh tốt, tiết kiệm điện. Hỗ trợ chở trong nội thành.', price: 7200000, condition: 'USED_GOOD', ward: '48-HC', attributes: { appliance_type: 'fridge', brand: 'Panasonic', capacity: '322L', power: 120, warranty: 'none' }, daysAgo: 2 },
  { key: 'daikin-ac', seller: 'demo-seller-ngoc', categoryId: 'appliances', title: 'Máy lạnh Daikin 1HP Inverter', description: 'Lắp được 2 năm, vệ sinh định kỳ. Bán kèm ống đồng 3m.', price: 5500000, condition: 'USED_GOOD', ward: '79-GV', attributes: { appliance_type: 'air_conditioner', brand: 'Daikin', capacity: '1HP', power: 900 }, daysAgo: 5 },
  { key: 'philips-airfryer', seller: 'demo-seller-huy', categoryId: 'appliances', title: 'Nồi chiên không dầu Philips 6.2L', description: 'Dùng ít, lòng nồi chống dính còn tốt. Có sách hướng dẫn công thức.', price: 1400000, condition: 'LIKE_NEW', ward: '01-HBT', attributes: { appliance_type: 'kitchen', brand: 'Philips', capacity: '6.2L', power: 2000, warranty: 'store' }, daysAgo: 0 },

  // Thú cưng
  { key: 'corgi-puppy', seller: 'demo-seller-khoa', categoryId: 'pets', title: 'Bé Corgi đực 3 tháng tuổi', description: 'Đã tiêm 2 mũi, tẩy giun đầy đủ. Bé hiếu động, ăn tốt.', price: 9000000, condition: 'NEW', ward: '79-THD', attributes: { pet_type: 'dog', breed: 'Corgi', age_months: 3, pet_gender: 'male', vaccinated: true }, daysAgo: 1, featured: true },
  { key: 'cat-tree', seller: 'demo-seller-ha', categoryId: 'pets', title: 'Cây cào móng cho mèo cao 1m2', description: 'Mèo nhà không chịu chơi nên pass lại. Có nhà ngủ và võng.', price: 450000, condition: 'LIKE_NEW', ward: '48-NHS', attributes: { pet_type: 'accessories' }, daysAgo: 6, isNegotiable: false },

  // Nội thất
  { key: 'ikea-desk', seller: 'demo-seller-ngoc', categoryId: 'furniture', title: 'Bàn làm việc IKEA gỗ sồi 120x60', description: 'Mặt bàn chắc chắn, không cong vênh. Tháo lắp dễ dàng.', price: 1800000, condition: 'USED_GOOD', ward: '79-TD', attributes: { home_type: 'furniture', material: 'Gỗ sồi', dimensions: '120 x 60 x 75 cm' }, daysAgo: 3 },
  { key: 'floor-lamp', seller: 'demo-seller-huy', categoryId: 'furniture', title: 'Đèn cây đứng phong cách Bắc Âu', description: 'Ánh sáng vàng ấm, chân gỗ, chao vải. Kèm bóng LED.', price: 750000, condition: 'LIKE_NEW', ward: '01-NH', attributes: { home_type: 'lighting', material: 'Gỗ, vải', dimensions: 'Cao 160 cm' }, daysAgo: 10 },
  { key: 'sofa-2-seat', seller: 'demo-seller-ha', categoryId: 'furniture', title: 'Sofa nỉ 2 chỗ màu xám', description: 'Nệm êm, khung gỗ tự nhiên. Đã giặt bọc ghế sạch sẽ.', price: 3200000, condition: 'USED_GOOD', ward: '48-TK', attributes: { home_type: 'furniture', material: 'Nỉ, gỗ', dimensions: '160 x 80 cm' }, daysAgo: 8, allowExchange: true, exchangeWish: 'Đổi bàn ăn 4 ghế' },

  // Sách, văn phòng phẩm
  { key: 'harry-potter-set', seller: 'demo-seller-khoa', categoryId: 'books', title: 'Bộ Harry Potter 7 tập bản tiếng Việt', description: 'Sách NXB Trẻ, giấy còn trắng, không ghi chú.', price: 850000, condition: 'USED_GOOD', ward: '79-BT', attributes: { genre: 'novel', author: 'J.K. Rowling', quantity: 7 }, daysAgo: 2 },
  { key: 'ielts-books', seller: 'demo-seller-ngoc', categoryId: 'books', title: 'Combo sách luyện IELTS Cambridge 15-18', description: 'Có ghi chú bút chì nhẹ, kèm file nghe.', price: 300000, condition: 'USED_FAIR', ward: '79-SG', attributes: { genre: 'textbook', author: 'Cambridge', quantity: 4 }, daysAgo: 11, isNegotiable: false },

  // Thể thao
  { key: 'yonex-racket', seller: 'demo-seller-huy', categoryId: 'sports', title: 'Vợt cầu lông Yonex Astrox 88D', description: 'Vợt đánh công, đã căng dây 10kg. Kèm bao vợt.', price: 2400000, condition: 'USED_GOOD', ward: '01-CN', attributes: { sport_type: 'Cầu lông', brand: 'Yonex' }, daysAgo: 4 },
  { key: 'camping-tent', seller: 'demo-seller-ha', categoryId: 'sports', title: 'Lều cắm trại Naturehike 2 người', description: 'Đi 2 chuyến, chống nước tốt, nhẹ 1.8kg.', price: 1300000, condition: 'LIKE_NEW', ward: '48-ST', attributes: { sport_type: 'Dã ngoại', brand: 'Naturehike', size: '2 người' }, daysAgo: 5, allowExchange: true, exchangeWish: 'Đổi túi ngủ' },

  // Khác
  { key: 'film-camera', seller: 'demo-seller-khoa', categoryId: 'other', title: 'Máy film Canon AE-1 kèm lens 50mm f1.8', description: 'Máy chạy tốt, đo sáng chuẩn. Phù hợp người mới chơi film.', price: 3500000, condition: 'USED_GOOD', ward: '79-BC', attributes: { brand: 'Canon' }, daysAgo: 12 },
  { key: 'mechanical-keyboard', seller: 'demo-seller-ngoc', categoryId: 'electronics', title: 'Bàn phím cơ Keychron K8 Pro hot-swap', description: 'Switch Gateron Brown, kết nối bluetooth và dây. Kèm keycap PBT.', price: 1900000, condition: 'LIKE_NEW', ward: '79-XH', attributes: { device_type: 'other', brand: 'Keychron', model: 'K8 Pro', has_accessories: true }, daysAgo: 1 },
];

/** Banner trang chủ (ảnh trong assets của app) */
export const DEMO_BANNERS = [
  { id: 'demo-banner-1', title: 'Tuần lễ đồ cũ', imageUrl: 'assets/images/banners/banner-kodo-week.jpg', route: '/nearby', sortOrder: 0 },
  { id: 'demo-banner-2', title: 'Siêu sale', imageUrl: 'assets/images/banners/banner-super-sale.jpg', route: '/search', sortOrder: 1 },
  { id: 'demo-banner-3', title: 'Black Friday', imageUrl: 'assets/images/banners/banner-black-friday.jpg', route: '/create-listing/category', sortOrder: 2 },
];

/** Ảnh minh họa (picsum.photos, cố định theo seed nên lần nào cũng ra cùng ảnh) */
export const demoImages = (key: string, count = 3) =>
  Array.from({ length: count }, (_, index) => `https://picsum.photos/seed/restore-${key}-${index + 1}/800/800`);
