import 'posting_quota_mock_data.dart';

/// Số tin đã dùng của từng chuyên mục khi chạy dữ liệu mẫu, giữ trong bộ
/// nhớ suốt phiên. Đăng tin mẫu xong thì tăng lên để giao diện hạn mức
/// cập nhật giống khi có API.
class MockPostingQuotaStore {
  MockPostingQuotaStore._();

  static List<Map> get _seed =>
      (PostingQuotaMockData.quota['categories'] as List).cast<Map>();

  static final Map<String, int> used = {
    for (final item in _seed) item['categoryId'] as String: item['used'] as int,
  };

  static int limitOf(String categoryId) {
    for (final item in _seed) {
      if (item['categoryId'] == categoryId) return item['limit'] as int;
    }
    return PostingQuotaMockData.personalLimit;
  }

  static void recordPublished(String categoryId) =>
      used[categoryId] = (used[categoryId] ?? 0) + 1;
}
