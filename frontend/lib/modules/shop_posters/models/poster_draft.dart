import 'package:equatable/equatable.dart';

/// Nội dung gửi duyệt (tạo mới hoặc sửa)
class PosterDraft extends Equatable {
  const PosterDraft({
    required this.title,
    required this.imageUrl,
    required this.days,
    this.listingId,
    this.startsAt,
  });

  final String title;

  /// Đường dẫn ảnh đã tải lên (`/api/v1/media/posters/...`)
  final String imageUrl;
  final int days;

  /// null = bấm poster mở trang shop
  final String? listingId;

  /// null = chạy ngay khi được duyệt
  final DateTime? startsAt;

  Map<String, dynamic> toJson() => {
    'title': title,
    'imageUrl': imageUrl,
    'days': days,
    'listingId': listingId,
    'startsAt': startsAt?.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [title, imageUrl, days, listingId, startsAt];
}
