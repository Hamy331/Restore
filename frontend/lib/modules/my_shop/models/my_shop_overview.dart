import 'package:equatable/equatable.dart';
import 'package:restore/data/models/shop_model.dart';

/// Số liệu nhanh của shop trên trang Quản lý shop
class MyShopStats extends Equatable {
  const MyShopStats({
    this.followerCount = 0,
    this.listingCount = 0,
    this.runningPosters = 0,
    this.pendingPosters = 0,
  });

  final int followerCount;
  final int listingCount;
  final int runningPosters;
  final int pendingPosters;

  factory MyShopStats.fromJson(Map<String, dynamic> json) => MyShopStats(
    followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    listingCount: (json['listingCount'] as num?)?.toInt() ?? 0,
    runningPosters: (json['runningPosters'] as num?)?.toInt() ?? 0,
    pendingPosters: (json['pendingPosters'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [
    followerCount,
    listingCount,
    runningPosters,
    pendingPosters,
  ];
}

/// `GET /shops/me`: shop của mình (null nếu chưa lên Cửa hàng), trạng thái
/// duyệt, phí đăng ký, tên có bị khoá (shop đã duyệt / xác minh) không.
/// Lên Cửa hàng không phụ thuộc gói tài khoản.
class MyShopOverview extends Equatable {
  const MyShopOverview({
    this.shop,
    this.reviewStatus,
    this.rejectNote,
    this.verificationStatus,
    this.verificationNote,
    this.businessName,
    this.taxCode,
    this.registrationFee = 199,
    this.registrationCategories = const [],
    this.canCreate = false,
    this.nameLocked = false,
    this.stats,
  });

  final ShopModel? shop;

  /// `review.status`: PENDING | APPROVED | REJECTED (null khi chưa có shop)
  final String? reviewStatus;

  /// Lý do admin từ chối
  final String? rejectNote;

  /// Hồ sơ xin xác minh gần nhất: PENDING | APPROVED | REJECTED (null = chưa gửi)
  final String? verificationStatus;

  /// Lý do admin từ chối hồ sơ xác minh
  final String? verificationNote;

  /// Tên doanh nghiệp và mã số thuế trên hồ sơ xác minh (chỉ chủ shop thấy)
  final String? businessName, taxCode;

  /// Phí đăng ký lên Cửa hàng (xu, trả một lần)
  final int registrationFee;

  /// Danh mục chọn khi đăng ký (chỉ có khi chưa lên Cửa hàng): tin cửa hàng
  /// chỉ đăng trong danh mục này
  final List<({String id, String name})> registrationCategories;
  final bool canCreate;
  final bool nameLocked;
  final MyShopStats? stats;

  factory MyShopOverview.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'], stats = json['stats'], review = json['review'];
    final verification = json['verification'];
    return MyShopOverview(
      shop: shop is Map
          ? ShopModel.fromJson(Map<String, dynamic>.from(shop))
          : null,
      reviewStatus: review is Map ? review['status'] as String? : null,
      rejectNote: review is Map ? review['rejectNote'] as String? : null,
      verificationStatus: verification is Map
          ? verification['status'] as String?
          : null,
      verificationNote: verification is Map
          ? verification['rejectNote'] as String?
          : null,
      businessName: verification is Map
          ? verification['businessName'] as String?
          : null,
      taxCode: verification is Map ? verification['taxCode'] as String? : null,
      registrationFee: (json['registration']?['fee'] as num?)?.toInt() ?? 199,
      registrationCategories: [
        for (final item
            in json['registration']?['categories'] as List? ?? const [])
          if (item is Map) (id: '${item['id']}', name: '${item['name']}'),
      ],
      canCreate: json['canCreate'] == true,
      nameLocked: json['nameLocked'] == true,
      stats: stats is Map
          ? MyShopStats.fromJson(Map<String, dynamic>.from(stats))
          : null,
    );
  }

  /// Người mua xem được trang shop: đã duyệt hoặc đã xác minh
  bool get isPublic =>
      reviewStatus == 'APPROVED' || (shop?.isVerified ?? false);

  /// Gửi được hồ sơ xác minh: có shop (đang chờ duyệt hoặc đã duyệt, không bị
  /// từ chối), chưa xác minh và không có hồ sơ đang chờ
  bool get canRequestVerification =>
      shop != null &&
      reviewStatus != 'REJECTED' &&
      !(shop?.isVerified ?? true) &&
      verificationStatus != 'PENDING';

  @override
  List<Object?> get props => [
    shop,
    reviewStatus,
    rejectNote,
    verificationStatus,
    verificationNote,
    businessName,
    taxCode,
    registrationFee,
    registrationCategories,
    canCreate,
    nameLocked,
    stats,
  ];
}
