/// Các bước nạp xu trên cùng một trang
enum TopupStep {
  /// Chọn gói
  choose,

  /// Xem lại, chọn cách trả, đồng ý điều khoản
  confirm,

  /// Đang trả tiền (cổng VNPay hoặc mã VietQR)
  pay,

  /// Thành công / đang chờ / thất bại
  result,
}
