class AppDimesions {
  AppDimesions._();

  /// Dưới mốc này là điện thoại
  static const double mobileWidth = 600;

  /// Máy tính bảng / cửa sổ hẹp: 600 → 1024
  static const double tabletWidth = 1024;

  /// Từ mốc này dùng bố cục web desktop (header, footer, nội dung 1200px)
  static const double desktopWidth = 1024;

  /// Bề rộng tối đa của nội dung trên desktop, hai bên để trống như Shopee
  static const double desktopContentWidth = 1200;

  /// Bề rộng tối đa cho các trang chưa có bố cục desktop riêng
  static const double desktopNarrowWidth = 960;
}
