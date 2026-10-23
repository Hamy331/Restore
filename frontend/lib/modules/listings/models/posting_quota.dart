import 'package:equatable/equatable.dart';
import 'listing_enums.dart';

/// Số tin một chuyên mục đang dùng so với giới hạn của tài khoản.
/// Chỉ tin đang hiển thị và đang chờ duyệt được tính; tin đã bán, đã ẩn
/// hoặc hết hạn thì trả lại suất đăng.
class CategoryPostingQuota extends Equatable {
  final String categoryId;
  final int used;
  final int limit;

  const CategoryPostingQuota({
    required this.categoryId,
    required this.used,
    required this.limit,
  });

  int get remaining => (limit - used).clamp(0, limit);
  bool get isFull => used >= limit;

  /// Còn đúng một suất: nhắc người bán trước khi chạm giới hạn
  bool get isAlmostFull => !isFull && remaining == 1;

  factory CategoryPostingQuota.fromJson(Map<String, dynamic> json) =>
      CategoryPostingQuota(
        categoryId: '${json['categoryId']}',
        used: (json['used'] as num?)?.toInt() ?? 0,
        limit: (json['limit'] as num).toInt(),
      );

  @override
  List<Object?> get props => [categoryId, used, limit];
}

/// Hạn mức đăng tin của tài khoản, nhận từ API `GET /me/posting-quota`.
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
  final Map<String, CategoryPostingQuota> categories;

  const PostingQuota({
    required this.accountType,
    required this.defaultLimit,
    required this.displayDays,
    required this.businessLimit,
    this.categories = const {},
  });

  CategoryPostingQuota forCategory(String categoryId) =>
      categories[categoryId] ??
      CategoryPostingQuota(
        categoryId: categoryId,
        used: 0,
        limit: defaultLimit,
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

  bool isFull(String categoryId) =>
      categoryId.isNotEmpty && forCategory(categoryId).isFull;

  factory PostingQuota.fromJson(Map<String, dynamic> json) {
    final categories = [
      for (final item in json['categories'] as List? ?? const [])
        CategoryPostingQuota.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    return PostingQuota(
      accountType: json['accountType'] == 'business'
          ? SellerType.business
          : SellerType.personal,
      defaultLimit: (json['defaultLimit'] as num).toInt(),
      displayDays: (json['displayDays'] as num?)?.toInt() ?? 60,
      businessLimit: (json['businessLimit'] as num?)?.toInt() ?? 30,
      categories: {for (final item in categories) item.categoryId: item},
    );
  }

  @override
  List<Object?> get props => [
    accountType,
    defaultLimit,
    displayDays,
    businessLimit,
    categories,
  ];
}

/// Đăng tin vượt giới hạn của chuyên mục
class PostingLimitReachedException implements Exception {
  const PostingLimitReachedException();

  /// Mã lỗi backend trả về cùng HTTP 409
  static const String code = 'POSTING_LIMIT_REACHED';
}
