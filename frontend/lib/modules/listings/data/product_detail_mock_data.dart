import 'package:restore/modules/home/data/home_mock_data.dart';

import 'listing_mock_data.dart';

/// Dữ liệu mẫu trang chi tiết, đúng cấu trúc JSON của `GET /listings/:id`.
/// Lấy tin gốc từ dữ liệu trang chủ rồi bổ sung mô tả, người bán, thuộc tính
/// để thẻ ở trang chủ và trang chi tiết luôn khớp nhau.
class ProductDetailMockData {
  ProductDetailMockData._();

  static const String _camera = 'assets/images/marketplace/listing-camera.png';
  static const String _lamp = 'assets/images/marketplace/listing-lamp.png';
  static const String _chair = 'assets/images/marketplace/listing-chair.png';

  static final Map<String, Map<String, dynamic>> _sellers = {
    'seller_khoa': {
      'id': 'seller_khoa',
      'email': 'khoa@example.com',
      'fullName': 'Trần Đăng Khoa',
      'username': 'khoafilm',
      'role': 'USER',
      'status': 'ACTIVE',
      'ratingAverage': 4.9,
      'ratingCount': 38,
      'createdAt': '2024-03-12T08:00:00Z',
    },
    'seller_linh': {
      'id': 'seller_linh',
      'email': 'linh@example.com',
      'fullName': 'Phạm Thuỳ Linh',
      'username': 'linhdecor',
      'role': 'USER',
      'status': 'ACTIVE',
      'ratingAverage': 4.6,
      'ratingCount': 12,
      'createdAt': '2025-01-05T08:00:00Z',
    },
    'seller_tuan': {
      'id': 'seller_tuan',
      'email': 'tuan@example.com',
      'fullName': 'Lê Minh Tuấn',
      'username': 'tuanwood',
      'role': 'USER',
      'status': 'UNVERIFIED',
      'createdAt': '2026-08-20T08:00:00Z',
    },
  };

  /// Phần bổ sung theo tin gốc (id không kèm hậu tố nhân bản `_1`, `_2`...)
  static final Map<String, Map<String, dynamic>> _extras = {
    'l1': {
      'seller': 'seller_khoa',
      'description':
          'Máy chụp film Canon AE-1 Program, đo sáng chuẩn, màn trập chạy '
          'đều mọi tốc độ. Kèm lens FD 50mm f1.8 trong, không mốc, không '
          'xước. Đã thay ron chống sáng, pin mới.\n\n'
          'Tặng kèm dây đeo da và 1 cuộn Kodak ColorPlus 200. Có thể test '
          'máy trực tiếp tại Quận 3.',
      'images': [_camera, _lamp, _chair],
      'attributes': {
        'device_type': 'camera',
        'brand': 'Canon',
        'model': 'AE-1 Program',
        'warranty': 'store',
        'has_accessories': true,
      },
      'areaLabel': 'Phường Võ Thị Sáu, TP. Hồ Chí Minh',
      'viewCount': 286,
    },
    'l2': {
      'seller': 'seller_linh',
      'description':
          'Đèn bàn thân đồng, chao thuỷ tinh mờ, ánh sáng vàng ấm rất hợp '
          'bàn đọc sách. Dây điện đã thay mới, công tắc nhạy.\n\n'
          'Nhận đổi lấy cây cảnh nhỏ hoặc khung tranh.',
      'images': [_lamp, _chair],
      'exchangeWish': 'Cây cảnh để bàn hoặc khung tranh treo tường',
      'attributes': {
        'home_type': 'lighting',
        'material': 'Đồng, thuỷ tinh',
        'dimensions': '22 x 22 x 45 cm',
      },
      'areaLabel': 'Phường Gia Định, TP. Hồ Chí Minh',
      'viewCount': 94,
    },
    'l3': {
      'seller': 'seller_tuan',
      'description':
          'Ghế gỗ sồi tự nhiên kiểu Bắc Âu, chân chắc, không lung lay. '
          'Mặt ghế có vài vết xước nhẹ do sử dụng, không ảnh hưởng.',
      'images': [_chair, _lamp],
      'attributes': {
        'home_type': 'furniture',
        'material': 'Gỗ sồi',
        'dimensions': '45 x 50 x 80 cm',
      },
      'areaLabel': 'Phường Thủ Đức, TP. Hồ Chí Minh',
      'viewCount': 51,
      'isNegotiable': false,
    },
    'l4': {
      'seller': 'seller_khoa',
      'description':
          'Nikon FM2 body đen, cơ hoàn toàn, chạy không cần pin. Kính ngắm '
          'sáng, đo sáng còn chuẩn. Chỉ muốn đổi lấy máy ảnh số để chụp '
          'hằng ngày, không bán.',
      'images': [_camera],
      'exchangeWish': 'Máy ảnh số compact hoặc mirrorless đời cũ',
      'attributes': {
        'device_type': 'camera',
        'brand': 'Nikon',
        'model': 'FM2',
        'warranty': 'none',
      },
      'areaLabel': 'Phường Đức Nhuận, TP. Hồ Chí Minh',
      'viewCount': 132,
    },
    'l6': {
      'seller': 'seller_tuan',
      'description':
          'Thanh lý 2 ghế gỗ quán cafe, khung chắc, sơn còn đẹp. Giao trong '
          'ngày khu vực Gò Vấp, nhận đổi lấy bàn nhỏ.',
      'images': [_chair],
      'exchangeWish': 'Bàn gỗ nhỏ hoặc kệ sách',
      'attributes': {'home_type': 'furniture', 'material': 'Gỗ thông'},
      'areaLabel': 'Phường Gò Vấp, TP. Hồ Chí Minh',
      'viewCount': 67,
    },
    'l7': {
      'seller': 'seller_khoa',
      'description':
          'Fujifilm X100F bạc, ngoại hình 98%, màn hình không trầy. Kèm '
          'hộp, sạc, 2 pin và dây đeo. Máy chụp khoảng 8.000 shot.',
      'images': [_camera],
      'attributes': {
        'device_type': 'camera',
        'brand': 'Fujifilm',
        'model': 'X100F',
        'warranty': 'none',
        'has_accessories': true,
      },
      'areaLabel': 'Phường Tân Thuận, TP. Hồ Chí Minh',
      'viewCount': 412,
    },
  };

  /// Tin chưa có phần bổ sung riêng dùng chung với tin cùng loại
  static const Map<String, String> _fallbackExtra = {'l5': 'l2', 'l8': 'l2'};

  /// Trả về JSON chi tiết của tin [id], null khi không có
  static Map<String, dynamic>? detail(String id, {DateTime? now}) {
    final rows = HomeMockData.listings(now ?? DateTime.now());
    final base = rows.where((row) => row['id'] == id).firstOrNull;
    if (base == null) return null;

    final baseId = id.split('_').first;
    final extra =
        _extras[baseId] ?? _extras[_fallbackExtra[baseId]] ?? _extras['l2']!;
    final cover = (base['images'] as List).first as String;
    final category = ListingMockData.categories
        .where((category) => category['id'] == base['categoryId'])
        .firstOrNull;
    final sellerId = extra['seller'] as String;

    return {
      ...base,
      'ownerId': sellerId,
      'description': extra['description'],
      'isNegotiable': extra['isNegotiable'] ?? true,
      // Ảnh đầu luôn là ảnh bìa trên thẻ trang chủ
      'images': [
        cover,
        for (final image in extra['images'] as List)
          if (image != cover) image,
      ],
      'attributes': extra['attributes'],
      'exchangeWish': base['allowExchange'] == true
          ? extra['exchangeWish']
          : null,
      'areaLabel': extra['areaLabel'],
      'viewCount': extra['viewCount'],
      'category': category,
      'seller': _sellers[sellerId],
      'sellerActiveListings': 3 + sellerId.length % 5,
      'isOwner': false,
    };
  }
}
