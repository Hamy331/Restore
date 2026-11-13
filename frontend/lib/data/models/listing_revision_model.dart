import 'package:equatable/equatable.dart';
import 'package:restore/data/models/listing_model.dart';

/// Trạng thái bản sửa của tin đã duyệt (cột ListingRevision.status)
enum ListingRevisionStatus {
  pending('PENDING'),
  rejected('REJECTED');

  const ListingRevisionStatus(this.apiValue);
  final String apiValue;

  static ListingRevisionStatus? fromApi(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}

/// Một dòng của bảng ListingRevision: bản sửa của tin đã duyệt, chờ duyệt
/// lại. Trong lúc chờ, người mua vẫn thấy bản cũ của tin; duyệt thì bản sửa
/// thay vào, bị từ chối thì tin giữ nguyên bản cũ.
///
/// API trả về trong `pendingEdit` của tin (chỉ chủ tin thấy), cùng tên khoá
/// với tin nên [content] là chính tin đó sau khi áp bản sửa.
class ListingRevisionModel extends Equatable {
  final ListingRevisionStatus status;

  /// Lý do bị từ chối (null khi đang chờ)
  final String? reviewReason;
  final DateTime? submittedAt;

  /// Tin với nội dung của bản sửa (trạng thái vẫn là trạng thái của tin)
  final ListingModel content;

  const ListingRevisionModel({
    required this.status,
    required this.content,
    this.reviewReason,
    this.submittedAt,
  });

  bool get isPending => status == ListingRevisionStatus.pending;
  bool get isRejected => status == ListingRevisionStatus.rejected;

  /// [listing] là JSON của tin, [revision] là `pendingEdit` của nó
  static ListingRevisionModel? fromListingJson(
    Map<String, dynamic> listing,
    Object? revision, {
    String? apiBaseUrl,
  }) {
    if (revision is! Map) return null;
    final data = Map<String, dynamic>.from(revision);
    final status = ListingRevisionStatus.fromApi(data['status'] as String?);
    if (status == null) return null;
    return ListingRevisionModel(
      status: status,
      reviewReason: data['reviewReason'] as String?,
      submittedAt: DateTime.tryParse('${data['submittedAt']}'),
      content: ListingModel.fromJson({
        ...listing,
        ...data,
        // Bản sửa không có trạng thái tin / thời điểm của riêng tin
        'status': listing['status'],
        'updatedAt': listing['updatedAt'],
        'reviewReason': listing['reviewReason'],
        'pendingEdit': null,
      }, apiBaseUrl: apiBaseUrl),
    );
  }

  @override
  List<Object?> get props => [status, reviewReason, submittedAt, content];
}
