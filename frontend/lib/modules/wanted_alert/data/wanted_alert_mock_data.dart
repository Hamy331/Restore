/// Thông báo mẫu, đúng cấu trúc JSON của `GET /wanted-alerts`
/// (thiếu các trường số liệu, repository mẫu tự tính từ tin mẫu).
class WantedAlertMockData {
  WantedAlertMockData._();

  /// Mọi tin mẫu đều ở TP.HCM nên lọc khu vực chỉ khớp mã này
  static const String mockListingProvinceCode = '79';

  /// [now] để tạo mốc thời gian tương đối. `seenAt` là lần cuối người dùng
  /// mở xem tin khớp, tin đăng sau mốc này hiện nhãn "Mới".
  static List<Map<String, dynamic>> alerts(DateTime now) => [
    {
      'id': 'alert-1',
      'userId': 'user_me',
      'keywords': 'máy ảnh film',
      'categoryId': 'electronics',
      'category': {
        'id': 'electronics',
        'name': {'vi': 'Đồ điện tử', 'en': 'Electronics'},
      },
      'maxPrice': null,
      'conditions': <String>[],
      'dealTypes': <String>[],
      'area': null,
      'matchLevel': 'BALANCED',
      'createdAt': now.subtract(const Duration(days: 20)).toIso8601String(),
      'seenAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'id': 'alert-2',
      'userId': 'user_me',
      'keywords': 'ghế gỗ',
      'categoryId': null,
      'minPrice': null,
      'maxPrice': null,
      'conditions': <String>[],
      'dealTypes': ['buy'],
      'area': {
        'code': mockListingProvinceCode,
        'level': 'province',
        'label': 'TP. Hồ Chí Minh',
      },
      'matchLevel': 'BROAD',
      'createdAt': now.subtract(const Duration(days: 12)).toIso8601String(),
      'seenAt': now.subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 'alert-3',
      'userId': 'user_me',
      'keywords': 'iPhone 13 Pro Max 256GB',
      'categoryId': 'phone',
      'category': {
        'id': 'phone',
        'name': {'vi': 'Điện thoại', 'en': 'Phones'},
      },
      'minPrice': 8000000,
      'maxPrice': 14000000,
      'conditions': ['LIKE_NEW', 'USED_GOOD'],
      'dealTypes': <String>[],
      'area': null,
      'matchLevel': 'STRICT',
      'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      'seenAt': now.subtract(const Duration(days: 3)).toIso8601String(),
    },
  ];
}
