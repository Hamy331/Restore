/// Bộ lọc của danh sách "Tin đăng mới".
/// [apiValue] gửi lên `GET /listings?filter=`.
enum HomeListingFilter {
  forYou('forYou'),
  newest('recent'),
  nearby('nearby'),
  exchange('exchange');

  const HomeListingFilter(this.apiValue);

  final String apiValue;
}
