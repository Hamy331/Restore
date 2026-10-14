import 'package:restore/core/constants/app_images.dart';

/// Dữ liệu mẫu dạng JSON, đúng cấu trúc response `GET /categories` ở backend.
/// Mỗi danh mục tự khai báo bộ thuộc tính (attributes) nên thêm loại hàng mới
/// chỉ cần thêm dữ liệu, không phải sửa giao diện.
/// TODO: Khi backend có API thì dùng ApiCategoryRepository thay cho dữ liệu này.
class ListingMockData {
  ListingMockData._();

  static final List<Map<String, dynamic>> categories = [
    {
      'id': 'phone',
      'name': _t('Điện thoại', 'Phones'),
      'description': _t(
        'iPhone, Samsung, Xiaomi, OPPO...',
        'iPhone, Samsung, Xiaomi, OPPO...',
      ),
      'icon': 'phone',
      'imageUrl': AppImages.categoryImages.phone,
      'attributes': [
        _select(
          'brand',
          _t('Hãng', 'Brand'),
          required: true,
          options: [
            'Apple', 'Samsung', 'Xiaomi', 'OPPO', 'vivo', 'realme', 'Nokia',
            'Google', 'Sony', 'ASUS', //
            _o('other', _t('Hãng khác', 'Other')),
          ],
        ),
        _text(
          'model',
          _t('Dòng máy', 'Model'),
          required: true,
          hint: _t('VD: iPhone 14 Pro Max', 'e.g. iPhone 14 Pro Max'),
        ),
        _select(
          'storage',
          _t('Dung lượng', 'Storage'),
          options: ['32 GB', '64 GB', '128 GB', '256 GB', '512 GB', '1 TB'],
        ),
        _select('color', _t('Màu sắc', 'Color'), options: _colors),
        _select(
          'origin',
          _t('Xuất xứ', 'Origin'),
          options: [
            _o('vn_a', _t('Chính hãng VN/A', 'Official VN/A')),
            _o('international', _t('Quốc tế', 'International')),
            _o('lock', _t('Bản lock', 'Carrier locked')),
          ],
        ),
        _number(
          'battery_health',
          _t('Tình trạng pin', 'Battery health'),
          unit: '%',
          min: 1,
          max: 100,
        ),
        _select('warranty', _t('Bảo hành', 'Warranty'), options: _warranty),
      ],
    },
    {
      'id': 'electronics',
      'name': _t('Đồ điện tử', 'Electronics'),
      'description': _t(
        'Laptop, máy ảnh, tai nghe, máy tính bảng...',
        'Laptops, cameras, headphones, tablets...',
      ),
      'icon': 'electronics',
      'imageUrl': AppImages.categoryImages.electronics,
      'attributes': [
        _select(
          'device_type',
          _t('Loại thiết bị', 'Device type'),
          required: true,
          options: [
            _o('laptop', _t('Laptop', 'Laptop')),
            _o('tablet', _t('Máy tính bảng', 'Tablet')),
            _o('camera', _t('Máy ảnh, máy quay', 'Camera')),
            _o('audio', _t('Tai nghe, loa', 'Headphones, speakers')),
            _o('smartwatch', _t('Đồng hồ thông minh', 'Smartwatch')),
            _o('tv', _t('Tivi, màn hình', 'TV, monitor')),
            _o('gaming', _t('Máy chơi game', 'Game console')),
            _o('other', _t('Khác', 'Other')),
          ],
        ),
        _text(
          'brand',
          _t('Hãng', 'Brand'),
          required: true,
          hint: _t('VD: Sony, Canon, Dell', 'e.g. Sony, Canon, Dell'),
        ),
        _text(
          'model',
          _t('Model', 'Model'),
          hint: _t('VD: Alpha A7 III', 'e.g. Alpha A7 III'),
        ),
        _select('warranty', _t('Bảo hành', 'Warranty'), options: _warranty),
        _bool(
          'has_accessories',
          _t('Còn đủ phụ kiện, hộp', 'Includes box & accessories'),
        ),
      ],
    },
    {
      'id': 'vehicles',
      'name': _t('Xe cộ', 'Vehicles'),
      'description': _t(
        'Xe máy, xe đạp, ô tô, phụ tùng...',
        'Motorbikes, bicycles, cars, parts...',
      ),
      'icon': 'vehicle',
      'imageUrl': AppImages.categoryImages.vehicles,
      'attributes': [
        _select(
          'vehicle_type',
          _t('Loại xe', 'Vehicle type'),
          required: true,
          options: [
            _o('motorbike', _t('Xe máy', 'Motorbike')),
            _o('ebike', _t('Xe điện', 'Electric bike')),
            _o('bicycle', _t('Xe đạp', 'Bicycle')),
            _o('car', _t('Ô tô', 'Car')),
            _o('parts', _t('Phụ tùng', 'Parts')),
          ],
        ),
        _text(
          'brand',
          _t('Hãng', 'Brand'),
          required: true,
          hint: _t('VD: Honda, Yamaha, VinFast', 'e.g. Honda, Yamaha'),
        ),
        _text(
          'model',
          _t('Dòng xe', 'Model'),
          hint: _t('VD: Vision 2022', 'e.g. Vision 2022'),
        ),
        _number('year', _t('Năm sản xuất', 'Year'), min: 1980, max: 2030),
        _number(
          'mileage',
          _t('Số km đã đi', 'Mileage'),
          unit: 'km',
          min: 0,
          max: 2000000,
        ),
        _number(
          'engine_cc',
          _t('Dung tích xi lanh', 'Engine capacity'),
          unit: 'cc',
          min: 0,
          max: 10000,
        ),
        _bool(
          'has_papers',
          _t('Còn giấy tờ chính chủ', 'Has registration papers'),
        ),
      ],
    },
    {
      'id': 'fashion',
      'name': _t('Thời trang', 'Fashion'),
      'description': _t(
        'Quần áo, giày dép, túi xách...',
        'Clothes, shoes, bags...',
      ),
      'icon': 'fashion',
      'imageUrl': AppImages.categoryImages.fashion,
      'attributes': [
        _select(
          'product_type',
          _t('Loại sản phẩm', 'Product type'),
          required: true,
          options: [
            _o('clothes', _t('Quần áo', 'Clothes')),
            _o('shoes', _t('Giày dép', 'Shoes')),
            _o('bags', _t('Túi xách', 'Bags')),
            _o('accessories', _t('Phụ kiện', 'Accessories')),
            _o('watch', _t('Đồng hồ', 'Watches')),
          ],
        ),
        _select(
          'gender',
          _t('Dành cho', 'For'),
          options: [
            _o('men', _t('Nam', 'Men')),
            _o('women', _t('Nữ', 'Women')),
            _o('unisex', _t('Unisex', 'Unisex')),
            _o('kids', _t('Trẻ em', 'Kids')),
          ],
        ),
        _text(
          'size',
          _t('Kích cỡ', 'Size'),
          hint: _t('VD: M, 42, 28', 'e.g. M, 42, 28'),
        ),
        _text(
          'brand',
          _t('Thương hiệu', 'Brand'),
          hint: _t('VD: Uniqlo, Nike', 'e.g. Uniqlo, Nike'),
        ),
        _text(
          'material',
          _t('Chất liệu', 'Material'),
          hint: _t('VD: Cotton, da thật', 'e.g. Cotton, leather'),
        ),
      ],
    },
    {
      'id': 'appliances',
      'name': _t('Đồ gia dụng', 'Appliances'),
      'description': _t(
        'Tủ lạnh, máy giặt, điều hoà...',
        'Fridges, washing machines, air conditioners...',
      ),
      'icon': 'appliance',
      'imageUrl': AppImages.categoryImages.appliances,
      'attributes': [
        _select(
          'appliance_type',
          _t('Loại sản phẩm', 'Product type'),
          required: true,
          options: [
            _o('fridge', _t('Tủ lạnh', 'Fridge')),
            _o('washer', _t('Máy giặt', 'Washing machine')),
            _o('air_conditioner', _t('Điều hoà', 'Air conditioner')),
            _o('water_heater', _t('Bình nóng lạnh', 'Water heater')),
            _o('kitchen', _t('Đồ dùng nhà bếp', 'Kitchen appliance')),
            _o('other', _t('Khác', 'Other')),
          ],
        ),
        _text(
          'brand',
          _t('Hãng', 'Brand'),
          hint: _t('VD: Panasonic, LG', 'e.g. Panasonic, LG'),
        ),
        _text(
          'capacity',
          _t('Công suất / dung tích', 'Capacity'),
          hint: _t('VD: 9 kg, 1.5 HP, 300 L', 'e.g. 9 kg, 1.5 HP, 300 L'),
        ),
        _number(
          'power',
          _t('Công suất điện', 'Power'),
          unit: 'W',
          min: 0,
          max: 20000,
        ),
        _select('warranty', _t('Bảo hành', 'Warranty'), options: _warranty),
      ],
    },
    {
      'id': 'pets',
      'name': _t('Thú cưng', 'Pets'),
      'description': _t(
        'Chó, mèo, chim, phụ kiện thú cưng...',
        'Dogs, cats, birds, pet accessories...',
      ),
      'icon': 'pet',
      'imageUrl': AppImages.categoryImages.pets,
      'attributes': [
        _select(
          'pet_type',
          _t('Loại', 'Type'),
          required: true,
          options: [
            _o('dog', _t('Chó', 'Dog')),
            _o('cat', _t('Mèo', 'Cat')),
            _o('bird', _t('Chim', 'Bird')),
            _o('fish', _t('Cá cảnh', 'Fish')),
            _o('accessories', _t('Phụ kiện, thức ăn', 'Accessories, food')),
          ],
        ),
        _text(
          'breed',
          _t('Giống', 'Breed'),
          hint: _t('VD: Poodle, Mèo Anh lông ngắn', 'e.g. Poodle'),
        ),
        _number(
          'age_months',
          _t('Tuổi', 'Age'),
          unit: _t('tháng', 'months'),
          min: 0,
          max: 360,
        ),
        _select(
          'pet_gender',
          _t('Giới tính', 'Gender'),
          options: [
            _o('male', _t('Đực', 'Male')),
            _o('female', _t('Cái', 'Female')),
          ],
        ),
        _bool('vaccinated', _t('Đã tiêm phòng', 'Vaccinated')),
      ],
    },
    {
      'id': 'home',
      'name': _t('Nội thất, trang trí', 'Furniture & decor'),
      'description': _t(
        'Bàn ghế, đèn, đồ bếp, đồ trang trí...',
        'Furniture, lamps, kitchenware, decor...',
      ),
      'icon': 'home',
      'imageUrl': AppImages.categoryImages.home,
      'attributes': [
        _select(
          'home_type',
          _t('Loại sản phẩm', 'Product type'),
          required: true,
          options: [
            _o('furniture', _t('Bàn ghế, tủ kệ', 'Furniture')),
            _o('lighting', _t('Đèn', 'Lighting')),
            _o('kitchenware', _t('Đồ bếp', 'Kitchenware')),
            _o('decor', _t('Đồ trang trí', 'Decor')),
            _o('bedding', _t('Chăn ga gối', 'Bedding')),
          ],
        ),
        _text(
          'material',
          _t('Chất liệu', 'Material'),
          hint: _t('VD: Gỗ sồi, mây tre', 'e.g. Oak, rattan'),
        ),
        _text(
          'dimensions',
          _t('Kích thước', 'Dimensions'),
          hint: _t('VD: 120 x 60 x 75 cm', 'e.g. 120 x 60 x 75 cm'),
        ),
      ],
    },
    {
      'id': 'books',
      'name': _t('Sách, văn phòng phẩm', 'Books & stationery'),
      'description': _t(
        'Sách giáo khoa, truyện, giáo trình...',
        'Textbooks, novels, course books...',
      ),
      'icon': 'book',
      'attributes': [
        _select(
          'genre',
          _t('Thể loại', 'Genre'),
          required: true,
          options: [
            _o('textbook', _t('Giáo trình, sách giáo khoa', 'Textbook')),
            _o('novel', _t('Tiểu thuyết, truyện', 'Novel, comics')),
            _o('skills', _t('Kỹ năng, kinh tế', 'Self-help, business')),
            _o('kids', _t('Thiếu nhi', 'Children')),
            _o('stationery', _t('Văn phòng phẩm', 'Stationery')),
          ],
        ),
        _text('author', _t('Tác giả', 'Author')),
        _number(
          'quantity',
          _t('Số lượng', 'Quantity'),
          unit: _t('cuốn', 'books'),
          min: 1,
          max: 1000,
        ),
      ],
    },
    {
      'id': 'sports',
      'name': _t('Thể thao, dã ngoại', 'Sports & outdoors'),
      'description': _t(
        'Dụng cụ tập, xe đạp thể thao, đồ cắm trại...',
        'Gym gear, sport bikes, camping...',
      ),
      'icon': 'sport',
      'attributes': [
        _text(
          'sport_type',
          _t('Môn thể thao', 'Sport'),
          required: true,
          hint: _t('VD: Gym, cầu lông, cắm trại', 'e.g. Gym, camping'),
        ),
        _text('brand', _t('Thương hiệu', 'Brand')),
        _text('size', _t('Kích cỡ', 'Size')),
      ],
    },
    {
      'id': 'other',
      'name': _t('Khác', 'Other'),
      'description': _t(
        'Các món đồ chưa có danh mục phù hợp',
        'Items that fit no other category',
      ),
      'icon': 'other',
      'attributes': [_text('brand', _t('Thương hiệu', 'Brand'))],
    },
  ];

  // --- CÁC LỰA CHỌN DÙNG CHUNG ---

  static final List<Object> _colors = [
    _o('black', _t('Đen', 'Black')),
    _o('white', _t('Trắng', 'White')),
    _o('silver', _t('Bạc', 'Silver')),
    _o('gold', _t('Vàng', 'Gold')),
    _o('gray', _t('Xám', 'Gray')),
    _o('blue', _t('Xanh dương', 'Blue')),
    _o('green', _t('Xanh lá', 'Green')),
    _o('red', _t('Đỏ', 'Red')),
    _o('purple', _t('Tím', 'Purple')),
    _o('pink', _t('Hồng', 'Pink')),
  ];

  static final List<Object> _warranty = [
    _o('none', _t('Hết bảo hành', 'No warranty')),
    _o('manufacturer', _t('Còn bảo hành hãng', 'Manufacturer warranty')),
    _o('store', _t('Bảo hành cửa hàng', 'Store warranty')),
  ];

  // --- HÀM DỰNG JSON (giữ dữ liệu mẫu ngắn gọn, đúng cấu trúc API) ---

  static Map<String, String> _t(String vi, String en) => {'vi': vi, 'en': en};

  static Map<String, dynamic> _o(String value, Map<String, String> label) => {
    'value': value,
    'label': label,
  };

  /// Lựa chọn là chuỗi thì giá trị cũng là nhãn (tên riêng: Apple, 128 GB)
  static Map<String, dynamic> _select(
    String key,
    Map<String, String> label, {
    required List<Object> options,
    bool required = false,
  }) => {
    'key': key,
    'type': 'select',
    'label': label,
    'required': required,
    'options': [
      for (final option in options)
        option is String ? {'value': option} : option,
    ],
  };

  static Map<String, dynamic> _text(
    String key,
    Map<String, String> label, {
    Map<String, String>? hint,
    bool required = false,
  }) => {
    'key': key,
    'type': 'text',
    'label': label,
    'hint': hint,
    'required': required,
    'maxLength': 60,
  };

  static Map<String, dynamic> _number(
    String key,
    Map<String, String> label, {
    Object? unit,
    num? min,
    num? max,
    bool required = false,
  }) => {
    'key': key,
    'type': 'number',
    'label': label,
    'required': required,
    'unit': unit,
    'min': min,
    'max': max,
  };

  static Map<String, dynamic> _bool(String key, Map<String, String> label) => {
    'key': key,
    'type': 'boolean',
    'label': label,
  };
}
