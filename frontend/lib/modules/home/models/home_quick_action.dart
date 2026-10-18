/// Lối tắt dưới hàng danh mục. Là chức năng của app nên khai báo cố định,
/// không lấy từ API.
enum HomeQuickAction {
  /// Tin quanh vị trí hiện tại (trang riêng)
  nearby,

  /// Thẻ đặt trước: báo khi có tin khớp món người dùng đang tìm
  wantedAlert,

  /// Khám phá shop đã xác minh, tương tác tốt
  trustedShops,

  /// Shop và người dùng mình đang theo dõi
  following,
}
