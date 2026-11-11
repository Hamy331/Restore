/// Dữ liệu mẫu đúng cấu trúc response `GET /listings/posting-quota`.
/// Tài khoản cá nhân được 1 đến 3 tin miễn phí đang hiển thị mỗi chuyên mục:
/// món giá trị cao, dễ bị buôn bán (điện thoại, xe, điện tử) chỉ 1 tin; đồ
/// thanh lý hàng loạt (sách, quần áo) được nhiều hơn.
/// Hết suất thì trả xu theo nhóm giá (15 / 10 / 5 xu), cả tài khoản tối đa 5 tin.
/// Mỗi chuyên mục có số ngày hiển thị miễn phí, tối đa và giá 30 ngày thêm riêng.
/// Điện thoại để sẵn 1/1 để xem được giao diện khi đã đủ giới hạn.
class PostingQuotaMockData {
  PostingQuotaMockData._();

  static const int personalLimit = 2;

  /// Gói Bán chuyên và Cửa hàng (tài liệu hạn mức, mục Loại tài khoản)
  static const int proLimit = 15;
  static const int shopLimit = 30;

  /// Tổng tin miễn phí của tài khoản Cá nhân
  static const int personalTotal = 5;

  /// Xu trong ví mẫu (khớp ví mẫu của module xu)
  static const int walletAvailable = 125;

  static final Map<String, dynamic> quota = {
    'accountType': 'personal',
    'defaultLimit': personalLimit,
    'displayDays': 60,
    'businessLimit': 30,
    'total': {'used': 3, 'limit': personalTotal},
    'wallet': {'available': walletAvailable},
    'display': {
      'packs': [
        {'days': 30, 'discountPercent': 10},
        {'days': 60, 'discountPercent': 20},
        {'days': 90, 'discountPercent': 30},
      ],
      'freeDaysPercent': 100,
      'extendDiscountPercent': 0,
      'autoExtend': false,
      'maxStartDelayDays': 14,
    },
    'categories': [
      {
        'categoryId': 'phones',
        'used': 1,
        'limit': 1,
        'extraCredits': 15,
        'displayDays': 30,
        'maxDisplayDays': 120,
        'dayPackCredits': 15,
      },
      {
        'categoryId': 'vehicles',
        'used': 0,
        'limit': 1,
        'extraCredits': 15,
        'displayDays': 30,
        'maxDisplayDays': 180,
        'dayPackCredits': 15,
      },
      {
        'categoryId': 'electronics',
        'used': 0,
        'limit': 1,
        'extraCredits': 15,
        'displayDays': 45,
        'maxDisplayDays': 120,
        'dayPackCredits': 12,
      },
      {
        'categoryId': 'appliances',
        'used': 0,
        'limit': 1,
        'extraCredits': 10,
        'displayDays': 45,
        'maxDisplayDays': 180,
        'dayPackCredits': 8,
      },
      {
        'categoryId': 'pets',
        'used': 0,
        'limit': 1,
        'extraCredits': 10,
        'displayDays': 21,
        'maxDisplayDays': 60,
        'dayPackCredits': 8,
      },
      {
        'categoryId': 'furniture',
        'used': 0,
        'limit': 2,
        'extraCredits': 10,
        'displayDays': 60,
        'maxDisplayDays': 180,
        'dayPackCredits': 6,
      },
      {
        'categoryId': 'fashion',
        'used': 1,
        'limit': 2,
        'extraCredits': 5,
        'displayDays': 30,
        'maxDisplayDays': 90,
        'dayPackCredits': 4,
      },
      {
        'categoryId': 'sports',
        'used': 0,
        'limit': 2,
        'extraCredits': 5,
        'displayDays': 45,
        'maxDisplayDays': 120,
        'dayPackCredits': 4,
      },
      {
        'categoryId': 'other',
        'used': 0,
        'limit': 2,
        'extraCredits': 5,
        'displayDays': 45,
        'maxDisplayDays': 120,
        'dayPackCredits': 4,
      },
      {
        'categoryId': 'books',
        'used': 1,
        'limit': 3,
        'extraCredits': 5,
        'displayDays': 60,
        'maxDisplayDays': 180,
        'dayPackCredits': 3,
      },
    ],
  };
}
