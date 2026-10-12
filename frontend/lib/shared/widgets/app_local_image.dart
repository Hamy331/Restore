import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Hiển thị ảnh từ asset (`assets/...`), URL (`http...`) hoặc file trên máy
/// (đường dẫn trả về từ image_picker). Lỗi tải ảnh sẽ hiện icon dự phòng.
class AppLocalImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  /// Giới hạn kích thước giải mã để tiết kiệm bộ nhớ khi hiển thị thumbnail
  final int? cacheWidth;

  const AppLocalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = AppIcons.image,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget errorBuilder(BuildContext _, Object _, StackTrace? _) => Center(
      child: Icon(fallbackIcon, color: AppColors.primaryDark, size: 32),
    );

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        errorBuilder: errorBuilder,
      );
    }
    // Trên web, image_picker trả về blob URL nên đọc như ảnh mạng
    if (kIsWeb || path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        errorBuilder: errorBuilder,
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      errorBuilder: errorBuilder,
    );
  }
}
