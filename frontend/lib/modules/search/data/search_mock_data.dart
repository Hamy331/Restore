/// Dữ liệu mẫu cho trang tìm kiếm, đúng cấu trúc JSON của API
/// (`GET /search/trending`, `GET /search/suggestions`, `GET /search/history`).
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
}
