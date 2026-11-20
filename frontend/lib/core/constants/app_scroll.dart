/// Thông số cuộn dùng chung cho các trang danh sách tin.
class AppScroll {
  AppScroll._();

  /// Khoảng (px logic) ngoài màn hình vẫn được dựng sẵn và tải trước dữ liệu.
  ///
  /// - `cacheExtent` của danh sách: thẻ nằm trong khoảng này dưới mép màn
  ///   hình được dựng trước nên ảnh bắt đầu tải trước khi cuộn tới (mặc định
  ///   của Flutter chỉ 250 px, chưa tới một hàng thẻ).
  /// - Ngưỡng tải trang tiếp ([AppLoadMoreListener]): còn cách cuối khoảng
  ///   này thì gọi API, để trang sau về kịp trước khi người dùng cuộn hết.
  ///
  /// ~1,5 màn hình điện thoại, khoảng 4 hàng thẻ (8 tin); ảnh thumbnail
  /// 480 px nên phần dựng thêm chỉ tốn vài MB bộ nhớ.
  static const double prefetchExtent = 1200;
}
