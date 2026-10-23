/// Dữ liệu mẫu đúng cấu trúc response `GET /me/posting-quota`.
/// Tài khoản cá nhân được 1 đến 3 tin miễn phí đang hiển thị mỗi chuyên mục:
/// món giá trị cao, dễ bị buôn bán (điện thoại, xe, điện tử) chỉ 1 tin; đồ
/// thanh lý hàng loạt (sách, quần áo) được nhiều hơn.
/// Điện thoại để sẵn 1/1 để xem được giao diện khi đã đủ giới hạn.
class PostingQuotaMockData {
  PostingQuotaMockData._();

  static const int personalLimit = 2;

  static final Map<String, dynamic> quota = {
    'accountType': 'personal',
    'defaultLimit': personalLimit,
    'displayDays': 60,
    'businessLimit': 15,
    'categories': [
      {'categoryId': 'phone', 'used': 1, 'limit': 1},
      {'categoryId': 'vehicles', 'used': 0, 'limit': 1},
      {'categoryId': 'electronics', 'used': 0, 'limit': 1},
      {'categoryId': 'appliances', 'used': 0, 'limit': 1},
      {'categoryId': 'pets', 'used': 0, 'limit': 1},
      {'categoryId': 'home', 'used': 0, 'limit': 2},
      {'categoryId': 'fashion', 'used': 1, 'limit': 2},
      {'categoryId': 'sports', 'used': 0, 'limit': 2},
      {'categoryId': 'other', 'used': 0, 'limit': 2},
      {'categoryId': 'books', 'used': 1, 'limit': 3},
    ],
  };
}
