import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';

/// Nền màu cho bài viết chỉ có chữ (giống "Aa" của Zalo/Facebook).
/// Danh sách nền lấy từ API để thêm mẫu mới không cần cập nhật app.
class PostBackground extends Equatable {
  final String id;

  /// Màu gradient từ trên trái xuống dưới phải, dạng `#RRGGBB`
  final List<Color> colors;

  /// Chữ sáng (trắng) hay tối trên nền này
  final bool lightText;

  const PostBackground({
    required this.id,
    required this.colors,
    this.lightText = true,
  });

  factory PostBackground.fromJson(Map<String, dynamic> json) => PostBackground(
    id: '${json['id']}',
    colors: [
      for (final hex in (json['colors'] as List? ?? const []))
        Color(int.parse('FF${'$hex'.replaceFirst('#', '')}', radix: 16)),
    ],
    lightText: json['lightText'] as bool? ?? true,
  );

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors.length == 1 ? [colors.first, colors.first] : colors,
  );

  @override
  List<Object?> get props => [id, colors, lightText];
}
