import 'package:equatable/equatable.dart';
import 'listing_enums.dart';

/// Lý do hết suất miễn phí ở một chuyên mục
enum PostingQuotaBlock {
  /// Chuyên mục đã đủ số tin miễn phí
  category,

  /// Cả tài khoản đã đủ số tin miễn phí (Cá nhân: 5 tin)
  total,

  /// Đăng miễn phí quá nhiều lần trong 30 ngày (đăng rồi ẩn liên tục)
  recent;

  static PostingQuotaBlock? fromApi(Object? value) => switch (value) {
    'CATEGORY' => category,
    'TOTAL' => total,
    'RECENT' => recent,
    _ => null,
  };
}

/// Số tin một chuyên mục đang dùng so với giới hạn của tài khoản.
/// Chỉ tin đang hiển thị và đang chờ duyệt được tính; tin đã bán, đã ẩn
/// hoặc hết hạn thì trả lại suất đăng. Tin trả bằng xu không chiếm suất.
class CategoryPostingQuota extends Equatable {
  final String categoryId;
  final int used;
  final int limit;

  /// Giá (xu) một tin vượt hạn mức; null = gói không cho trả xu
  final int? extraCredits;

  /// Lý do hết suất miễn phí, null = còn suất
  final PostingQuotaBlock? blockedBy;

  /// Số ngày tin hiển thị (cũng là số ngày mỗi lần gia hạn)
  final int displayDays;

  /// Giá (xu) gia hạn tin thêm một kỳ, mọi gói đều gia hạn được
  final int? extendCredits;

  /// Giá (xu) một lần đẩy tin, đã giảm theo gói
  final int? boostCredits;

  const CategoryPostingQuota({
    required this.categoryId,
    required this.used,
    required this.limit,
    this.extraCredits,
    this.blockedBy,
    this.displayDays = 60,
    this.extendCredits,
    this.boostCredits,
  });

  int get remaining => (limit - used).clamp(0, limit);

  /// Không còn suất miễn phí (do chuyên mục, tổng tài khoản hoặc đăng lại nhiều)
  bool get isFull => blockedBy != null || used >= limit;

  /// Còn đúng một suất: nhắc người bán trước khi chạm giới hạn
  bool get isAlmostFull => !isFull && remaining == 1;

  /// Hết suất nhưng được đăng tiếp bằng xu
  bool get canPayWithCredits => extraCredits != null && extraCredits! > 0;

  factory CategoryPostingQuota.fromJson(Map<String, dynamic> json) {
    final used = (json['used'] as num?)?.toInt() ?? 0;
    final limit = (json['limit'] as num).toInt();
    final free = json['freeAvailable'];
    return CategoryPostingQuota(
      categoryId: '${json['categoryId']}',
      used: used,
      limit: limit,
      extraCredits: (json['extraCredits'] as num?)?.toInt(),
      displayDays: (json['displayDays'] as num?)?.toInt() ?? 60,
      extendCredits:
          (json['extendCredits'] as num?)?.toInt() ??
          (json['extraCredits'] as num?)?.toInt(),
      boostCredits: (json['boostCredits'] as num?)?.toInt(),
      blockedBy:
          PostingQuotaBlock.fromApi(json['blockedBy']) ??
          (free == false || (free == null && used >= limit)
              ? PostingQuotaBlock.category
              : null),
    );
  }

  @override
  List<Object?> get props => [
    categoryId,
    used,
    limit,
    extraCredits,
    blockedBy,
    displayDays,
    extendCredits,
    boostCredits,
  ];
}

/// Hạn mức đăng tin của tài khoản, nhận từ API `GET /listings/posting-quota`.
/// Giới hạn do backend quyết định theo loại tài khoản và từng chuyên mục,
/// app chỉ hiển thị và chặn sớm để người bán không mất công điền tin.
class PostingQuota extends Equatable {
  final SellerType accountType;

  /// Giới hạn mặc định cho chuyên mục không có cấu hình riêng
  final int defaultLimit;

  /// Số ngày một tin được hiển thị trước khi hết hạn
  final int displayDays;

  /// Giới hạn của tài khoản bán chuyên, để giới thiệu khi nâng cấp
  final int businessLimit;

  /// Số tin miễn phí đang dùng / tối đa trên cả tài khoản (Cá nhân: 5)
  final int totalUsed;
  final int? totalLimit;

  /// Số xu đang có trong ví, để biết đủ trả cho tin vượt hạn mức không
  final int walletAvailable;
  final Map<String, CategoryPostingQuota> categories;

  /// Lượt đẩy tin miễn phí còn lại trong tháng / lượt tặng mỗi tháng của gói
  final int boostFreeLeft;
  final int boostFreePerMonth;

  /// Phần trăm giảm giá đẩy tin của gói (0 với Cá nhân)
  final int boostDiscountPercent;

  const PostingQuota({
    required this.accountType,
    required this.defaultLimit,
    required this.displayDays,
    required this.businessLimit,
    this.totalUsed = 0,
    this.totalLimit,
    this.walletAvailable = 0,
    this.categories = const {},
    this.boostFreeLeft = 0,
    this.boostFreePerMonth = 0,
    this.boostDiscountPercent = 0,
  });

  CategoryPostingQuota forCategory(String categoryId) =>
      categories[categoryId] ??
      CategoryPostingQuota(
        categoryId: categoryId,
        used: 0,
        limit: defaultLimit,
        displayDays: displayDays,
      );

  /// Giới hạn thấp nhất và cao nhất giữa các chuyên mục, để giới thiệu
  /// ngắn gọn kiểu "1 đến 3 tin mỗi chuyên mục"
  int get minLimit => categories.values.fold(
    defaultLimit,
    (min, item) => item.limit < min ? item.limit : min,
  );
  int get maxLimit => categories.values.fold(
    defaultLimit,
    (max, item) => item.limit > max ? item.limit : max,
  );

  /// Giá thấp nhất một tin vượt hạn mức, null khi không trả xu được
  int? get minExtraCredits {
    final prices = categories.values
        .map((item) => item.extraCredits)
        .whereType<int>()
        .where((price) => price > 0);
    return prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
  }

  bool isFull(String categoryId) =>
      categoryId.isNotEmpty && forCategory(categoryId).isFull;

  factory PostingQuota.fromJson(Map<String, dynamic> json) {
    final categories = [
      for (final item in json['categories'] as List? ?? const [])
        CategoryPostingQuota.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    final total = json['total'] is Map ? json['total'] as Map : const {};
    final wallet = json['wallet'] is Map ? json['wallet'] as Map : const {};
    final boost = json['boost'] is Map ? json['boost'] as Map : const {};
    return PostingQuota(
      accountType: json['accountType'] == 'business'
          ? SellerType.business
          : SellerType.personal,
      defaultLimit: (json['defaultLimit'] as num).toInt(),
      displayDays: (json['displayDays'] as num?)?.toInt() ?? 60,
      businessLimit: (json['businessLimit'] as num?)?.toInt() ?? 30,
      totalUsed: (total['used'] as num?)?.toInt() ?? 0,
      totalLimit: (total['limit'] as num?)?.toInt(),
      walletAvailable: (wallet['available'] as num?)?.toInt() ?? 0,
      categories: {for (final item in categories) item.categoryId: item},
      boostFreeLeft: (boost['freeLeft'] as num?)?.toInt() ?? 0,
      boostFreePerMonth: (boost['freePerMonth'] as num?)?.toInt() ?? 0,
      boostDiscountPercent: (boost['discountPercent'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    accountType,
    defaultLimit,
    displayDays,
    businessLimit,
    totalUsed,
    totalLimit,
    walletAvailable,
    categories,
    boostFreeLeft,
    boostFreePerMonth,
    boostDiscountPercent,
  ];
}

/// Đăng tin vượt giới hạn của chuyên mục
class PostingLimitReachedException implements Exception {
  const PostingLimitReachedException();

  /// Mã lỗi backend trả về cùng HTTP 409
  static const String code = 'POSTING_LIMIT_REACHED';

  /// Đồng ý trả xu nhưng ví không đủ
  static const String notEnoughCredits = 'NOT_ENOUGH_CREDITS';
}
