/// Trạng thái duyệt banner shop gửi lên (cột status của bảng ShopBanner, đề
/// xuất trong `backend/docs/trusted-shops.md`). App chỉ nhận banner đã duyệt
/// và đang trong thời gian chạy; các trạng thái khác dùng cho trang quản lý.
enum ShopBannerStatus {
  /// Shop vừa gửi, chờ admin duyệt
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  const ShopBannerStatus(this.apiValue);

  final String apiValue;

  static ShopBannerStatus? fromApi(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}
