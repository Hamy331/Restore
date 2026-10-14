import 'package:equatable/equatable.dart';

/// Banner ảnh ở trang chủ, nhận từ `GET /home/banners`.
/// Ảnh thiết kế theo tỉ lệ [aspectRatio] (1200 × 600 px).
class HomeBanner extends Equatable {
  static const double aspectRatio = 2;

  final String id;

  /// URL ảnh; null khi chưa có ảnh thì app hiện khung trống đúng tỉ lệ
  final String? imageUrl;

  /// Đường dẫn trong app khi bấm (VD "/create-listing/category"), có thể null
  final String? route;

  const HomeBanner({required this.id, this.imageUrl, this.route});

  factory HomeBanner.fromJson(Map<String, dynamic> json) => HomeBanner(
    id: '${json['id']}',
    imageUrl: json['imageUrl'] as String?,
    route: json['route'] as String?,
  );

  @override
  List<Object?> get props => [id, imageUrl, route];
}
