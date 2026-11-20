/// Dữ liệu mẫu cho trang tìm kiếm, đúng cấu trúc JSON của API
/// (`GET /search/trending`, `GET /search/suggestions`, `GET /search/history`,
/// `GET /search/users`). Shop dùng lại shop mẫu của Shop uy tín.
/// Tin đăng dùng lại tin mẫu của trang chủ.
class SearchMockData {
  SearchMockData._();

  /// Từ khoá gợi ý tìm nhanh (server tính theo xu hướng và khu vực)
  static const List<String> trending = [
    'Máy ảnh film',
    'Đèn ngủ gỗ handmade',
    'Ghế gỗ quán cafe',
  ];

  /// Kho từ khoá để gợi ý khi đang gõ
  static const List<String> keywords = [
    'Máy ảnh film',
    'Máy ảnh Canon',
    'Máy ảnh Fujifilm',
    'Máy ảnh Nikon FM2',
    'Đèn bàn vintage',
    'Đèn đọc sách',
    'Đèn ngủ gỗ handmade',
    'Ghế gỗ',
    'Ghế gỗ quán cafe',
    'Ghế gỗ sồi Bắc Âu',
    'Lens 50mm',
    'Fujifilm X100F',
  ];

  /// Lịch sử ban đầu của tài khoản mẫu, [now] để tính thời điểm tìm
  static List<Map<String, dynamic>> history(DateTime now) => [
    {
      'id': 'search-1',
      'keyword': 'Máy ảnh Canon',
      'searchedAt': now.subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': 'search-2',
      'keyword': 'Đèn bàn',
      'searchedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  /// Người dùng để tìm theo tên / username (JSON của `GET /search/users`)
  static const List<Map<String, dynamic>> users = [
    {
      'id': 'user_binh',
      'fullName': 'Nguyễn Văn Bình',
      'username': 'binh_nguyen',
      'avatarUrl': null,
      'bio': 'Mê máy ảnh film, hay pass đồ cũ',
      'ratingAverage': 4.8,
      'ratingCount': 23,
      'followerCount': 128,
      'listingCount': 6,
      'isFollowing': false,
      'shopId': null,
    },
    {
      'id': 'user_lan',
      'fullName': 'Trần Ngọc Lan',
      'username': 'lan.decor',
      'avatarUrl': null,
      'bio': 'Đồ decor, đèn ngủ handmade',
      'ratingAverage': 4.9,
      'ratingCount': 41,
      'followerCount': 312,
      'listingCount': 14,
      'isFollowing': true,
      'shopId': null,
    },
    {
      'id': 'user_minh',
      'fullName': 'Lê Minh',
      'username': 'minh_camera',
      'avatarUrl': null,
      'bio': null,
      'ratingAverage': 4.6,
      'ratingCount': 9,
      'followerCount': 45,
      'listingCount': 3,
      'isFollowing': false,
      'shopId': null,
    },
    {
      'id': 'user_kodo',
      'fullName': 'Kodo Camera Official',
      'username': 'kodo.camera',
      'avatarUrl': null,
      'bio': 'Tài khoản của shop Kodo Camera Official',
      'ratingAverage': 4.9,
      'ratingCount': 210,
      'followerCount': 1840,
      'listingCount': 4,
      'isFollowing': false,
      'shopId': 'shop_kodo',
    },
  ];
}
