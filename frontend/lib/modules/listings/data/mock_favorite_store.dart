/// Tin đã lưu khi chạy dữ liệu mẫu, giữ trong bộ nhớ suốt phiên.
/// Trang chủ và trang chi tiết dùng chung để trạng thái "Lưu tin" khớp nhau.
class MockFavoriteStore {
  MockFavoriteStore._();

  static final Set<String> ids = {};

  static bool contains(String listingId) => ids.contains(listingId);

  static void set(String listingId, bool favorite) =>
      favorite ? ids.add(listingId) : ids.remove(listingId);
}
