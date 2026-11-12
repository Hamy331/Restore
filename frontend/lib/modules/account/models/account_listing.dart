import 'package:equatable/equatable.dart';
import '../../../data/models/enums/listing_status.dart';
import '../../../data/models/listing_revision_model.dart';

/// Các tab tin đăng trên trang tài khoản và trạng thái tương ứng ở backend.
enum AccountListingStatus {
  visible(ListingStatus.available),
  pending(ListingStatus.pending),
  hidden(ListingStatus.hidden);

  const AccountListingStatus(this.listingStatus);
  final ListingStatus listingStatus;
}

class AccountListing extends Equatable {
  const AccountListing({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.views,
    required this.image,
    this.createdAt,
    this.status = AccountListingStatus.visible,
    this.categoryId,
    this.expiresAt,
    this.paidCredits = 0,
    this.startsAt,
    this.autoExtend = false,
    this.editStatus,
    this.editReason,
  });

  final String id;
  final String title;
  final int price;
  final String category;
  final DateTime? createdAt;
  final int views;
  final String image;
  final AccountListingStatus status;
  final String? categoryId;

  /// Hết hạn hiển thị; tin quá hạn nằm ở tab Đã ẩn
  final DateTime? expiresAt;

  /// Số xu đã trả cho tin (0 = tin miễn phí)
  final int paidCredits;

  /// Ngày hẹn bắt đầu hiển thị: tin đã duyệt nhưng chưa tới ngày nằm ở tab
  /// Đã ẩn cho tới ngày đó
  final DateTime? startsAt;

  /// Đang bật tự gia hạn (gói Cửa hàng)
  final bool autoExtend;

  /// Bản sửa của tin đã duyệt: đang chờ duyệt / bị từ chối; null khi không
  /// có bản sửa. Trong lúc chờ, người mua vẫn thấy bản cũ.
  final ListingRevisionStatus? editStatus;

  /// Lý do bản sửa bị từ chối
  final String? editReason;

  /// Tin đã duyệt và đang chờ tới ngày hẹn để tự hiện
  bool isScheduledAt(DateTime now) =>
      status == AccountListingStatus.hidden &&
      startsAt != null &&
      startsAt!.isAfter(now);

  /// Tin đã quá hạn hiển thị: hiện lại phải kích hoạt lại
  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  /// Số ngày còn hiển thị (làm tròn lên), null khi chưa có hạn
  int? daysLeftAt(DateTime now) {
    final end = expiresAt;
    if (end == null) return null;
    final ms = end.difference(now).inMilliseconds;
    return ms <= 0 ? 0 : (ms / Duration.millisecondsPerDay).ceil();
  }

  AccountListing withStatus(AccountListingStatus value) => AccountListing(
    id: id,
    title: title,
    price: price,
    category: category,
    createdAt: createdAt,
    views: views,
    image: image,
    status: value,
    categoryId: categoryId,
    expiresAt: expiresAt,
    paidCredits: paidCredits,
    startsAt: startsAt,
    autoExtend: autoExtend,
    editStatus: editStatus,
    editReason: editReason,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    price,
    category,
    createdAt,
    views,
    image,
    status,
    categoryId,
    expiresAt,
    paidCredits,
    startsAt,
    autoExtend,
    editStatus,
    editReason,
  ];
}

/// Hiện lại / gia hạn tin bị backend từ chối (HTTP 409): [code] như
/// `POSTING_LIMIT_REACHED`, `NOT_ENOUGH_CREDITS`, `EXTEND_TOO_LONG`
class AccountListingActionException implements Exception {
  const AccountListingActionException(
    this.code, {
    this.message,
    this.details = const {},
  });
  final String code;
  final String? message;
  final Map<String, dynamic> details;

  static const postingLimitReached = 'POSTING_LIMIT_REACHED';
  static const notEnoughCredits = 'NOT_ENOUGH_CREDITS';
  static const extendTooEarly = 'EXTEND_TOO_EARLY';
  static const extendTooLong = 'EXTEND_TOO_LONG';
  static const autoExtendNotAvailable = 'AUTO_EXTEND_NOT_AVAILABLE';

  @override
  String toString() => 'AccountListingActionException($code)';
}
