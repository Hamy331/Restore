import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// Ảnh đại diện danh mục: dùng `imageUrl` từ API (asset khi chạy mock, URL khi
/// có backend). Chưa có ảnh hoặc tải lỗi thì lùi về icon Lucide theo `iconKey`.
class AppCategoryIcon extends StatelessWidget {
  final String? imageUrl;
  final String? iconKey;
  final double size;

  /// Cỡ icon Lucide dự phòng, mặc định bằng một nửa [size]
  final double? fallbackSize;
  final Color fallbackColor;

  const AppCategoryIcon({
    super.key,
    this.imageUrl,
    this.iconKey,
    required this.size,
    this.fallbackSize,
    this.fallbackColor = AppColors.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AppIcons.forCategory(iconKey);
    final fallback = Icon(
      icon,
      size: fallbackSize ?? size / 2,
      color: fallbackColor,
    );
    final path = imageUrl;
    if (path == null || path.isEmpty) return fallback;

    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return SizedBox.square(
      dimension: size,
      child: path.startsWith('assets/')
          ? Image.asset(
              path,
              fit: BoxFit.contain,
              cacheWidth: cacheWidth,
              errorBuilder: (_, _, _) => Center(child: fallback),
            )
          : AppLocalImage(
              path: path,
              fit: BoxFit.contain,
              fallbackIcon: icon,
              cacheWidth: cacheWidth,
            ),
    );
  }
}
