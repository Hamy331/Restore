import 'package:restore/modules/listings/data/listing_mock_data.dart';

/// Dữ liệu mẫu Shop uy tín, đúng cấu trúc JSON của API
/// (`GET /shops/trusted/overview`, `GET /shops/:id`, `GET /shops/:id/listings`).
///
/// Mỗi tin của shop có id dạng `<tin gốc>_<mã shop><số>` (VD `l7_kodo2`) để
/// trang chi tiết sản phẩm mẫu mượn mô tả, ảnh của tin gốc cùng loại.
class TrustedShopMockData {
  TrustedShopMockData._();

  static const String _camera = 'assets/images/marketplace/listing-camera.png';
  static const String _lamp = 'assets/images/marketplace/listing-lamp.png';
  static const String _chair = 'assets/images/marketplace/listing-chair.png';

  /// Ảnh mẫu từ Unsplash (cần mạng); tải lỗi thì app vẽ nền màu nhận diện
  static String _unsplash(String photoId) =>
      'https://images.unsplash.com/photo-$photoId'
      '?auto=format&fit=crop&w=1000&q=70';

  /// Shop người dùng mẫu đang theo dõi; bấm Theo dõi / Bỏ theo dõi sẽ sửa
  /// trực tiếp tập này
  static final Set<String> followingShopIds = {'shop_lumi'};

  static final List<Map<String, dynamic>> shops = [
    {
      'id': 'shop_kodo',
      'ownerId': 'user_kodo',
      'name': 'Kodo Camera Official',
      'tagline': 'Máy ảnh chính hãng, bảo hành 24 tháng',
      'description':
          'Gian hàng chính thức của Kodo Camera tại Việt Nam. Toàn bộ máy và '
          'ống kính nhập trực tiếp, có tem bảo hành hãng và hoá đơn VAT. Hỗ '
          'trợ đổi mới trong 7 ngày nếu lỗi do nhà sản xuất.',
      'coverUrl': _unsplash('1516035069371-29a1b244cc32'),
      'accentColor': '#2B63C6',
      'verificationType': 'OFFICIAL_BRAND',
      'verifiedAt': '2025-11-02T08:00:00Z',
      'certificateCode': 'RS-OB-2025-0012',
      'categoryIds': ['electronics'],
      'address': 'Quận 1, TP. Hồ Chí Minh',
      'ratingAverage': 4.9,
      'ratingCount': 1284,
      'followerCount': 18640,
      'createdAt': '2025-10-20T08:00:00Z',
    },
    {
      'id': 'shop_lumi',
      'ownerId': 'user_lumi',
      'name': 'Lumi Lighting',
      'tagline': 'Đèn trang trí thiết kế Việt, chính hãng',
      'description':
          'Thương hiệu đèn trang trí Lumi, sản xuất tại xưởng Bình Dương. '
          'Sản phẩm trưng bày và hàng mẫu được bán lại với giá tốt, bảo hành '
          'bóng và mạch 12 tháng.',
      'coverUrl': _unsplash('1513506003901-1e6a229e2d15'),
      'accentColor': '#B7791F',
      'verificationType': 'OFFICIAL_BRAND',
      'verifiedAt': '2026-01-15T08:00:00Z',
      'certificateCode': 'RS-OB-2026-0031',
      'categoryIds': ['home'],
      'address': 'Thủ Dầu Một, Bình Dương',
      'ratingAverage': 4.8,
      'ratingCount': 642,
      'followerCount': 9320,
      'createdAt': '2026-01-10T08:00:00Z',
    },
    {
      'id': 'shop_mirai',
      'ownerId': 'user_mirai',
      'name': 'Mirai Photo Store',
      'tagline': 'Nhà phân phối chính thức máy ảnh Mirai',
      'description':
          'Nhà phân phối được Mirai uỷ quyền tại Việt Nam. Bán máy mới, máy '
          'trưng bày và máy thu cũ đã qua kiểm định, có phiếu bảo hành.',
      'coverUrl': _unsplash('1526170375885-4d8ecf77b99f'),
      'accentColor': '#C23A62',
      'verificationType': 'OFFICIAL_BRAND',
      'verifiedAt': '2026-03-08T08:00:00Z',
      'certificateCode': 'RS-OB-2026-0047',
      'categoryIds': ['electronics'],
      'address': 'Quận Hoàn Kiếm, Hà Nội',
      'ratingAverage': 4.7,
      'ratingCount': 415,
      'followerCount': 5210,
      'createdAt': '2026-03-01T08:00:00Z',
    },
    {
      'id': 'shop_mocan',
      'ownerId': 'user_mocan',
      'name': 'Mộc An Furniture',
      'tagline': 'Nội thất gỗ tự nhiên, xưởng tại Thủ Đức',
      'description':
          'Xưởng nội thất gỗ sồi, gỗ thông tự nhiên. Đã được ReStore kiểm tra '
          'giấy phép kinh doanh và địa chỉ xưởng. Nhận làm theo kích thước, '
          'giao lắp trong TP. Hồ Chí Minh.',
      'coverUrl': _unsplash('1524758631624-e2822e304c36'),
      'accentColor': '#7A5230',
      'verificationType': 'CERTIFIED',
      'verifiedAt': '2026-04-21T08:00:00Z',
      'certificateCode': 'RS-CT-2026-0108',
      'categoryIds': ['home'],
      'address': 'Thủ Đức, TP. Hồ Chí Minh',
      'ratingAverage': 4.8,
      'ratingCount': 236,
      'followerCount': 2870,
      'createdAt': '2026-04-01T08:00:00Z',
    },
    {
      'id': 'shop_retro',
      'ownerId': 'user_retro',
      'name': 'Retro Lens Sài Gòn',
      'tagline': 'Máy film đã kiểm định, bảo hành 3 tháng',
      'description':
          'Chuyên máy ảnh film và ống kính cổ. Mỗi máy đều được test màn '
          'trập, đo sáng và chụp thử trước khi bán. ReStore đã xác minh cửa '
          'hàng và lịch sử giao dịch.',
      'coverUrl': _unsplash('1452780212940-6f5c0d14d848'),
      'accentColor': '#0E7C70',
      'verificationType': 'CERTIFIED',
      'verifiedAt': '2026-05-12T08:00:00Z',
      'certificateCode': 'RS-CT-2026-0126',
      'categoryIds': ['electronics'],
      'address': 'Quận 3, TP. Hồ Chí Minh',
      'ratingAverage': 4.9,
      'ratingCount': 318,
      'followerCount': 4105,
      'createdAt': '2025-12-12T08:00:00Z',
    },
    {
      'id': 'shop_gocnha',
      'ownerId': 'user_gocnha',
      'name': 'Góc Nhà Decor',
      'tagline': 'Đồ trang trí, đèn ngủ handmade',
      'description':
          'Cửa hàng đồ trang trí nhà cửa, phần lớn làm thủ công. Được ReStore '
          'cấp chứng nhận sau khi kiểm tra giấy tờ và 50 đơn giao thành công.',
      'coverUrl': _unsplash('1493663284031-b7e3aefcae8e'),
      'accentColor': '#6A4BC4',
      'verificationType': 'CERTIFIED',
      'verifiedAt': '2026-07-30T08:00:00Z',
      'certificateCode': 'RS-CT-2026-0173',
      'categoryIds': ['home'],
      'address': 'Quận Tây Hồ, Hà Nội',
      'ratingAverage': 4.7,
      'ratingCount': 154,
      'followerCount': 1980,
      'createdAt': '2026-06-02T08:00:00Z',
    },
  ];

  /// Tin của từng shop: (tin gốc, tên, giá, tình trạng, nhận đổi)
  static const Map<String, List<(String, String, int, String, bool)>>
  _products = {
    'shop_kodo': [
      ('l7', 'Kodo Z30 body mới 100%, bảo hành hãng', 18990000, 'NEW', false),
      ('l1', 'Kodo Z30 kèm lens kit 18-45mm', 21490000, 'NEW', false),
      ('l7', 'Kodo Z50 II trưng bày, đủ hộp', 23900000, 'LIKE_NEW', false),
      ('l1', 'Ống kính Kodo 50mm f1.8 chính hãng', 4290000, 'NEW', false),
      ('l7', 'Kodo Zf bản bạc, tặng thẻ 64GB', 39500000, 'NEW', false),
      ('l1', 'Ống kính Kodo 24-70mm f4 trưng bày', 15900000, 'LIKE_NEW', false),
      ('l7', 'Kodo Z30 vlog kit kèm mic và tay cầm', 20990000, 'NEW', false),
      ('l1', 'Đèn flash Kodo SB-500 chính hãng', 5490000, 'NEW', false),
    ],
    'shop_lumi': [
      ('l2', 'Đèn bàn Lumi Aura chao thuỷ tinh', 890000, 'NEW', false),
      ('l5', 'Đèn đọc sách Lumi Read, 3 mức sáng', 650000, 'NEW', false),
      ('l8', 'Đèn ngủ Lumi Mộc gỗ tần bì', 420000, 'NEW', false),
      ('l2', 'Đèn cây Lumi Arc hàng trưng bày', 2390000, 'LIKE_NEW', false),
      ('l5', 'Đèn kẹp bàn Lumi Clip, cổng USB-C', 380000, 'NEW', false),
      ('l8', 'Bộ 2 đèn ngủ Lumi Cloud', 760000, 'NEW', false),
    ],
    'shop_mirai': [
      ('l7', 'Mirai X-T5 bạc, nhập chính hãng', 36900000, 'NEW', false),
      ('l1', 'Mirai X100VI đen, bảo hành 24 tháng', 42900000, 'NEW', false),
      ('l7', 'Mirai X-S20 máy trưng bày', 24500000, 'LIKE_NEW', false),
      ('l1', 'Ống kính Mirai 35mm f2 WR', 7900000, 'NEW', false),
      ('l7', 'Mirai Instax Wide, tặng 20 tấm film', 2490000, 'NEW', false),
    ],
    'shop_mocan': [
      ('l3', 'Ghế ăn gỗ sồi Mộc An, bộ 2 chiếc', 2600000, 'NEW', false),
      ('l6', 'Ghế quầy bar gỗ thông, cao 75 cm', 1150000, 'NEW', true),
      ('l3', 'Ghế thư giãn khung sồi, nệm vải bố', 3900000, 'NEW', false),
      ('l6', 'Ghế đẩu gỗ tràm, hàng mẫu trưng bày', 450000, 'LIKE_NEW', true),
      ('l3', 'Ghế làm việc gỗ óc chó tay vịn', 4800000, 'NEW', false),
      ('l6', 'Bộ 4 ghế cafe gỗ thông sơn mờ', 2200000, 'USED_GOOD', true),
      ('l3', 'Ghế trẻ em gỗ sồi có tựa lưng', 690000, 'NEW', false),
    ],
    'shop_retro': [
      ('l4', 'Máy film rangefinder đã kiểm định', 4200000, 'USED_GOOD', true),
      ('l1', 'Máy film SLR kèm lens 50mm f1.7', 3100000, 'USED_GOOD', false),
      ('l4', 'Máy film compact point & shoot', 1850000, 'USED_GOOD', true),
      ('l1', 'Ống kính manual 135mm f2.8 ngàm M42', 950000, 'USED_FAIR', false),
      ('l4', 'Máy film medium format 6x6', 8900000, 'USED_GOOD', false),
      ('l1', 'Máy film SLR cơ, đo sáng chuẩn', 2750000, 'LIKE_NEW', true),
    ],
    'shop_gocnha': [
      ('l8', 'Đèn ngủ mây tre đan thủ công', 320000, 'NEW', false),
      ('l2', 'Đèn bàn gốm men lam, chao vải lanh', 560000, 'NEW', true),
      ('l5', 'Đèn treo tường gỗ cong, ánh vàng', 480000, 'NEW', false),
      ('l3', 'Ghế đôn mây đan tay', 690000, 'NEW', true),
      ('l8', 'Đèn lồng giấy dó, bộ 3 chiếc', 270000, 'NEW', false),
    ],
  };

  /// Giá gốc của các tin đang giảm giá, theo id tin
  static const Map<String, int> _originalPrices = {
    'l7_kodo1': 21990000,
    'l1_kodo4': 4990000,
    'l1_kodo6': 19900000,
    'l2_lumi4': 3190000,
    'l5_lumi2': 790000,
    'l7_mirai3': 28900000,
    'l7_mirai5': 2990000,
    'l3_mocan1': 3250000,
    'l6_mocan4': 690000,
    'l2_gocnha2': 690000,
  };

  /// Tin là sản phẩm vừa ra mắt của thương hiệu, kèm số ngày từ lúc ra mắt
  static const Map<String, int> _newReleaseDays = {
    'l7_kodo5': 2,
    'l1_mirai2': 4,
    'l2_lumi1': 6,
    'l7_mirai1': 9,
    'l7_kodo7': 12,
  };

  static String _coverOf(String baseId) => switch (baseId) {
    'l2' || 'l5' || 'l8' => _lamp,
    'l3' || 'l6' => _chair,
    _ => _camera,
  };

  static String _categoryOf(String baseId) => switch (baseId) {
    'l2' || 'l5' || 'l8' || 'l3' || 'l6' => 'home',
    _ => 'electronics',
  };

  /// Mã ngắn của shop trong id tin (VD `shop_kodo` → `kodo`)
  static String _shopKey(String shopId) => shopId.split('_').last;

  /// Tin của mọi shop với thời gian đăng tính từ [now], mỗi tin có `shopId`
  static List<Map<String, dynamic>> listings(DateTime now) {
    final result = <Map<String, dynamic>>[];
    for (final shop in shops) {
      final shopId = shop['id'] as String;
      final products = _products[shopId] ?? const [];
      for (var index = 0; index < products.length; index++) {
        final (baseId, title, price, condition, exchange) = products[index];
        final id = '${baseId}_${_shopKey(shopId)}${index + 1}';
        final releaseDays = _newReleaseDays[id];
        result.add({
          'id': id,
          'shopId': shopId,
          'ownerId': shop['ownerId'],
          'title': title,
          'description': '',
          'price': price,
          'originalPrice': _originalPrices[id],
          'isNegotiable': shop['verificationType'] != 'OFFICIAL_BRAND',
          'condition': condition,
          'status': 'AVAILABLE',
          'allowSale': true,
          'allowExchange': exchange,
          'images': [_coverOf(baseId)],
          'categoryId': _categoryOf(baseId),
          'createdAt': now
              .subtract(
                releaseDays == null
                    ? Duration(hours: 3 + index * 7 + shopId.length)
                    : Duration(days: releaseDays),
              )
              .toIso8601String(),
          'areaLabel': shop['address'],
          // Tin đầu tiên của shop chính hãng được đẩy nổi bật
          'isFeatured':
              index == 0 && shop['verificationType'] == 'OFFICIAL_BRAND',
        });
      }
    }
    return result;
  }

  /// Tin là sản phẩm vừa ra mắt (khu "Siêu phẩm mới ra mắt")
  static bool isNewRelease(String listingId) =>
      _newReleaseDays.containsKey(listingId);

  /// Banner sự kiện đã duyệt (JSON của ShopBanner, chưa kèm `shop`), thời
  /// gian chạy tính từ [now]. Ảnh do shop tự thiết kế, 1200 × 600.
  static List<Map<String, dynamic>> banners(DateTime now) {
    Map<String, dynamic> banner(
      String id,
      String shopId,
      String image,
      String title, {
      required int endsInDays,
    }) => {
      'id': id,
      'shopId': shopId,
      'title': title,
      'imageUrl': 'assets/images/banners/$image',
      'status': 'APPROVED',
      'startsAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      'endsAt': now.add(Duration(days: endsInDays)).toIso8601String(),
    };

    return [
      banner(
        'banner_kodo_week',
        'shop_kodo',
        'banner-kodo-week.jpg',
        'Tuần lễ Kodo Z30',
        endsInDays: 5,
      ),
      banner(
        'banner_lumi_super_sale',
        'shop_lumi',
        'banner-super-sale.jpg',
        'Lumi Super Sale',
        endsInDays: 12,
      ),
      banner(
        'banner_mirai_black_friday',
        'shop_mirai',
        'banner-black-friday.jpg',
        'Mirai Black Friday',
        endsInDays: 9,
      ),
      banner(
        'banner_mocan_sale',
        'shop_mocan',
        'banner-mocan-sale.jpg',
        'Mộc An xả kho ghế mẫu',
        endsInDays: 2,
      ),
    ];
  }

  /// Tin [id] của một shop, null khi không có (dùng cho trang chi tiết mẫu)
  static Map<String, dynamic>? listingById(String id, {DateTime? now}) =>
      listings(
        now ?? DateTime.now(),
      ).where((listing) => listing['id'] == id).firstOrNull;

  /// Shop kèm số tin đang bán và trạng thái theo dõi hiện tại
  static Map<String, dynamic> shopJson(Map<String, dynamic> shop) {
    final id = shop['id'] as String;
    return {
      ...shop,
      'listingCount': _products[id]?.length ?? 0,
      'isFollowing': followingShopIds.contains(id),
    };
  }

  /// Danh mục (JSON của `GET /categories`) có ít nhất một shop uy tín
  static List<Map<String, dynamic>> categories() {
    final ids = {
      for (final shop in shops) ...(shop['categoryIds'] as List).cast<String>(),
    };
    return [
      for (final category in ListingMockData.categories)
        if (ids.contains(category['id'])) category,
    ];
  }
}
