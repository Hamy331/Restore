import type { ListingCondition, ShopVerificationType } from '@prisma/client';

/*
 * Shop uy tín (gói Cửa hàng, đã xác minh) và tài khoản Bán chuyên để test, chạy bằng `npm run db:seed:shops`.
 * Mỗi danh mục có 1-2 shop. Logo và banner là ảnh trong assets của app (assets/images/shops, assets/images/banners).
 * Mọi bản ghi có id riêng (tiền tố shop- / pro-seller-) và email đuôi @shop.restore.vn / @pro.restore.vn
 * để chạy lại hay xóa (`--remove`) không đụng dữ liệu thật. Mật khẩu chung: DEMO_PASSWORD (seed/demo.ts).
 */

export type SeedListing = {
  title: string;
  description: string;
  price: number;
  /** Giá trước giảm: có thì tin hiện ở "Trải nghiệm hàng hiệu" */
  originalPrice?: number;
  condition: ListingCondition | null;
  categoryId: string;
  attributes: Record<string, string | number | boolean>;
  /** Số ngày trước khi đăng (0 = hôm nay) */
  daysAgo: number;
  allowExchange?: boolean;
  exchangeWish?: string;
};

export type SeedShop = {
  /** id user và shop = `shop-${key}`, email `${key}@shop.restore.vn` */
  key: string;
  name: string;
  /** Tên tài khoản (username), không dấu */
  username: string;
  tagline: string;
  description: string;
  accentColor: string;
  verificationType: ShopVerificationType;
  /** Số ngày trước khi được xác minh (≤ 180 thì hiện ở "Cửa hàng mới") */
  verifiedDaysAgo: number;
  categoryIds: string[];
  /** Mã phường, xem src/modules/catalog/location.units.ts */
  ward: string;
  phone: string;
  ratingAverage: number;
  ratingCount: number;
  /** Số người theo dõi giả lập (tạo bằng các tài khoản demo / pro) */
  followers: number;
  /** Ảnh banner 1200 x 600 trong assets/images/banners của app */
  banner?: { title: string; image: string };
  listings: SeedListing[];
};

export type SeedProSeller = {
  /** id = `pro-seller-${key}`, email `${key}@pro.restore.vn` */
  key: string;
  fullName: string;
  username: string;
  phone: string;
  categoryId: string;
  ward: string;
  ratingAverage: number;
  ratingCount: number;
  listings: SeedListing[];
};

export const SHOPS: SeedShop[] = [
  // Điện thoại, đồ điện tử
  {
    key: 'samsung', name: 'Samsung Official Store', username: 'samsungstore', accentColor: '#1428A0',
    tagline: 'Galaxy chính hãng, bảo hành toàn quốc', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 320,
    description: 'Gian hàng chính hãng Samsung trên ReStore: máy trưng bày, máy đổi trả 30 ngày đã kiểm định, còn bảo hành hãng.',
    categoryIds: ['phones', 'electronics'], ward: '26743', phone: '0281000001', ratingAverage: 4.9, ratingCount: 412, followers: 9,
    banner: { title: 'Galaxy Week giảm tới 20%', image: 'assets/images/banners/shop-samsung.jpg' },
    listings: [
      { title: 'Samsung Galaxy S24 Ultra 256GB xám titan', description: 'Máy trưng bày, đã kiểm định 30 điểm, bảo hành hãng 12 tháng. Fullbox kèm bút S Pen.', price: 23990000, originalPrice: 28990000, condition: 'LIKE_NEW', categoryId: 'phones', attributes: { brand: 'Samsung', model: 'Galaxy S24 Ultra', storage: '256 GB', color: 'gray', origin: 'vn_a', warranty: 'manufacturer' }, daysAgo: 0 },
      { title: 'Galaxy Z Flip5 256GB tím, đổi trả 30 ngày', description: 'Máy khách đổi trả trong 30 ngày, nếp gấp đẹp, pin 100%. Bảo hành hãng còn 11 tháng.', price: 14490000, originalPrice: 19990000, condition: 'LIKE_NEW', categoryId: 'phones', attributes: { brand: 'Samsung', model: 'Galaxy Z Flip5', storage: '256 GB', color: 'purple', origin: 'vn_a', warranty: 'manufacturer' }, daysAgo: 1 },
      { title: 'Galaxy Tab S9 FE wifi 128GB kèm bút', description: 'Máy trưng bày tại cửa hàng, màn đẹp không trầy. Kèm bút S Pen và sạc.', price: 7990000, condition: 'LIKE_NEW', categoryId: 'electronics', attributes: { device_type: 'tablet', brand: 'Samsung', model: 'Galaxy Tab S9 FE', warranty: 'manufacturer', has_accessories: true }, daysAgo: 2 },
      { title: 'Galaxy Watch6 Classic 47mm', description: 'Đồng hồ mới 100% nguyên seal, bảo hành 12 tháng toàn quốc.', price: 6490000, originalPrice: 8990000, condition: 'NEW', categoryId: 'electronics', attributes: { device_type: 'smartwatch', brand: 'Samsung', model: 'Galaxy Watch6 Classic', warranty: 'manufacturer' }, daysAgo: 3 },
    ],
  },
  {
    key: 'apple', name: 'Apple Authorized Reseller', username: 'applereseller', accentColor: '#1D1D1F',
    tagline: 'iPhone, MacBook chính hãng VN/A', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 290,
    description: 'Đại lý uỷ quyền: iPhone, iPad, MacBook chính hãng VN/A, máy cũ được kiểm tra và thay pin chính hãng trước khi bán.',
    categoryIds: ['phones', 'electronics'], ward: '26740', phone: '0281000002', ratingAverage: 4.9, ratingCount: 538, followers: 11,
    banner: { title: 'iPhone đã kiểm định, bảo hành 12 tháng', image: 'assets/images/banners/shop-apple.jpg' },
    listings: [
      { title: 'iPhone 15 Pro 128GB titan tự nhiên', description: 'Máy đã kiểm định, pin 98%, bảo hành 12 tháng tại cửa hàng. Kèm cáp USB-C zin.', price: 21490000, originalPrice: 24990000, condition: 'LIKE_NEW', categoryId: 'phones', attributes: { brand: 'Apple', model: 'iPhone 15 Pro', storage: '128 GB', color: 'silver', origin: 'vn_a', battery_health: 98, warranty: 'store' }, daysAgo: 0 },
      { title: 'iPhone 13 128GB xanh, pin thay chính hãng', description: 'Máy đẹp 99%, pin mới thay tại Apple. Phù hợp làm máy chính hoặc tặng người thân.', price: 10490000, condition: 'USED_GOOD', categoryId: 'phones', attributes: { brand: 'Apple', model: 'iPhone 13', storage: '128 GB', color: 'blue', origin: 'vn_a', battery_health: 100, warranty: 'store' }, daysAgo: 2 },
      { title: 'MacBook Air M3 13 inch 16/512 Midnight', description: 'Máy mới 100% nguyên seal, bảo hành Apple 12 tháng toàn cầu.', price: 32990000, originalPrice: 35990000, condition: 'NEW', categoryId: 'electronics', attributes: { device_type: 'laptop', brand: 'Apple', model: 'MacBook Air M3', warranty: 'manufacturer', has_accessories: true }, daysAgo: 1 },
      { title: 'iPad Air M2 11 inch wifi 128GB', description: 'Máy trưng bày, còn bảo hành hãng 10 tháng. Kèm hộp và cáp.', price: 14290000, condition: 'LIKE_NEW', categoryId: 'electronics', attributes: { device_type: 'tablet', brand: 'Apple', model: 'iPad Air M2', warranty: 'manufacturer', has_accessories: true }, daysAgo: 4 },
    ],
  },
  {
    key: 'xiaomi', name: 'Xiaomi Store Việt Nam', username: 'xiaomistore', accentColor: '#FF6900',
    tagline: 'Điện thoại và thiết bị thông minh giá tốt', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 75,
    description: 'Cửa hàng chính hãng Xiaomi: điện thoại, máy lọc không khí, robot hút bụi. Máy demo được bán lại với giá tốt.',
    categoryIds: ['phones', 'appliances'], ward: '00166', phone: '0241000003', ratingAverage: 4.7, ratingCount: 205, followers: 6,
    listings: [
      { title: 'Xiaomi 14 12/256GB đen, máy demo', description: 'Máy trưng bày 2 tuần, ngoại hình như mới. Bảo hành hãng 18 tháng.', price: 14990000, originalPrice: 18990000, condition: 'LIKE_NEW', categoryId: 'phones', attributes: { brand: 'Xiaomi', model: 'Xiaomi 14', storage: '256 GB', color: 'black', origin: 'vn_a', warranty: 'manufacturer' }, daysAgo: 1 },
      { title: 'Redmi Note 13 Pro 8/256GB tím', description: 'Mới 100% nguyên seal, tặng ốp lưng chính hãng.', price: 6990000, condition: 'NEW', categoryId: 'phones', attributes: { brand: 'Xiaomi', model: 'Redmi Note 13 Pro', storage: '256 GB', color: 'purple', origin: 'vn_a', warranty: 'manufacturer' }, daysAgo: 3 },
      { title: 'Robot hút bụi lau nhà Xiaomi X10', description: 'Máy trưng bày, tự đổ rác, lau rung. Đủ phụ kiện, bảo hành 12 tháng.', price: 8490000, originalPrice: 11990000, condition: 'LIKE_NEW', categoryId: 'appliances', attributes: { appliance_type: 'other', brand: 'Xiaomi', capacity: '4L', power: 45, warranty: 'manufacturer' }, daysAgo: 5 },
    ],
  },
  {
    key: 'sony', name: 'Sony Center', username: 'sonycenter', accentColor: '#111111',
    tagline: 'Máy ảnh, tai nghe, PlayStation chính hãng', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 210,
    description: 'Sony Center bán lại máy ảnh, tai nghe, máy chơi game đã qua kiểm tra kỹ thuật, có phiếu bảo hành.',
    categoryIds: ['electronics'], ward: '00070', phone: '0241000004', ratingAverage: 4.8, ratingCount: 260, followers: 7,
    listings: [
      { title: 'Máy ảnh Sony A7 IV body, shot 3.000', description: 'Máy trưng bày, cảm biến sạch, bảo hành hãng 12 tháng.', price: 46990000, originalPrice: 52990000, condition: 'LIKE_NEW', categoryId: 'electronics', attributes: { device_type: 'camera', brand: 'Sony', model: 'A7 IV', warranty: 'manufacturer', has_accessories: true }, daysAgo: 0 },
      { title: 'Tai nghe Sony WH-1000XM5 bạc', description: 'Hàng mới 100% nguyên hộp, chống ồn hàng đầu.', price: 6990000, condition: 'NEW', categoryId: 'electronics', attributes: { device_type: 'audio', brand: 'Sony', model: 'WH-1000XM5', warranty: 'manufacturer' }, daysAgo: 2 },
      { title: 'PlayStation 5 Slim Digital kèm 2 tay cầm', description: 'Máy đổi trả, đã kiểm tra quạt và ổ cứng. Bảo hành 6 tháng.', price: 10490000, originalPrice: 12490000, condition: 'LIKE_NEW', categoryId: 'electronics', attributes: { device_type: 'gaming', brand: 'Sony', model: 'PS5 Slim Digital', warranty: 'store', has_accessories: true }, daysAgo: 4 },
    ],
  },

  // Xe cộ
  {
    key: 'honda', name: 'Honda Head Phát Tiến', username: 'hondaphattien', accentColor: '#CC0000',
    tagline: 'Đại lý uỷ nhiệm Honda, xe lướt có giấy tờ', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 400,
    description: 'Head Honda bán xe lướt thu lại từ khách, bảo dưỡng tại xưởng và sang tên trọn gói.',
    categoryIds: ['vehicles'], ward: '26884', phone: '0281000005', ratingAverage: 4.7, ratingCount: 188, followers: 5,
    listings: [
      { title: 'Honda SH 160i 2023 ABS đen nhám', description: 'Xe lướt 4.000 km, bảo dưỡng định kỳ tại Head, hỗ trợ sang tên.', price: 96000000, originalPrice: 104000000, condition: 'LIKE_NEW', categoryId: 'vehicles', attributes: { vehicle_type: 'motorbike', brand: 'Honda', model: 'SH 160i', year: 2023, mileage: 4000, engine_cc: 160, has_papers: true }, daysAgo: 1 },
      { title: 'Honda Air Blade 125 2022 xanh', description: 'Xe một chủ, máy êm, giấy tờ đầy đủ.', price: 38500000, condition: 'USED_GOOD', categoryId: 'vehicles', attributes: { vehicle_type: 'motorbike', brand: 'Honda', model: 'Air Blade 125', year: 2022, mileage: 15000, engine_cc: 125, has_papers: true }, daysAgo: 3 },
      { title: 'Honda Wave Alpha 2024 trắng', description: 'Xe mới đi 800 km, còn bảo hành hãng 2 năm.', price: 17900000, condition: 'LIKE_NEW', categoryId: 'vehicles', attributes: { vehicle_type: 'motorbike', brand: 'Honda', model: 'Wave Alpha', year: 2024, mileage: 800, engine_cc: 110, has_papers: true }, daysAgo: 6 },
    ],
  },
  {
    key: 'vinfast', name: 'VinFast Showroom Đà Nẵng', username: 'vinfastdanang', accentColor: '#1464F4',
    tagline: 'Xe máy điện, ô tô điện đã qua sử dụng', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 40,
    description: 'Showroom VinFast thu cũ đổi mới: xe đã kiểm tra pin và động cơ, có hợp đồng thuê pin hoặc pin mua kèm.',
    categoryIds: ['vehicles'], ward: '20242', phone: '0236100006', ratingAverage: 4.6, ratingCount: 97, followers: 4,
    banner: { title: 'Thu cũ đổi mới xe điện', image: 'assets/images/banners/shop-vinfast.jpg' },
    listings: [
      { title: 'VinFast Feliz S 2023 pin LFP', description: 'Xe đi 6.000 km, pin còn 95%, tặng mũ bảo hiểm.', price: 23500000, originalPrice: 29900000, condition: 'USED_GOOD', categoryId: 'vehicles', attributes: { vehicle_type: 'ebike', brand: 'VinFast', model: 'Feliz S', year: 2023, mileage: 6000, has_papers: true }, daysAgo: 0 },
      { title: 'VinFast VF 5 Plus 2024 xanh', description: 'Ô tô điện lướt 9.000 km, bảo hành hãng 7 năm, không kèm pin.', price: 418000000, condition: 'LIKE_NEW', categoryId: 'vehicles', attributes: { vehicle_type: 'car', brand: 'VinFast', model: 'VF 5 Plus', year: 2024, mileage: 9000, has_papers: true }, daysAgo: 2 },
      { title: 'VinFast Evo200 2024 đỏ', description: 'Xe trưng bày, đi được 200 km mỗi lần sạc.', price: 19900000, condition: 'LIKE_NEW', categoryId: 'vehicles', attributes: { vehicle_type: 'ebike', brand: 'VinFast', model: 'Evo200', year: 2024, mileage: 300, has_papers: true }, daysAgo: 4 },
    ],
  },

  // Đồ gia dụng
  {
    key: 'panasonic', name: 'Panasonic Official', username: 'panasonicvn', accentColor: '#0041C0',
    tagline: 'Gia dụng Nhật Bản, máy trưng bày giá tốt', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 260,
    description: 'Gian hàng Panasonic bán máy trưng bày, máy hộp móp: tủ lạnh, máy giặt, máy lạnh, bảo hành chính hãng.',
    categoryIds: ['appliances'], ward: '26737', phone: '0281000007', ratingAverage: 4.8, ratingCount: 174, followers: 6,
    listings: [
      { title: 'Tủ lạnh Panasonic Inverter 366L ngăn đá dưới', description: 'Máy trưng bày, hộp móp, bảo hành 2 năm tại nhà.', price: 11490000, originalPrice: 14990000, condition: 'LIKE_NEW', categoryId: 'appliances', attributes: { appliance_type: 'fridge', brand: 'Panasonic', capacity: '366L', power: 130, warranty: 'manufacturer' }, daysAgo: 1 },
      { title: 'Máy giặt Panasonic 10kg cửa trước', description: 'Mới 100%, giặt hơi nước diệt khuẩn.', price: 9990000, condition: 'NEW', categoryId: 'appliances', attributes: { appliance_type: 'washer', brand: 'Panasonic', capacity: '10kg', power: 1900, warranty: 'manufacturer' }, daysAgo: 3 },
      { title: 'Máy lạnh Panasonic 1.5HP Inverter', description: 'Máy trưng bày, miễn phí lắp đặt nội thành.', price: 10290000, originalPrice: 12490000, condition: 'LIKE_NEW', categoryId: 'appliances', attributes: { appliance_type: 'air_conditioner', brand: 'Panasonic', capacity: '1.5HP', power: 1200, warranty: 'manufacturer' }, daysAgo: 5 },
    ],
  },
  {
    key: 'philips', name: 'Philips Home Store', username: 'philipshome', accentColor: '#0B5ED7',
    tagline: 'Đồ bếp và chăm sóc nhà cửa', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 120,
    description: 'Nồi chiên, máy xay, bàn ủi hơi nước chính hãng Philips. Hàng đổi trả được kiểm tra kỹ trước khi bán.',
    categoryIds: ['appliances'], ward: '00256', phone: '0241000008', ratingAverage: 4.7, ratingCount: 133, followers: 3,
    listings: [
      { title: 'Nồi chiên không dầu Philips XXL 7.3L', description: 'Hàng đổi trả, lòng nồi mới, bảo hành 24 tháng.', price: 3490000, originalPrice: 4990000, condition: 'LIKE_NEW', categoryId: 'appliances', attributes: { appliance_type: 'kitchen', brand: 'Philips', capacity: '7.3L', power: 2000, warranty: 'manufacturer' }, daysAgo: 0 },
      { title: 'Máy xay sinh tố Philips 5000 series', description: 'Mới nguyên hộp, cối thuỷ tinh 2L.', price: 1290000, condition: 'NEW', categoryId: 'appliances', attributes: { appliance_type: 'kitchen', brand: 'Philips', capacity: '2L', power: 800, warranty: 'manufacturer' }, daysAgo: 2 },
      { title: 'Bàn ủi hơi nước đứng Philips', description: 'Máy trưng bày, dùng tốt cho vest và rèm.', price: 2190000, condition: 'LIKE_NEW', categoryId: 'appliances', attributes: { appliance_type: 'other', brand: 'Philips', power: 1800, warranty: 'manufacturer' }, daysAgo: 7 },
    ],
  },

  // Thú cưng
  {
    key: 'pawhouse', name: 'Paw House Pet Shop', username: 'pawhouse', accentColor: '#F28C28',
    tagline: 'Chó mèo khoẻ mạnh, tiêm phòng đầy đủ', verificationType: 'CERTIFIED', verifiedDaysAgo: 30,
    description: 'Pet shop được ReStore kiểm tra giấy phép kinh doanh và sổ tiêm. Bé nào cũng có giấy khám sức khoẻ.',
    categoryIds: ['pets'], ward: '26824', phone: '0281000009', ratingAverage: 4.9, ratingCount: 156, followers: 8,
    banner: { title: 'Tháng nhận nuôi: tặng sổ tiêm và balo', image: 'assets/images/banners/shop-pawhouse.jpg' },
    listings: [
      { title: 'Mèo Anh lông ngắn xám 3 tháng', description: 'Bé cái, đã tiêm 2 mũi, tẩy giun. Tặng cát và hạt ăn 1 tuần.', price: 6500000, condition: null, categoryId: 'pets', attributes: { pet_type: 'cat', breed: 'Anh lông ngắn', age_months: 3, pet_gender: 'female', vaccinated: true }, daysAgo: 0 },
      { title: 'Chó Poodle tiny nâu đỏ 2 tháng', description: 'Bé đực, đã tiêm mũi 1, có giấy khám sức khoẻ.', price: 8500000, condition: null, categoryId: 'pets', attributes: { pet_type: 'dog', breed: 'Poodle', age_months: 2, pet_gender: 'male', vaccinated: true }, daysAgo: 1 },
      { title: 'Chuồng mèo 3 tầng có bánh xe', description: 'Hàng mới, khung sơn tĩnh điện, kèm khay vệ sinh.', price: 990000, originalPrice: 1390000, condition: null, categoryId: 'pets', attributes: { pet_type: 'accessories' }, daysAgo: 3 },
    ],
  },
  {
    key: 'royalcanin', name: 'Royal Canin Official', username: 'royalcaninvn', accentColor: '#E2001A',
    tagline: 'Thức ăn dinh dưỡng cho chó mèo', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 150,
    description: 'Nhà phân phối chính thức thức ăn Royal Canin. Hàng còn hạn dài, giao nhanh nội thành.',
    categoryIds: ['pets'], ward: '00004', phone: '0241000010', ratingAverage: 4.8, ratingCount: 302, followers: 5,
    listings: [
      { title: 'Hạt Royal Canin Kitten 2kg', description: 'Hạn sử dụng 2027, nguyên bao chưa mở.', price: 520000, originalPrice: 650000, condition: null, categoryId: 'pets', attributes: { pet_type: 'accessories' }, daysAgo: 1 },
      { title: 'Hạt Royal Canin Mini Adult 4kg cho chó nhỏ', description: 'Hàng chính hãng, có tem nhà phân phối.', price: 890000, condition: null, categoryId: 'pets', attributes: { pet_type: 'accessories' }, daysAgo: 4 },
      { title: 'Pate Royal Canin Instinctive thùng 12 gói', description: 'Cho mèo trưởng thành, hạn dài.', price: 330000, condition: null, categoryId: 'pets', attributes: { pet_type: 'accessories' }, daysAgo: 6 },
    ],
  },

  // Nội thất
  {
    key: 'ikea', name: 'IKEA Second Life', username: 'ikeasecondlife', accentColor: '#0058A3',
    tagline: 'Nội thất trưng bày, giá mềm hơn tới 40%', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 100,
    description: 'Góc Second Life bán lại đồ trưng bày và hàng đổi trả còn tốt, đã lắp thử và kiểm tra từng món.',
    categoryIds: ['furniture'], ward: '27139', phone: '0281000011', ratingAverage: 4.7, ratingCount: 221, followers: 7,
    banner: { title: 'Second Life: đồ trưng bày giảm tới 40%', image: 'assets/images/banners/shop-ikea.jpg' },
    listings: [
      { title: 'Sofa 3 chỗ vải xám, đồ trưng bày', description: 'Đặt ở showroom 3 tháng, bọc tháo giặt được.', price: 7490000, originalPrice: 11990000, condition: 'LIKE_NEW', categoryId: 'furniture', attributes: { home_type: 'furniture', material: 'Vải, gỗ', dimensions: '228 x 89 x 83 cm' }, daysAgo: 0 },
      { title: 'Bàn làm việc nâng hạ điện 140x70', description: 'Hàng đổi trả, động cơ êm, mặt bàn trắng.', price: 6990000, originalPrice: 8990000, condition: 'LIKE_NEW', categoryId: 'furniture', attributes: { home_type: 'furniture', material: 'Gỗ ép, thép', dimensions: '140 x 70 cm' }, daysAgo: 2 },
      { title: 'Đèn bàn LED điều chỉnh độ sáng', description: 'Mới 100%, ánh sáng ấm, đế chắc.', price: 590000, condition: 'NEW', categoryId: 'furniture', attributes: { home_type: 'lighting', material: 'Nhôm', dimensions: 'Cao 45 cm' }, daysAgo: 5 },
      { title: 'Bộ chăn ga cotton 1m6 xanh nhạt', description: 'Hàng trưng bày, đã giặt sạch.', price: 690000, condition: 'LIKE_NEW', categoryId: 'furniture', attributes: { home_type: 'bedding', material: 'Cotton', dimensions: '160 x 200 cm' }, daysAgo: 8 },
    ],
  },
  {
    key: 'gomoc', name: 'Gỗ Mộc Decor', username: 'gomocdecor', accentColor: '#8B5E3C',
    tagline: 'Nội thất gỗ tự nhiên làm thủ công', verificationType: 'CERTIFIED', verifiedDaysAgo: 20,
    description: 'Xưởng mộc nhỏ ở Đà Nẵng, nhận làm theo yêu cầu. Đồ thanh lý từ các công trình mẫu.',
    categoryIds: ['furniture'], ward: '20209', phone: '0236100012', ratingAverage: 4.8, ratingCount: 64, followers: 2,
    listings: [
      { title: 'Bàn ăn gỗ sồi 6 ghế', description: 'Mẫu trưng bày, gỗ sồi Mỹ, sơn PU mờ.', price: 12500000, originalPrice: 15900000, condition: 'LIKE_NEW', categoryId: 'furniture', attributes: { home_type: 'furniture', material: 'Gỗ sồi', dimensions: '160 x 90 cm' }, daysAgo: 1 },
      { title: 'Kệ tivi gỗ óc chó 1m8', description: 'Hàng mới làm, có ngăn kéo giảm chấn.', price: 8900000, condition: 'NEW', categoryId: 'furniture', attributes: { home_type: 'furniture', material: 'Gỗ óc chó', dimensions: '180 x 40 x 50 cm' }, daysAgo: 4 },
      { title: 'Khay gỗ trang trí bộ 3 chiếc', description: 'Gỗ xoài, phù hợp làm quà tân gia.', price: 350000, condition: 'NEW', categoryId: 'furniture', attributes: { home_type: 'decor', material: 'Gỗ xoài' }, daysAgo: 9 },
    ],
  },

  // Thời trang
  {
    key: 'nike', name: 'Nike Factory Store', username: 'nikefactory', accentColor: '#111111',
    tagline: 'Giày và đồ thể thao chính hãng giá outlet', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 230,
    description: 'Outlet Nike: hàng chính hãng mùa trước, đủ size, đổi size trong 7 ngày.',
    categoryIds: ['fashion', 'sports'], ward: '27154', phone: '0281000013', ratingAverage: 4.8, ratingCount: 345, followers: 8,
    listings: [
      { title: 'Giày Nike Air Max 90 trắng size 42', description: 'Mới 100% fullbox, hàng outlet chính hãng.', price: 2490000, originalPrice: 3829000, condition: 'NEW', categoryId: 'fashion', attributes: { product_type: 'shoes', gender: 'unisex', size: '42', brand: 'Nike', material: 'Da, lưới' }, daysAgo: 0 },
      { title: 'Áo khoác Nike Windrunner nam size L', description: 'Hàng mới có tag, chống gió, chống nước nhẹ.', price: 1290000, originalPrice: 2069000, condition: 'NEW', categoryId: 'fashion', attributes: { product_type: 'clothes', gender: 'men', size: 'L', brand: 'Nike', material: 'Polyester' }, daysAgo: 2 },
      { title: 'Giày chạy Nike Pegasus 40 nữ size 38', description: 'Mới 100%, đế React êm.', price: 2190000, condition: 'NEW', categoryId: 'sports', attributes: { sport_type: 'Chạy bộ', brand: 'Nike', size: '38' }, daysAgo: 3 },
    ],
  },
  {
    key: 'uniqlo', name: 'Uniqlo Reuse Corner', username: 'uniqloreuse', accentColor: '#E60012',
    tagline: 'Quần áo cơ bản, chất lượng Nhật', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 60,
    description: 'Góc hàng đổi trả và mẫu trưng bày của Uniqlo, giặt hấp sạch sẽ trước khi bán.',
    categoryIds: ['fashion'], ward: '00008', phone: '0241000014', ratingAverage: 4.6, ratingCount: 118, followers: 4,
    listings: [
      { title: 'Áo lông vũ siêu nhẹ nữ size M be', description: 'Hàng trưng bày, kèm túi gấp gọn.', price: 690000, originalPrice: 1471000, condition: 'LIKE_NEW', categoryId: 'fashion', attributes: { product_type: 'clothes', gender: 'women', size: 'M', brand: 'Uniqlo', material: 'Lông vũ' }, daysAgo: 1 },
      { title: 'Áo sơ mi Oxford nam size L trắng', description: 'Mới có tag, form regular.', price: 390000, condition: 'NEW', categoryId: 'fashion', attributes: { product_type: 'clothes', gender: 'men', size: 'L', brand: 'Uniqlo', material: 'Cotton' }, daysAgo: 3 },
      { title: 'Túi đeo chéo Uniqlo mini đen', description: 'Hàng mới, chống nước nhẹ, nhiều ngăn.', price: 249000, condition: 'NEW', categoryId: 'fashion', attributes: { product_type: 'bags', gender: 'unisex', brand: 'Uniqlo', material: 'Nylon' }, daysAgo: 6 },
    ],
  },

  // Thể thao
  {
    key: 'yonex', name: 'Yonex Pro Shop', username: 'yonexproshop', accentColor: '#00843D',
    tagline: 'Cầu lông, tennis chính hãng', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 180,
    description: 'Đại lý Yonex: vợt, giày, quả cầu chính hãng có tem chống giả. Căng dây miễn phí.',
    categoryIds: ['sports'], ward: '00082', phone: '0241000015', ratingAverage: 4.9, ratingCount: 240, followers: 5,
    listings: [
      { title: 'Vợt cầu lông Yonex Astrox 99 Pro', description: 'Mới 100% có tem, căng dây miễn phí 11kg.', price: 3890000, originalPrice: 4590000, condition: 'NEW', categoryId: 'sports', attributes: { sport_type: 'Cầu lông', brand: 'Yonex', size: '4U' }, daysAgo: 0 },
      { title: 'Giày cầu lông Yonex Power Cushion 65Z3 size 41', description: 'Hàng mới fullbox.', price: 2690000, condition: 'NEW', categoryId: 'sports', attributes: { sport_type: 'Cầu lông', brand: 'Yonex', size: '41' }, daysAgo: 2 },
      { title: 'Vợt tennis Yonex EZONE 100 đã qua sử dụng', description: 'Đánh 2 tháng, khung không nứt, kèm bao.', price: 2900000, condition: 'USED_GOOD', categoryId: 'sports', attributes: { sport_type: 'Tennis', brand: 'Yonex', size: 'G2' }, daysAgo: 5 },
    ],
  },
  {
    key: 'decathlon', name: 'Decathlon Second Use', username: 'decathlon2nd', accentColor: '#0082C3',
    tagline: 'Đồ thể thao cũ đã kiểm tra, giá sinh viên', verificationType: 'CERTIFIED', verifiedDaysAgo: 15,
    description: 'Đồ thể thao thu lại từ khách được kiểm tra và phân loại tình trạng rõ ràng.',
    categoryIds: ['sports'], ward: '20263', phone: '0236100016', ratingAverage: 4.6, ratingCount: 72, followers: 3,
    listings: [
      { title: 'Lều cắm trại 4 người dựng nhanh', description: 'Dùng 1 chuyến, đủ cọc và dây.', price: 1490000, originalPrice: 2290000, condition: 'LIKE_NEW', categoryId: 'sports', attributes: { sport_type: 'Dã ngoại', brand: 'Quechua', size: '4 người' }, daysAgo: 1 },
      { title: 'Xe đạp địa hình Rockrider ST 100 size M', description: 'Đã bảo dưỡng, thay má phanh mới.', price: 3590000, condition: 'USED_GOOD', categoryId: 'sports', attributes: { sport_type: 'Đạp xe', brand: 'Rockrider', size: 'M' }, daysAgo: 3 },
      { title: 'Tạ tay điều chỉnh 20kg', description: 'Bộ tạ gang kèm thanh nối.', price: 790000, condition: 'USED_GOOD', categoryId: 'sports', attributes: { sport_type: 'Gym', brand: 'Domyos' }, daysAgo: 7 },
    ],
  },

  // Sách
  {
    key: 'sachxua', name: 'Sách Xưa Sài Gòn', username: 'sachxuasaigon', accentColor: '#7A4B2A',
    tagline: 'Sách cũ quý, bản in đầu', verificationType: 'CERTIFIED', verifiedDaysAgo: 140,
    description: 'Tiệm sách cũ 15 năm ở Sài Gòn, chuyên sách văn học và bản in hiếm. Sách được vệ sinh, bọc bìa.',
    categoryIds: ['books'], ward: '26743', phone: '0281000017', ratingAverage: 4.9, ratingCount: 189, followers: 4,
    listings: [
      { title: 'Bộ Tuyển tập Nguyễn Nhật Ánh 10 cuốn', description: 'Sách cũ giữ kỹ, gáy đẹp, đã bọc bìa.', price: 650000, condition: 'USED_GOOD', categoryId: 'books', attributes: { genre: 'novel', author: 'Nguyễn Nhật Ánh', quantity: 10 }, daysAgo: 0 },
      { title: 'Đắc Nhân Tâm bản in 1990', description: 'Bản in cũ hiếm, giấy ngả vàng tự nhiên.', price: 320000, condition: 'USED_FAIR', categoryId: 'books', attributes: { genre: 'skills', author: 'Dale Carnegie', quantity: 1 }, daysAgo: 3 },
      { title: 'Combo truyện tranh Doraemon 20 tập', description: 'Bản tái bản, sách sạch không ghi chú.', price: 280000, originalPrice: 400000, condition: 'USED_GOOD', categoryId: 'books', attributes: { genre: 'kids', author: 'Fujiko F. Fujio', quantity: 20 }, daysAgo: 5 },
    ],
  },
  {
    key: 'tiemsachgio', name: 'Tiệm Sách Gió', username: 'tiemsachgio', accentColor: '#2F7D6D',
    tagline: 'Sách học, văn phòng phẩm cho sinh viên', verificationType: 'CERTIFIED', verifiedDaysAgo: 10,
    description: 'Thu mua và bán lại giáo trình, sách ngoại ngữ. Có văn phòng phẩm mới giá tốt.',
    categoryIds: ['books'], ward: '00235', phone: '0241000018', ratingAverage: 4.7, ratingCount: 45, followers: 2,
    listings: [
      { title: 'Giáo trình Kinh tế vi mô và vĩ mô', description: 'Sách cũ của sinh viên, ghi chú bút chì ít.', price: 120000, condition: 'USED_GOOD', categoryId: 'books', attributes: { genre: 'textbook', author: 'NXB Kinh tế', quantity: 2 }, daysAgo: 1 },
      { title: 'Bộ sách luyện TOEIC ETS 2024', description: 'Mới 100%, kèm mã nghe online.', price: 360000, originalPrice: 450000, condition: 'NEW', categoryId: 'books', attributes: { genre: 'textbook', author: 'ETS', quantity: 2 }, daysAgo: 2 },
      { title: 'Combo bút gel và sổ tay A5 chấm', description: 'Hàng mới, 12 bút nhiều màu.', price: 150000, condition: 'NEW', categoryId: 'books', attributes: { genre: 'stationery', quantity: 13 }, daysAgo: 4 },
    ],
  },

  // Khác
  {
    key: 'canon', name: 'Canon Imaging Store', username: 'canonimaging', accentColor: '#CC0000',
    tagline: 'Máy ảnh, máy in chính hãng Canon', verificationType: 'OFFICIAL_BRAND', verifiedDaysAgo: 340,
    description: 'Cửa hàng Canon bán máy trưng bày và hàng đổi trả, bảo hành chính hãng.',
    categoryIds: ['electronics', 'other'], ward: '00166', phone: '0241000019', ratingAverage: 4.8, ratingCount: 199, followers: 5,
    listings: [
      { title: 'Máy ảnh Canon EOS R50 kèm lens 18-45', description: 'Máy trưng bày, shot 1.200, bảo hành hãng.', price: 15990000, originalPrice: 18990000, condition: 'LIKE_NEW', categoryId: 'electronics', attributes: { device_type: 'camera', brand: 'Canon', model: 'EOS R50', warranty: 'manufacturer', has_accessories: true }, daysAgo: 1 },
      { title: 'Máy in ảnh Canon SELPHY CP1500', description: 'Mới 100%, in ảnh 10x15 tại nhà.', price: 2690000, condition: 'NEW', categoryId: 'other', attributes: { brand: 'Canon' }, daysAgo: 3 },
      { title: 'Ống kính Canon RF 50mm f/1.8 STM', description: 'Hàng đổi trả, kính trong không mốc.', price: 3990000, condition: 'LIKE_NEW', categoryId: 'electronics', attributes: { device_type: 'camera', brand: 'Canon', model: 'RF 50mm f/1.8', warranty: 'manufacturer' }, daysAgo: 6 },
    ],
  },
  {
    key: 'retrohub', name: 'Retro Vintage Hub', username: 'retrovintage', accentColor: '#5B4B8A',
    tagline: 'Đồ cổ, máy film, đĩa than', verificationType: 'CERTIFIED', verifiedDaysAgo: 5,
    description: 'Chuyên đồ vintage: máy film, máy nghe đĩa than, đồng hồ cơ. Món nào cũng được thử trước khi giao.',
    categoryIds: ['other'], ward: '27094', phone: '0281000020', ratingAverage: 4.7, ratingCount: 58, followers: 3,
    listings: [
      { title: 'Máy film Olympus OM-10 kèm lens 50mm', description: 'Máy chạy tốt, đo sáng chuẩn, đã vệ sinh.', price: 2900000, condition: 'USED_GOOD', categoryId: 'other', attributes: { brand: 'Olympus' }, daysAgo: 0 },
      { title: 'Mâm đĩa than Audio-Technica LP60X', description: 'Dùng ít, kèm 2 đĩa than Trịnh Công Sơn.', price: 3200000, originalPrice: 3900000, condition: 'LIKE_NEW', categoryId: 'other', attributes: { brand: 'Audio-Technica' }, daysAgo: 2, allowExchange: true, exchangeWish: 'Đổi máy film Canon AE-1' },
      { title: 'Đồng hồ Seiko 5 cơ đời 1980', description: 'Máy chạy chuẩn, đã lau dầu.', price: 1800000, condition: 'USED_FAIR', categoryId: 'other', attributes: { brand: 'Seiko' }, daysAgo: 5 },
    ],
  },
];

/** Tài khoản Bán chuyên (gói BASIC), mỗi người 1-2 tin */
export const PRO_SELLERS: SeedProSeller[] = [
  {
    key: 'minhanh', fullName: 'Nguyễn Minh Anh', username: 'minhanhphone', phone: '0901234501', categoryId: 'phones', ward: '26884',
    ratingAverage: 4.7, ratingCount: 42,
    listings: [
      { title: 'iPhone 12 Pro Max 256GB vàng', description: 'Máy zin, pin 87%, Face ID nhạy. Bảo hành 3 tháng.', price: 9900000, condition: 'USED_GOOD', categoryId: 'phones', attributes: { brand: 'Apple', model: 'iPhone 12 Pro Max', storage: '256 GB', color: 'gold', origin: 'vn_a', battery_health: 87, warranty: 'store' }, daysAgo: 0 },
      { title: 'Samsung Galaxy A55 5G 128GB xanh', description: 'Mới 99%, còn bảo hành hãng 9 tháng.', price: 7200000, condition: 'LIKE_NEW', categoryId: 'phones', attributes: { brand: 'Samsung', model: 'Galaxy A55', storage: '128 GB', color: 'blue', origin: 'vn_a', warranty: 'manufacturer' }, daysAgo: 2 },
    ],
  },
  {
    key: 'quocbao', fullName: 'Trần Quốc Bảo', username: 'quocbaolaptop', phone: '0901234502', categoryId: 'electronics', ward: '00070',
    ratingAverage: 4.8, ratingCount: 63,
    listings: [
      { title: 'Laptop Dell XPS 13 9310 i7/16GB', description: 'Máy đẹp, màn 4K cảm ứng, pin 4 tiếng.', price: 15500000, condition: 'USED_GOOD', categoryId: 'electronics', attributes: { device_type: 'laptop', brand: 'Dell', model: 'XPS 13 9310', warranty: 'store', has_accessories: true }, daysAgo: 1 },
      { title: 'ThinkPad X1 Carbon Gen 9 i5/16GB', description: 'Bàn phím êm, kèm sạc 65W zin.', price: 13900000, condition: 'USED_GOOD', categoryId: 'electronics', attributes: { device_type: 'laptop', brand: 'Lenovo', model: 'ThinkPad X1 Carbon Gen 9', warranty: 'store', has_accessories: true }, daysAgo: 3 },
    ],
  },
  {
    key: 'thanhtam', fullName: 'Lê Thanh Tâm', username: 'thanhtamxe', phone: '0901234503', categoryId: 'vehicles', ward: '20242',
    ratingAverage: 4.5, ratingCount: 27,
    listings: [
      { title: 'Yamaha Exciter 155 2022 xanh GP', description: 'Xe chính chủ, đi 18.000 km, máy zin chưa bổ.', price: 41000000, condition: 'USED_GOOD', categoryId: 'vehicles', attributes: { vehicle_type: 'motorbike', brand: 'Yamaha', model: 'Exciter 155', year: 2022, mileage: 18000, engine_cc: 155, has_papers: true }, daysAgo: 1 },
    ],
  },
  {
    key: 'hoaithu', fullName: 'Đỗ Hoài Thu', username: 'hoaithucloset', phone: '0901234504', categoryId: 'fashion', ward: '26740',
    ratingAverage: 4.9, ratingCount: 88,
    listings: [
      { title: 'Đầm lụa Zara size S xanh rêu', description: 'Mặc 1 lần đi tiệc, giặt khô sạch sẽ.', price: 450000, condition: 'LIKE_NEW', categoryId: 'fashion', attributes: { product_type: 'clothes', gender: 'women', size: 'S', brand: 'Zara', material: 'Lụa' }, daysAgo: 0 },
      { title: 'Túi Charles & Keith kem', description: 'Dùng vài lần, không trầy góc.', price: 690000, condition: 'USED_GOOD', categoryId: 'fashion', attributes: { product_type: 'bags', gender: 'women', brand: 'Charles & Keith' }, daysAgo: 4 },
    ],
  },
  {
    key: 'giahuy', fullName: 'Phạm Gia Huy', username: 'giahuyhome', phone: '0901234505', categoryId: 'appliances', ward: '00256',
    ratingAverage: 4.6, ratingCount: 35,
    listings: [
      { title: 'Máy lọc không khí Sharp FP-J40E', description: 'Dùng 1 năm, đã thay màng lọc mới.', price: 1900000, condition: 'USED_GOOD', categoryId: 'appliances', attributes: { appliance_type: 'other', brand: 'Sharp', power: 40, warranty: 'none' }, daysAgo: 2 },
    ],
  },
];
