/// Dữ liệu mẫu cho trang chủ, đúng cấu trúc JSON của API
/// (`GET /home/banners`, `GET /listings/recommended`, `GET /listings`).
class HomeMockData {
  HomeMockData._();

  static const String areaName = 'TP. Hồ Chí Minh';

  static const String _camera = 'assets/images/marketplace/listing-camera.png';
  static const String _lamp = 'assets/images/marketplace/listing-lamp.png';
  static const String _chair = 'assets/images/marketplace/listing-chair.png';

  static const Map<String, dynamic> currentUser = {
    'id': 'user_me',
    'email': 'minhanh@example.com',
    'fullName': 'Nguyễn Minh Anh',
    'username': 'minhanh',
    'role': 'USER',
    'status': 'ACTIVE',
  };

  /// Banner trang chủ (ảnh 1200 × 600). Banner sự kiện của shop uy tín đã được
  /// admin duyệt đứng đầu, bấm vào mở trang Shop uy tín rồi vào thẳng shop.
  /// Banner của app chưa có ảnh nên để imageUrl null, app hiện khung trống.
  static final List<Map<String, dynamic>> banners = [
    {
      'id': 'banner-shop-kodo',
      'imageUrl': 'assets/images/banners/banner-kodo-week.jpg',
      'route': '/trusted-shops?shop=shop_kodo',
    },
    {
      'id': 'banner-shop-lumi',
      'imageUrl': 'assets/images/banners/banner-super-sale.jpg',
      'route': '/trusted-shops?shop=shop_lumi',
    },
    {
      'id': 'banner-shop-mirai',
      'imageUrl': 'assets/images/banners/banner-black-friday.jpg',
      'route': '/trusted-shops?shop=shop_mirai',
    },
    {'id': 'banner-1', 'imageUrl': null, 'route': '/create-listing/category'},
    {'id': 'banner-2', 'imageUrl': null, 'route': null},
    {'id': 'banner-3', 'imageUrl': null, 'route': '/ai-assistant'},
  ];

  /// Tạo danh sách tin với thời gian đăng tính từ [now]
  static List<Map<String, dynamic>> listings(DateTime now) {
    Map<String, dynamic> item({
      required String id,
      required String title,
      required int? price,
      required String image,
      required String category,
      required String area,
      required double distance,
      required Duration age,
      String condition = 'USED_GOOD',
      bool exchange = false,
      bool featured = false,
    }) => {
      'id': id,
      'ownerId': 'user_$id',
      'title': title,
      'description': '',
      'price': price,
      'condition': condition,
      'status': 'AVAILABLE',
      'allowSale': price != null,
      'allowExchange': exchange,
      'images': [image],
      'categoryId': category,
      'createdAt': now.subtract(age).toIso8601String(),
      'areaLabel': area,
      'distanceKm': distance,
      'isFeatured': featured,
    };

    final base = [
      item(
        id: 'l1',
        title: 'Máy ảnh Canon AE-1 kèm lens 50mm f1.8',
        price: 3200000,
        image: _camera,
        category: 'electronics',
        area: 'Quận 3',
        distance: 2.1,
        age: const Duration(minutes: 12),
        condition: 'LIKE_NEW',
        featured: true,
      ),
      item(
        id: 'l2',
        title: 'Đèn bàn đồng vintage, chao thuỷ tinh',
        price: 450000,
        image: _lamp,
        category: 'home',
        area: 'Bình Thạnh',
        distance: 3.4,
        age: const Duration(minutes: 40),
        exchange: true,
      ),
      item(
        id: 'l3',
        title: 'Ghế gỗ sồi Bắc Âu, còn rất chắc',
        price: 690000,
        image: _chair,
        category: 'home',
        area: 'Thủ Đức',
        distance: 9.8,
        age: const Duration(hours: 2),
        featured: true,
      ),
      item(
        id: 'l4',
        title: 'Máy ảnh film Nikon FM2, đổi lấy máy số',
        price: null,
        image: _camera,
        category: 'electronics',
        area: 'Phú Nhuận',
        distance: 4.2,
        age: const Duration(hours: 5),
        exchange: true,
      ),
      item(
        id: 'l5',
        title: 'Đèn đọc sách để bàn, ánh sáng vàng ấm',
        price: 220000,
        image: _lamp,
        category: 'home',
        area: 'Quận 1',
        distance: 1.3,
        age: const Duration(hours: 9),
        condition: 'LIKE_NEW',
      ),
      item(
        id: 'l6',
        title: 'Bộ 2 ghế gỗ quán cafe, giao trong ngày',
        price: 1200000,
        image: _chair,
        category: 'home',
        area: 'Gò Vấp',
        distance: 7.5,
        age: const Duration(days: 1, hours: 3),
        exchange: true,
      ),
      item(
        id: 'l7',
        title: 'Fujifilm X100F bạc, đủ hộp sạc',
        price: 15500000,
        image: _camera,
        category: 'electronics',
        area: 'Quận 7',
        distance: 6.0,
        age: const Duration(days: 2),
        condition: 'LIKE_NEW',
        featured: true,
      ),
      item(
        id: 'l8',
        title: 'Đèn ngủ gỗ handmade, mới 95%',
        price: 180000,
        image: _lamp,
        category: 'home',
        area: 'Tân Bình',
        distance: 5.1,
        age: const Duration(days: 3),
        condition: 'LIKE_NEW',
      ),
    ];

    // Nhân bản thêm để thử phân trang (mỗi lượt 10 tin)
    return [
      ...base,
      for (var round = 1; round <= 3; round++)
        for (final json in base)
          {
            ...json,
            'id': '${json['id']}_$round',
            'isFeatured': false,
            'distanceKm': (json['distanceKm'] as double) + round * 1.5,
            'createdAt': DateTime.parse(
              json['createdAt'] as String,
            ).subtract(Duration(days: round * 3)).toIso8601String(),
          },
    ];
  }
}
