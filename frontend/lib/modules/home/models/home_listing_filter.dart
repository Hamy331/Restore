/// Tab của danh sách tin trang chủ, theo thứ tự hiển thị.
/// [apiValue] gửi lên `GET /listings?filter=`.
enum HomeListingFilter {
  newest('recent'),
  forYou('forYou'),

  /// Tin của shop đã xác minh
  certified('certified'),
  nearby('nearby'),

  /// Đồ cho tặng miễn phí
  free('free'),

  /// Tin của người bán mình đang theo dõi (cần đăng nhập)
  following('following');

  const HomeListingFilter(this.apiValue);

  final String apiValue;
}
