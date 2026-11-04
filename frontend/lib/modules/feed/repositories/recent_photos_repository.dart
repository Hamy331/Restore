import '../data/feed_mock_data.dart';

/// Ảnh gần đây trong máy, hiện thành lưới ngay dưới thanh công cụ của màn
/// hình viết bài (giống Zalo) để chọn nhanh không cần mở thư viện.
abstract class RecentPhotosRepository {
  /// Đường dẫn ảnh, mới chụp trước
  Future<List<String>> getRecentPhotos({int limit = 60});
}

class MockRecentPhotosRepository implements RecentPhotosRepository {
  @override
  Future<List<String>> getRecentPhotos({int limit = 60}) async =>
      FeedMockData.recentPhotos.take(limit).toList();
}

/// Đọc ảnh thật trong máy cần thêm gói photo_manager và xin quyền ảnh.
/// Chưa có thì trả về rỗng, lưới chỉ còn ô Chụp ảnh và Thư viện.
class DeviceRecentPhotosRepository implements RecentPhotosRepository {
  @override
  Future<List<String>> getRecentPhotos({int limit = 60}) async => const [];
}
