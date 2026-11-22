/*
 * Danh mục mặc định theo mô hình 2 cấp (danh mục cha › danh mục con).
 * Mỗi danh mục cha là một dòng Category (giữ luật hạn mức, giá xu, gói cửa hàng); danh mục con nằm trong
 * metadata.subcategories. Thuộc tính hiệu lực của tin = attributes của cha + attributes của con.
 * Thuộc tính có `filter` thành bộ lọc của danh mục con, theo kiểu hiển thị:
 *   "single" chip chọn một (single_chip_choice), "multi" chip chọn nhiều (multiple_chip_choice),
 *   "list" chọn một trong danh sách dài có ô tìm (single_choice: Hãng, Màu, Giống), "range" khoảng số.
 * Mỗi danh mục con có priceMax: đầu trên thanh trượt giá trong bộ lọc.
 * Tình trạng lọc theo nhóm ở app (Còn bảo hành / Mới / Đã sử dụng) nên thuộc tính warranty không có filter.
 *
 * Thứ tự ở đây là thứ tự hiển thị, phải khớp CATEGORY_ORDER trong src/modules/catalog/catalog.type.ts
 * (seed.ts kiểm tra trước khi chạy).
 */

type Text = { vi: string; en: string };
type Option = { value: string; label?: Text };
type Attribute = {
  key: string;
  type: 'select' | 'text' | 'number' | 'boolean';
  label: Text;
  required?: boolean;
  filter?: 'single' | 'multi' | 'list' | 'range';
  options?: Option[];
  hint?: Text;
  maxLength?: number;
  unit?: string | Text | null;
  min?: number;
  max?: number;
};
type Subcategory = { id: string; name: Text; attributes: Attribute[]; hasCondition?: boolean; priceMax?: number };

export type CategorySeed = { id: string; name: Text } & Record<string, unknown>;

const t = (vi: string, en = vi): Text => ({ vi, en });

/** Lựa chọn là tên riêng (hãng, dung lượng): giá trị = nhãn. "other" luôn có nhãn Khác */
const names = (...values: string[]): Option[] =>
  values.map((value) => (value === 'other' ? { value, label: t('Khác', 'Other') } : { value }));

/** Lựa chọn có nhãn vi/en: [value, vi, en] */
const labelled = (...rows: [string, string, string?][]): Option[] =>
  rows.map(([value, vi, en]) => ({ value, label: t(vi, en ?? vi) }));

const OTHER: [string, string, string] = ['other', 'Khác', 'Other'];

const select = (key: string, label: Text, options: Option[], extra: Partial<Attribute> = {}): Attribute =>
  ({ key, type: 'select', label, required: false, options, ...extra });

/** Thuộc tính lọc dạng chọn trong danh sách dài có ô tìm (single_choice) */
const LIST_FILTERS = new Set(['brand', 'color', 'breed']);
/** Thuộc tính lọc dạng chip chọn nhiều (multiple_chip_choice / multiple_choice) */
const MULTI_FILTERS = new Set(['storage', 'ram', 'cpu', 'drive_type', 'drive_capacity', 'gpu', 'screen_size', 'monitor',
  'payload', 'frame_size', 'owners', 'material', 'bed_size', 'volume', 'cooling_capacity', 'gender']);

/** select vừa nhập vừa lọc; còn lại (các trường "Loại...", nhiên liệu, hộp số...) là chip chọn một */
const filterSelect = (key: string, label: Text, options: Option[], extra: Partial<Attribute> = {}): Attribute =>
  select(key, label, options, {
    filter: LIST_FILTERS.has(key) ? 'list' : MULTI_FILTERS.has(key) ? 'multi' : 'single', ...extra,
  });

const text = (key: string, label: Text, extra: Partial<Attribute> = {}): Attribute =>
  ({ key, type: 'text', label, required: false, maxLength: 60, ...extra });

const number = (key: string, label: Text, min: number, max: number, extra: Partial<Attribute> = {}): Attribute =>
  ({ key, type: 'number', label, required: false, min, max, ...extra });

const flag = (key: string, label: Text): Attribute => ({ key, type: 'boolean', label });

/* ---------- Thuộc tính dùng lại ---------- */

const brand = (...values: string[]) => filterSelect('brand', t('Hãng', 'Brand'), names(...values, 'other'), { required: true });
const brandText = (required = false) => text('brand', t('Hãng', 'Brand'), { required });
const model = (hint: Text, required = false) => text('model', t('Dòng máy', 'Model'), { hint, required });
const year = number('year', t('Năm sản xuất', 'Year'), 1980, 2030, { filter: 'range', unit: null });
const mileage = number('mileage', t('Số km đã đi', 'Mileage'), 0, 2000000, { filter: 'range', unit: 'km' });
const hasPapers = flag('has_papers', t('Còn giấy tờ chính chủ', 'Has registration papers'));
const fuel = filterSelect('fuel', t('Nhiên liệu', 'Fuel'),
  labelled(['petrol', 'Xăng', 'Petrol'], ['diesel', 'Dầu', 'Diesel'], ['hybrid', 'Hybrid'], ['electric', 'Điện', 'Electric']));
const warranty = select('warranty', t('Bảo hành', 'Warranty'),
  labelled(['none', 'Hết bảo hành', 'No warranty'], ['manufacturer', 'Còn bảo hành hãng', 'Manufacturer warranty'],
    ['store', 'Bảo hành cửa hàng', 'Store warranty']));
const storage = filterSelect('storage', t('Dung lượng', 'Storage'),
  names('16 GB', '32 GB', '64 GB', '128 GB', '256 GB', '512 GB', '1 TB'));
const color = filterSelect('color', t('Màu sắc', 'Color'), labelled(
  ['black', 'Đen', 'Black'], ['white', 'Trắng', 'White'], ['silver', 'Bạc', 'Silver'], ['gold', 'Vàng', 'Gold'],
  ['gray', 'Xám', 'Gray'], ['blue', 'Xanh dương', 'Blue'], ['green', 'Xanh lá', 'Green'], ['red', 'Đỏ', 'Red'],
  ['purple', 'Tím', 'Purple'], ['pink', 'Hồng', 'Pink'], OTHER));
const cpu = filterSelect('cpu', t('Bộ vi xử lý', 'Processor'), names(
  'Intel Core i3', 'Intel Core i5', 'Intel Core i7', 'Intel Core i9', 'Intel Core Ultra', 'Intel Celeron / Pentium',
  'AMD Ryzen 3', 'AMD Ryzen 5', 'AMD Ryzen 7', 'AMD Ryzen 9', 'Apple M1', 'Apple M2', 'Apple M3', 'Apple M4', 'other'));
const ram = filterSelect('ram', t('RAM', 'RAM'), names('4 GB', '8 GB', '16 GB', '32 GB', '64 GB', 'other'));
const driveType = filterSelect('drive_type', t('Loại ổ cứng', 'Drive type'), names('SSD', 'HDD', 'SSD + HDD'));
const driveCapacity = filterSelect('drive_capacity', t('Dung lượng ổ cứng', 'Drive capacity'),
  names('128 GB', '256 GB', '512 GB', '1 TB', '2 TB', 'other'));
const gpu = filterSelect('gpu', t('Card màn hình', 'Graphics card'),
  labelled(['onboard', 'Onboard'], ['nvidia', 'NVIDIA'], ['amd', 'AMD'], OTHER));
const productType = (options: Option[], required = true) =>
  filterSelect('product_type', t('Loại sản phẩm', 'Product type'), options, { required });
const material = (options?: Option[]) => options
  ? filterSelect('material', t('Chất liệu', 'Material'), options)
  : text('material', t('Chất liệu', 'Material'));
const furnitureMaterial = material(labelled(
  ['wood', 'Gỗ', 'Wood'], ['plastic', 'Nhựa', 'Plastic'], ['metal', 'Sắt, inox', 'Metal'], ['glass', 'Kính, đá', 'Glass, stone'],
  ['fabric', 'Vải, nệm', 'Fabric'], ['leather', 'Da', 'Leather'], ['rattan', 'Mây tre', 'Rattan'], OTHER));
const dimensions = text('dimensions', t('Kích thước', 'Dimensions'), { hint: t('VD: 120 x 60 x 75 cm', 'e.g. 120 x 60 x 75 cm') });
const petGender = (male: string, female: string) => filterSelect('pet_gender', t('Giới tính', 'Gender'),
  labelled(['male', male, 'Male'], ['female', female, 'Female'], ['unknown', 'Không rõ', 'Unknown']));
const vaccinated = flag('vaccinated', t('Đã tiêm phòng', 'Vaccinated'));
const ageGroup = (young: string, adult: string) => filterSelect('age_group', t('Độ tuổi', 'Age'),
  labelled(['young', young, 'Under 3 months'], ['junior', 'Dưới 1 năm tuổi', 'Under 1 year'],
    ['adult', adult, 'Over 1 year'], ['unknown', 'Không rõ', 'Unknown']));
const breed = (options: Option[]) => filterSelect('breed', t('Giống', 'Breed'), options);

/** Đầu trên thanh trượt giá (VND) theo danh mục con */
const M = 1_000_000;
const PRICE_MAX: Record<string, number> = {
  'o-to': 5000 * M, 'xe-may': 100 * M, 'xe-tai': 1500 * M, 'xe-dap': 20 * M, 'phuong-tien-khac': 100 * M, 'phu-tung-xe': 10 * M,
  'dien-thoai': 50 * M, 'may-tinh-bang': 50 * M, laptop: 100 * M, 'may-tinh-de-ban': 50 * M, 'may-anh': 100 * M,
  'tivi-am-thanh': 100 * M, 'thiet-bi-deo': 50 * M, 'phu-kien': 50 * M, 'linh-kien': 50 * M,
  ga: 10 * M, cho: 50 * M, chim: 50 * M, meo: 50 * M, 'thu-cung-khac': 50 * M, 'phu-kien-thuc-an': 30 * M,
  'tu-lanh': 100 * M, 'may-lanh': 100 * M, 'may-giat': 100 * M,
  'ban-ghe': 100 * M, 'tu-ke': 100 * M, 'giuong-nem': 100 * M, 'bep-do-dien': 100 * M, 'dung-cu-bep': 100 * M, quat: 30 * M,
  den: 100 * M, 'cay-canh-trang-tri': 200 * M, 'thiet-bi-ve-sinh': 100 * M, 'gia-dung-khac': 100 * M,
  'do-dung-van-phong': 100 * M, 'do-chuyen-dung': 300 * M,
  'nhac-cu': 30 * M, sach: 10 * M, 'the-thao-da-ngoai': 100 * M, 'do-suu-tam': 50 * M, 'thiet-bi-game': 100 * M, 'so-thich-khac': 50 * M,
  'quan-ao': 100 * M, 'dong-ho': 50 * M, 'giay-dep': 100 * M, 'tui-xach': 20 * M, 'nuoc-hoa': 10 * M, 'phu-kien-thoi-trang': 30 * M,
  'me-va-be': 10 * M,
};

const sub = (id: string, name: Text, attributes: Attribute[], extra: Partial<Subcategory> = {}): Subcategory =>
  ({ id, name, attributes, priceMax: PRICE_MAX[id] ?? 100 * M, ...extra });

/** priceMax của danh mục cha = lớn nhất trong các danh mục con (lọc khi chưa chọn danh mục con) */
const category = (id: string, name: Text, info: {
  description: Text; icon: string; imageUrl?: string; hasCondition?: boolean;
  attributes?: Attribute[]; subcategories: Subcategory[];
}): CategorySeed => ({
  id, name, ...info, attributes: info.attributes ?? [],
  priceMax: Math.max(...info.subcategories.map((item) => item.priceMax ?? 0)),
});

export const CATEGORIES: CategorySeed[] = [
  category('vehicles', t('Xe cộ', 'Vehicles'), {
    description: t('Ô tô, xe máy, xe tải, xe đạp, phụ tùng...', 'Cars, motorbikes, trucks, bicycles, parts...'),
    icon: 'vehicle', imageUrl: 'assets/images/categories/vehicles.png',
    subcategories: [
      sub('o-to', t('Ô tô', 'Cars'), [
        brand('Toyota', 'Hyundai', 'Kia', 'Ford', 'Mazda', 'Honda', 'Mitsubishi', 'VinFast', 'Mercedes-Benz', 'BMW',
          'Chevrolet', 'Nissan', 'Suzuki', 'Lexus', 'Peugeot'),
        model(t('VD: Vios 1.5G', 'e.g. Vios 1.5G'), true), year, mileage, fuel,
        filterSelect('gearbox', t('Hộp số', 'Gearbox'),
          labelled(['automatic', 'Tự động', 'Automatic'], ['manual', 'Số sàn', 'Manual'], ['semi', 'Bán tự động', 'Semi-automatic'])),
        filterSelect('owners', t('Số đời chủ', 'Owners'), labelled(['one', '1 chủ', 'One owner'], ['many', 'Nhiều hơn 1 chủ', 'More than one'])),
        hasPapers,
      ]),
      sub('xe-may', t('Xe máy', 'Motorbikes'), [
        brand('Honda', 'Yamaha', 'Piaggio', 'Suzuki', 'SYM', 'VinFast', 'Kymco', 'Kawasaki', 'Ducati', 'Yadea', 'Dat Bike', 'Pega'),
        model(t('VD: Vision 2022, Air Blade 125', 'e.g. Vision 2022'), true),
        filterSelect('bike_type', t('Loại xe', 'Type'), labelled(
          ['scooter', 'Tay ga', 'Scooter'], ['manual', 'Xe số', 'Underbone'], ['clutch', 'Tay côn / Moto', 'Clutch / Motorcycle'],
          ['electric', 'Xe máy điện', 'Electric']), { required: true }),
        filterSelect('engine_size', t('Dung tích xe', 'Engine size'), labelled(
          ['lt50', 'Dưới 50 cc', 'Under 50 cc'], ['50_100', '50 - 100 cc'], ['100_175', '100 - 175 cc'], ['gt175', 'Trên 175 cc', 'Over 175 cc'],
          ['unknown', 'Không rõ', 'Unknown'])),
        year, mileage, hasPapers,
      ]),
      sub('xe-tai', t('Xe tải, xe ben', 'Trucks'), [
        brand('Hyundai', 'Isuzu', 'Hino', 'Thaco', 'Suzuki', 'Kia', 'Dongfeng', 'Veam', 'Mitsubishi Fuso', 'JAC'),
        model(t('VD: Porter H150', 'e.g. Porter H150')),
        filterSelect('payload', t('Trọng tải', 'Payload'), labelled(
          ['lt1', 'Dưới 1 tấn', 'Under 1 t'], ['1_2_5', '1 - 2,5 tấn', '1 - 2.5 t'], ['2_5_5', '2,5 - 5 tấn', '2.5 - 5 t'],
          ['5_10', '5 - 10 tấn', '5 - 10 t'], ['gt10', 'Trên 10 tấn', 'Over 10 t'])),
        fuel, year, mileage, hasPapers,
      ]),
      sub('xe-dap', t('Xe đạp', 'Bicycles'), [
        filterSelect('bicycle_type', t('Loại xe đạp', 'Type'), labelled(
          ['city', 'Xe đạp phổ thông', 'City bike'], ['sport', 'Xe đạp thể thao', 'Sport bike'], ['kids', 'Xe đạp trẻ em', 'Kids bike'],
          ['electric', 'Xe đạp điện', 'E-bike'], OTHER), { required: true }),
        filterSelect('brand', t('Hãng', 'Brand'), names('Giant', 'Trek', 'Asama', 'Thống Nhất', 'Fornix', 'Twitter', 'Galaxy',
          'Jett', 'Specialized', 'Merida', 'other')),
        filterSelect('frame_size', t('Kích thước khung', 'Frame size'), names('XS', 'S', 'M', 'L', 'XL')),
      ]),
      sub('phuong-tien-khac', t('Phương tiện khác', 'Other vehicles'), [
        filterSelect('vehicle_kind', t('Loại xe', 'Type'), labelled(
          ['special', 'Xe chuyên dụng', 'Special-purpose'], ['bus', 'Xe khách, xe buýt', 'Bus, coach'], OTHER), { required: true }),
        brandText(), year, mileage, hasPapers,
      ]),
      sub('phu-tung-xe', t('Phụ tùng xe', 'Vehicle parts'), [
        filterSelect('part_type', t('Loại phụ tùng', 'Part type'), labelled(
          ['motorbike', 'Phụ tùng xe máy', 'Motorbike parts'], ['car', 'Phụ tùng ô tô', 'Car parts'],
          ['truck', 'Phụ tùng xe tải', 'Truck parts'], ['electric', 'Phụ tùng xe điện', 'EV parts'],
          ['bicycle', 'Phụ tùng xe đạp', 'Bicycle parts'], OTHER), { required: true }),
        brandText(),
      ]),
    ],
  }),

  category('electronics', t('Điện tử', 'Electronics'), {
    description: t('Điện thoại, laptop, máy tính bảng, máy ảnh...', 'Phones, laptops, tablets, cameras...'),
    icon: 'electronics', imageUrl: 'assets/images/categories/electronics.png',
    attributes: [warranty],
    subcategories: [
      sub('dien-thoai', t('Điện thoại', 'Phones'), [
        brand('Apple', 'Samsung', 'Xiaomi', 'OPPO', 'vivo', 'realme', 'Honor', 'Google', 'Huawei', 'OnePlus', 'Sony', 'Nokia', 'ASUS'),
        model(t('VD: iPhone 14 Pro Max', 'e.g. iPhone 14 Pro Max'), true), storage, color,
        select('origin', t('Xuất xứ', 'Origin'),
          labelled(['vn_a', 'Chính hãng VN/A', 'Official VN/A'], ['international', 'Quốc tế', 'International'], ['lock', 'Bản lock', 'Carrier locked'])),
        number('battery_health', t('Tình trạng pin', 'Battery health'), 1, 100, { unit: '%' }),
      ]),
      sub('may-tinh-bang', t('Máy tính bảng', 'Tablets'), [
        brand('Apple', 'Samsung', 'Xiaomi', 'Lenovo', 'Huawei', 'OPPO', 'Honor', 'Amazon'),
        model(t('VD: iPad Air 5', 'e.g. iPad Air 5'), true), storage,
        filterSelect('screen_size', t('Kích cỡ màn hình', 'Screen size'), labelled(
          ['lt8', 'Dưới 8 inch', 'Under 8"'], ['8_10', '8 - 10 inch', '8 - 10"'], ['10_12', '10 - 12 inch', '10 - 12"'], ['gt12', 'Trên 12 inch', 'Over 12"'])),
      ]),
      sub('laptop', t('Laptop', 'Laptops'), [
        brand('Apple', 'Dell', 'Lenovo', 'ASUS', 'HP', 'Acer', 'MSI', 'Microsoft', 'Gigabyte', 'LG', 'Samsung'),
        model(t('VD: MacBook Air M2', 'e.g. MacBook Air M2'), true), cpu, ram, driveType, driveCapacity, gpu,
        filterSelect('screen_size', t('Kích cỡ màn hình', 'Screen size'), labelled(
          ['lt13', 'Dưới 13 inch', 'Under 13"'], ['13_15', '13 - 14.9 inch', '13 - 14.9"'], ['15_17', '15 - 16.9 inch', '15 - 16.9"'],
          ['gte17', 'Từ 17 inch', '17" and up'])),
      ]),
      sub('may-tinh-de-ban', t('Máy tính để bàn', 'Desktops'), [
        brandText(), cpu, ram, driveType, driveCapacity, gpu,
        filterSelect('monitor', t('Màn hình', 'Monitor'), labelled(
          ['none', 'Không kèm màn hình', 'No monitor'], ['lt22', 'Dưới 22 inch', 'Under 22"'], ['22_27', '22 - 27 inch', '22 - 27"'],
          ['gt27', 'Trên 27 inch', 'Over 27"'])),
      ]),
      sub('may-anh', t('Máy ảnh, máy quay', 'Cameras'), [
        filterSelect('camera_type', t('Thiết bị', 'Device'), labelled(
          ['camera', 'Máy ảnh', 'Camera'], ['camcorder', 'Máy quay', 'Camcorder'], ['lens', 'Ống kính', 'Lens'], OTHER), { required: true }),
        filterSelect('brand', t('Hãng', 'Brand'), names('Canon', 'Sony', 'Nikon', 'Fujifilm', 'Panasonic', 'Olympus', 'Leica', 'DJI',
          'GoPro', 'other')),
        model(t('VD: Sony A7 III', 'e.g. Sony A7 III')),
      ]),
      sub('tivi-am-thanh', t('Tivi, âm thanh', 'TV & audio'), [
        filterSelect('av_type', t('Thiết bị', 'Device'), labelled(
          ['tv', 'Tivi', 'TV'], ['speaker', 'Loa', 'Speaker'], ['headphone', 'Tai nghe', 'Headphones'], ['amplifier', 'Amply', 'Amplifier'],
          ['karaoke', 'Dàn karaoke', 'Karaoke'], ['microphone', 'Micro', 'Microphone'], OTHER), { required: true }),
        filterSelect('brand', t('Hãng', 'Brand'), names('Samsung', 'LG', 'Sony', 'TCL', 'Xiaomi', 'Panasonic', 'JBL', 'Marshall',
          'Bose', 'Apple', 'other')),
        model(t('VD: AirPods Pro 2', 'e.g. AirPods Pro 2')),
      ]),
      sub('thiet-bi-deo', t('Thiết bị đeo thông minh', 'Wearables'), [
        filterSelect('wearable_type', t('Thiết bị', 'Device'), labelled(
          ['smartwatch', 'Đồng hồ thông minh', 'Smartwatch'], ['band', 'Vòng tay thông minh', 'Fitness band'], OTHER), { required: true }),
        filterSelect('brand', t('Hãng', 'Brand'), names('Apple', 'Samsung', 'Garmin', 'Xiaomi', 'Huawei', 'Amazfit', 'Google', 'other')),
        model(t('VD: Apple Watch Series 9', 'e.g. Apple Watch Series 9')),
      ]),
      sub('phu-kien', t('Phụ kiện (màn hình, chuột...)', 'Accessories'), [
        filterSelect('accessory_type', t('Loại phụ kiện', 'Accessory type'), labelled(
          ['computer', 'Phụ kiện máy tính', 'Computer accessories'], ['phone', 'Phụ kiện điện thoại', 'Phone accessories'], OTHER),
        { required: true }),
        brandText(), model(t('VD: Logitech MX Master 3S', 'e.g. Logitech MX Master 3S')),
      ]),
      sub('linh-kien', t('Linh kiện (RAM, card...)', 'Components'), [
        filterSelect('component_type', t('Loại linh kiện', 'Component type'), labelled(
          ['computer', 'Linh kiện máy tính', 'Computer components'], ['phone', 'Linh kiện điện thoại', 'Phone components'], OTHER),
        { required: true }),
        brandText(), model(t('VD: RTX 3060 12GB', 'e.g. RTX 3060 12GB')),
      ]),
    ],
  }),

  category('pets', t('Thú cưng', 'Pets'), {
    description: t('Chó, mèo, chim, gà, phụ kiện thú cưng...', 'Dogs, cats, birds, pet supplies...'),
    icon: 'pet', imageUrl: 'assets/images/categories/pets.png', hasCondition: false,
    subcategories: [
      sub('ga', t('Gà', 'Chickens'), [
        breed(labelled(['choi', 'Gà chọi', 'Fighting'], ['tre', 'Gà tre', 'Bantam'], ['serama', 'Gà Serama', 'Serama'],
          ['ta', 'Gà ta', 'Local'], ['dong_tao', 'Gà Đông Tảo', 'Dong Tao'], ['ac', 'Gà ác', 'Silkie'], OTHER)),
        filterSelect('age_group', t('Độ tuổi', 'Age'), labelled(['young', 'Gà con (dưới 3 tháng)', 'Chick'], ['adult', 'Gà lớn (từ 3 tháng)', 'Adult'])),
        petGender('Trống', 'Mái'),
      ]),
      sub('cho', t('Chó', 'Dogs'), [
        breed(labelled(['poodle', 'Poodle'], ['co', 'Chó cỏ', 'Local'], ['pomeranian', 'Phốc sóc', 'Pomeranian'], ['corgi', 'Corgi'],
          ['phu_quoc', 'Phú Quốc'], ['gsd', 'Becgie', 'German Shepherd'], ['chihuahua', 'Chihuahua'], ['husky', 'Husky'],
          ['alaska', 'Alaska'], ['golden', 'Golden Retriever'], ['pug', 'Pug'], ['shiba', 'Shiba'], OTHER)),
        filterSelect('pet_size', t('Kích cỡ', 'Size'), labelled(
          ['tiny', 'Siêu nhỏ (tiny, teacup)', 'Tiny'], ['small', 'Nhỏ', 'Small'], ['medium', 'Trung bình', 'Medium'], ['large', 'Lớn', 'Large'])),
        ageGroup('Chó con (dưới 3 tháng)', 'Chó trưởng thành (trên 1 năm)'), petGender('Đực', 'Cái'), vaccinated,
      ]),
      sub('chim', t('Chim', 'Birds'), [
        breed(labelled(['chao_mao', 'Chào mào'], ['cu_gay', 'Cu gáy'], ['vet', 'Vẹt', 'Parrot'], ['chich_choe', 'Chích choè'],
          ['bo_cau', 'Bồ câu', 'Pigeon'], ['khuou', 'Khướu'], ['vanh_khuyen', 'Vành khuyên'], ['hoa_mi', 'Hoạ mi'], OTHER)),
        filterSelect('age_group', t('Độ tuổi', 'Age'), labelled(['young', 'Chim non (dưới 3 tháng)', 'Fledgling'], ['adult', 'Chim lớn', 'Adult'])),
        petGender('Trống', 'Mái'),
      ]),
      sub('meo', t('Mèo', 'Cats'), [
        breed(labelled(['british_short', 'Anh lông ngắn', 'British Shorthair'], ['british_long', 'Anh lông dài', 'British Longhair'],
          ['ta', 'Mèo ta', 'Local'], ['munchkin', 'Munchkin'], ['persian', 'Ba Tư', 'Persian'], ['bengal', 'Bengal'],
          ['siamese', 'Xiêm', 'Siamese'], ['scottish', 'Scottish Fold'], OTHER)),
        ageGroup('Mèo con (dưới 3 tháng)', 'Mèo trưởng thành (trên 1 năm)'), petGender('Đực', 'Cái'), vaccinated,
      ]),
      sub('thu-cung-khac', t('Thú cưng khác', 'Other pets'), [
        filterSelect('pet_kind', t('Loại', 'Kind'), labelled(['fish', 'Cá cảnh', 'Fish'], ['hamster', 'Chuột cảnh', 'Hamster'],
          ['rabbit', 'Thỏ cảnh', 'Rabbit'], ['hedgehog', 'Nhím cảnh', 'Hedgehog'], ['reptile', 'Bò sát', 'Reptile'], OTHER), { required: true }),
      ]),
      sub('phu-kien-thuc-an', t('Phụ kiện, thức ăn, dịch vụ', 'Supplies & services'), [
        filterSelect('supply_type', t('Loại', 'Type'), labelled(['food', 'Thức ăn', 'Food'], ['accessory', 'Phụ kiện', 'Accessory'],
          ['cage', 'Chuồng, lồng, bể', 'Cage, tank'], ['service', 'Dịch vụ', 'Service'], OTHER)),
      ], { hasCondition: true }),
    ],
  }),

  category('appliances', t('Điện lạnh', 'Cooling & laundry'), {
    description: t('Tủ lạnh, máy lạnh, máy giặt', 'Fridges, air conditioners, washers'),
    icon: 'appliance', imageUrl: 'assets/images/categories/appliances.png',
    attributes: [warranty],
    subcategories: [
      sub('tu-lanh', t('Tủ lạnh', 'Fridges'), [
        brand('Samsung', 'LG', 'Panasonic', 'Toshiba', 'Hitachi', 'Sharp', 'Electrolux', 'Aqua', 'Beko', 'Mitsubishi Electric', 'Casper'),
        filterSelect('volume', t('Thể tích', 'Volume'), labelled(
          ['lt150', 'Dưới 150 lít', 'Under 150 L'], ['150_300', '150 - 299 lít', '150 - 299 L'], ['300_400', '300 - 399 lít', '300 - 399 L'],
          ['400_500', '400 - 499 lít', '400 - 499 L'], ['gte500', 'Từ 500 lít', '500 L and up'])),
      ]),
      sub('may-lanh', t('Máy lạnh, điều hoà', 'Air conditioners'), [
        brand('Daikin', 'Panasonic', 'LG', 'Samsung', 'Toshiba', 'Mitsubishi Electric', 'Casper', 'Gree', 'Sharp', 'Midea', 'Funiki', 'Aqua'),
        filterSelect('cooling_capacity', t('Công suất', 'Capacity'), labelled(
          ['1hp', '1 HP (9.000 BTU)'], ['1_5hp', '1.5 HP (12.000 BTU)'], ['2hp', '2 HP (18.000 BTU)'], ['gt2hp', 'Trên 2 HP', 'Over 2 HP'])),
        flag('inverter', t('Inverter', 'Inverter')),
      ]),
      sub('may-giat', t('Máy giặt', 'Washers'), [
        brand('Samsung', 'LG', 'Electrolux', 'Toshiba', 'Panasonic', 'Aqua', 'Sharp', 'Hitachi', 'Beko', 'Bosch', 'Casper'),
        filterSelect('load_type', t('Cửa máy giặt', 'Loading'), labelled(['front', 'Cửa trước (lồng ngang)', 'Front load'],
          ['top', 'Cửa trên (lồng đứng)', 'Top load'])),
        filterSelect('wash_weight', t('Khối lượng giặt', 'Wash load'), labelled(['lt8', 'Dưới 8 kg', 'Under 8 kg'],
          ['8_10', '8 - 9.9 kg'], ['gte10', 'Từ 10 kg', '10 kg and up'])),
      ]),
    ],
  }),

  category('furniture', t('Nội thất, cây cảnh', 'Home & garden'), {
    description: t('Bàn ghế, tủ kệ, đồ gia dụng, cây cảnh...', 'Furniture, kitchen, decor, plants...'),
    icon: 'home', imageUrl: 'assets/images/categories/furniture.png',
    subcategories: [
      sub('ban-ghe', t('Bàn ghế', 'Tables & chairs'), [
        productType(labelled(['stool', 'Ghế đẩu', 'Stool'], ['chair', 'Ghế dựa', 'Chair'], ['office_chair', 'Ghế văn phòng', 'Office chair'],
          ['massage_chair', 'Ghế massage', 'Massage chair'], ['sofa', 'Sofa'], ['coffee_table', 'Bàn cà phê', 'Coffee table'],
          ['dining_table', 'Bàn ăn', 'Dining table'], ['desk', 'Bàn làm việc', 'Desk'], OTHER)),
        furnitureMaterial, dimensions,
      ]),
      sub('tu-ke', t('Tủ, kệ gia đình', 'Cabinets & shelves'), [
        productType(labelled(['wardrobe', 'Tủ quần áo', 'Wardrobe'], ['shoe', 'Tủ, kệ giày', 'Shoe rack'], ['book', 'Kệ sách', 'Bookshelf'],
          ['tv', 'Kệ tivi', 'TV stand'], ['kitchen', 'Tủ bếp', 'Kitchen cabinet'], ['bedside', 'Tủ đầu giường', 'Nightstand'],
          ['display', 'Tủ trưng bày', 'Display cabinet'], OTHER)),
        furnitureMaterial, dimensions,
      ]),
      sub('giuong-nem', t('Giường, chăn ga gối nệm', 'Beds & bedding'), [
        productType(labelled(['bed', 'Giường', 'Bed'], ['mattress', 'Nệm', 'Mattress'], ['bedding', 'Chăn, ga, vỏ gối', 'Bedding'],
          ['pillow', 'Ruột gối', 'Pillow'], OTHER)),
        filterSelect('bed_size', t('Kích cỡ', 'Size'), labelled(['2_2_2', '2m x 2.2m'], ['1_8_2', '1.8m x 2m'], ['1_6_2', '1.6m x 2m'],
          ['1_5_1_9', '1.5m x 1.9m'], ['1_2_1_9', '1.2m x 1.9m'], ['bunk', 'Giường tầng', 'Bunk bed'], OTHER)),
      ]),
      sub('bep-do-dien', t('Bếp, lò, đồ điện nhà bếp', 'Kitchen appliances'), [
        productType(labelled(['rice_cooker', 'Nồi cơm điện', 'Rice cooker'], ['air_fryer', 'Nồi chiên không dầu', 'Air fryer'],
          ['microwave', 'Lò vi sóng', 'Microwave'], ['oven', 'Lò nướng', 'Oven'], ['cooktop', 'Bếp điện, bếp từ', 'Electric cooktop'],
          ['gas_stove', 'Bếp gas', 'Gas stove'], ['blender', 'Máy xay', 'Blender'], ['coffee', 'Máy pha cà phê', 'Coffee maker'],
          ['kettle', 'Ấm siêu tốc', 'Kettle'], ['water_purifier', 'Máy lọc nước', 'Water purifier'], ['hood', 'Máy hút mùi', 'Range hood'], OTHER)),
        brandText(), warranty,
      ]),
      sub('dung-cu-bep', t('Dụng cụ nhà bếp', 'Kitchenware'), [
        productType(labelled(['pot', 'Nồi', 'Pot'], ['pan', 'Chảo', 'Pan'], ['knife', 'Dao, kéo, thớt', 'Knives & boards'],
          ['dish', 'Chén, bát, đĩa', 'Dishes'], ['glass', 'Ly, cốc', 'Glasses'], ['flask', 'Bình giữ nhiệt', 'Flask'],
          ['container', 'Hộp đựng thực phẩm', 'Food container'], OTHER)),
      ]),
      sub('quat', t('Quạt', 'Fans'), [
        productType(labelled(['stand', 'Quạt đứng', 'Stand fan'], ['wall', 'Quạt treo tường', 'Wall fan'], ['ceiling', 'Quạt trần', 'Ceiling fan'],
          ['box', 'Quạt hộp', 'Box fan'], ['cooler', 'Quạt điều hoà, hơi nước', 'Air cooler'], ['mini', 'Quạt mini, quạt sạc', 'Mini fan'], OTHER)),
        filterSelect('brand', t('Hãng', 'Brand'), names('Asia', 'Senko', 'Panasonic', 'Toshiba', 'Midea', 'Mitsubishi', 'Sunhouse',
          'Kangaroo', 'Xiaomi', 'other')),
      ]),
      sub('den', t('Đèn', 'Lighting'), [
        productType(labelled(['pendant', 'Đèn thả', 'Pendant'], ['chandelier', 'Đèn chùm', 'Chandelier'], ['ceiling', 'Đèn ốp trần', 'Ceiling light'],
          ['desk', 'Đèn bàn', 'Desk lamp'], ['night', 'Đèn ngủ', 'Night light'], ['decor', 'Đèn trang trí', 'Decorative'],
          ['outdoor', 'Đèn ngoài trời', 'Outdoor'], ['flashlight', 'Đèn pin', 'Flashlight'], OTHER)),
      ]),
      sub('cay-canh-trang-tri', t('Cây cảnh, đồ trang trí', 'Plants & decor'), [
        productType(labelled(['indoor_plant', 'Cây cảnh trong nhà', 'Indoor plant'], ['outdoor_plant', 'Cây cảnh ngoài trời', 'Outdoor plant'],
          ['pot', 'Chậu cây', 'Plant pot'], ['indoor_decor', 'Đồ trang trí trong nhà', 'Indoor decor'],
          ['outdoor_decor', 'Đồ trang trí ngoài trời', 'Outdoor decor'], OTHER)),
      ]),
      sub('thiet-bi-ve-sinh', t('Thiết bị vệ sinh, nhà tắm', 'Bathroom'), [
        productType(labelled(['water_heater', 'Bình nóng lạnh', 'Water heater'], ['toilet', 'Bồn cầu', 'Toilet'], ['basin', 'Lavabo', 'Basin'],
          ['bathtub', 'Bồn tắm', 'Bathtub'], ['shower', 'Vòi sen', 'Shower'], ['faucet', 'Vòi rửa', 'Faucet'],
          ['vacuum', 'Máy hút bụi', 'Vacuum cleaner'], OTHER)),
        filterSelect('brand', t('Hãng', 'Brand'), names('Ariston', 'Ferroli', 'Panasonic', 'TOTO', 'Inax', 'Viglacera', 'Caesar',
          'Kangaroo', 'Electrolux', 'other')),
      ]),
      sub('gia-dung-khac', t('Nội thất, gia dụng khác', 'Other household'), [brandText()]),
    ],
  }),

  category('office', t('Văn phòng, công nông nghiệp', 'Office & industry'), {
    description: t('Đồ dùng văn phòng, máy móc, giống nuôi trồng...', 'Office supplies, machinery, farming...'),
    icon: 'office',
    subcategories: [
      sub('do-dung-van-phong', t('Đồ dùng văn phòng', 'Office supplies'), [
        filterSelect('item_type', t('Loại sản phẩm', 'Product type'), labelled(['printer', 'Máy in, máy scan', 'Printer, scanner'],
          ['copier', 'Máy photocopy', 'Copier'], ['projector', 'Máy chiếu', 'Projector'], ['safe', 'Két sắt', 'Safe'],
          ['stationery', 'Văn phòng phẩm', 'Stationery'], OTHER)),
        brandText(),
      ]),
      sub('do-chuyen-dung', t('Đồ chuyên dụng, giống nuôi trồng', 'Equipment & farming'), [
        filterSelect('item_type', t('Loại sản phẩm', 'Product type'), labelled(['machinery', 'Máy móc công nghiệp', 'Industrial machinery'],
          ['tools', 'Dụng cụ cơ khí', 'Tools'], ['farm_machine', 'Máy nông nghiệp', 'Farm machinery'],
          ['seedling', 'Cây giống, con giống', 'Seedlings, livestock'], ['supplies', 'Vật tư nông nghiệp', 'Farm supplies'], OTHER)),
        brandText(),
      ]),
    ],
  }),

  category('hobbies', t('Sở thích', 'Hobbies'), {
    description: t('Sách, thể thao, nhạc cụ, game, đồ sưu tầm...', 'Books, sports, instruments, games, collectibles...'),
    icon: 'sport', imageUrl: 'assets/images/categories/sports.png',
    subcategories: [
      sub('nhac-cu', t('Nhạc cụ', 'Instruments'), [
        filterSelect('instrument_type', t('Loại nhạc cụ', 'Instrument'), labelled(['guitar', 'Guitar'], ['piano', 'Piano, organ'],
          ['drum', 'Trống', 'Drums'], ['ukulele', 'Ukulele'], ['violin', 'Violin'], ['flute', 'Sáo', 'Flute'],
          ['traditional', 'Nhạc cụ dân tộc', 'Traditional'], OTHER), { required: true }),
        brandText(),
      ]),
      sub('sach', t('Sách', 'Books'), [
        filterSelect('genre', t('Thể loại', 'Genre'), labelled(['textbook', 'Giáo trình, sách giáo khoa', 'Textbooks'],
          ['novel', 'Tiểu thuyết, truyện', 'Fiction'], ['skills', 'Kỹ năng, kinh tế', 'Self-help, business'], ['kids', 'Thiếu nhi', 'Children'],
          ['language', 'Ngoại ngữ', 'Languages'], ['comic', 'Truyện tranh', 'Comics'], OTHER), { required: true }),
        text('author', t('Tác giả', 'Author')),
        number('quantity', t('Số lượng', 'Quantity'), 1, 1000, { unit: t('cuốn', 'books') }),
      ]),
      sub('the-thao-da-ngoai', t('Đồ thể thao, dã ngoại', 'Sports & outdoors'), [
        filterSelect('sport_type', t('Môn thể thao', 'Sport'), labelled(['gym', 'Gym, fitness'], ['football', 'Bóng đá', 'Football'],
          ['badminton', 'Cầu lông', 'Badminton'], ['racket', 'Tennis, pickleball'], ['swimming', 'Bơi lội', 'Swimming'], ['golf', 'Golf'],
          ['camping', 'Cắm trại, dã ngoại', 'Camping'], ['fishing', 'Câu cá', 'Fishing'], ['martial', 'Võ thuật', 'Martial arts'], OTHER)),
        brandText(), text('size', t('Kích cỡ', 'Size')),
      ]),
      sub('do-suu-tam', t('Đồ sưu tầm, đồ cổ', 'Collectibles'), [
        filterSelect('collectible_type', t('Loại', 'Type'), labelled(['gem', 'Đá quý, thạch', 'Gems'], ['art', 'Tranh ảnh', 'Art'],
          ['lighter', 'Bật lửa', 'Lighters'], ['statue', 'Tượng trang trí', 'Statues'], ['ceramic', 'Gốm sứ', 'Ceramics'],
          ['coin', 'Tiền xu, tem', 'Coins, stamps'], OTHER)),
      ]),
      sub('thiet-bi-game', t('Thiết bị chơi game', 'Gaming'), [
        filterSelect('game_item', t('Loại', 'Type'), labelled(['console', 'Máy chơi game', 'Console'],
          ['controller', 'Tay cầm, phụ kiện', 'Controllers & accessories'], ['game', 'Đĩa, thẻ game', 'Games'], OTHER), { required: true }),
        filterSelect('platform', t('Hệ máy', 'Platform'), labelled(['playstation', 'PlayStation'], ['xbox', 'Xbox'],
          ['nintendo', 'Nintendo'], ['pc', 'PC'], OTHER)),
        model(t('VD: PS5 Slim', 'e.g. PS5 Slim')),
      ]),
      sub('so-thich-khac', t('Sở thích khác', 'Other hobbies'), [brandText()]),
    ],
  }),

  category('fashion', t('Thời trang', 'Fashion'), {
    description: t('Quần áo, giày dép, túi xách, đồng hồ...', 'Clothes, shoes, bags, watches...'),
    icon: 'fashion', imageUrl: 'assets/images/categories/fashion.png',
    attributes: [
      filterSelect('gender', t('Dành cho', 'For'), labelled(['women', 'Nữ', 'Women'], ['men', 'Nam', 'Men'], ['unisex', 'Unisex'],
        ['kids', 'Trẻ em', 'Kids'])),
      text('brand', t('Thương hiệu', 'Brand')),
    ],
    subcategories: [
      sub('quan-ao', t('Quần áo', 'Clothes'), [text('size', t('Kích cỡ', 'Size'), { hint: t('VD: M, 30, 38', 'e.g. M, 30, 38') }), material()]),
      sub('dong-ho', t('Đồng hồ', 'Watches'), []),
      sub('giay-dep', t('Giày dép', 'Shoes'), [text('size', t('Kích cỡ', 'Size'), { hint: t('VD: 39, 42', 'e.g. 39, 42') })]),
      sub('tui-xach', t('Túi xách', 'Bags'), [material()]),
      sub('nuoc-hoa', t('Nước hoa', 'Perfume'), []),
      sub('phu-kien-thoi-trang', t('Phụ kiện thời trang khác', 'Fashion accessories'), []),
    ],
  }),

  category('mom-baby', t('Mẹ và bé', 'Mom & baby'), {
    description: t('Xe đẩy, đồ chơi, quần áo trẻ em, đồ cho mẹ...', 'Strollers, toys, kids clothes...'),
    icon: 'baby',
    subcategories: [
      sub('me-va-be', t('Mẹ và bé', 'Mom & baby'), [
        filterSelect('item_type', t('Loại sản phẩm', 'Product type'), labelled(['stroller', 'Xe đẩy, nôi, cũi', 'Strollers, cribs'],
          ['clothes', 'Quần áo trẻ em', 'Kids clothes'], ['toy', 'Đồ chơi', 'Toys'], ['feeding', 'Bình sữa, đồ ăn dặm', 'Feeding'],
          ['seat', 'Ghế ăn, ghế ô tô', 'High chairs, car seats'], ['maternity', 'Đồ cho mẹ', 'Maternity'], OTHER)),
        filterSelect('age_range', t('Độ tuổi của bé', 'Child age'), labelled(['0_6m', '0 - 6 tháng', '0 - 6 months'],
          ['6_12m', '6 - 12 tháng', '6 - 12 months'], ['1_3y', '1 - 3 tuổi', '1 - 3 years'], ['3_6y', '3 - 6 tuổi', '3 - 6 years'],
          ['gt6y', 'Trên 6 tuổi', 'Over 6 years'])),
        text('brand', t('Thương hiệu', 'Brand')),
      ]),
    ],
  }),
];

/** Danh mục cũ (trước mô hình 2 cấp): tắt khi chuyển dữ liệu, không xoá vì đơn hàng cũ còn tham chiếu */
export const RETIRED_CATEGORY_IDS = ['phones', 'books', 'sports', 'other'];
