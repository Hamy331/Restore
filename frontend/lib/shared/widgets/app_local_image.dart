import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/network/media_url.dart';
import 'package:restore/shared/utils/image_cache/app_network_image.dart';

/// Hiển thị ảnh từ asset (`assets/...`), URL (`http...`) hoặc file trên máy
/// (đường dẫn trả về từ image_picker). Lỗi tải ảnh sẽ hiện icon dự phòng.
///
/// Ảnh mạng dùng [AppNetworkImage] (cache bộ nhớ + đĩa), hiện dần khi tải
/// xong thay vì vòng xoay, để cuộn danh sách không giật.
class AppLocalImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  /// Giới hạn kích thước giải mã để tiết kiệm bộ nhớ khi hiển thị thumbnail.
  /// Ảnh mạng không truyền thì giới hạn ở [maxNetworkDecodeWidth].
  final int? cacheWidth;

  /// Bề ngang giải mã tối đa của ảnh mạng khi không truyền [cacheWidth]
  /// (ảnh chụp điện thoại 4000px giải mã đủ cỡ tốn ~60 MB bộ nhớ mỗi ảnh)
  static const int maxNetworkDecodeWidth = 1440;

  const AppLocalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = AppIcons.image,
    this.cacheWidth,
  });

  static bool _isOwnServer(String url) =>
      Uri.tryParse(url)?.origin == Uri.parse(AppEnvironment.apiBaseUrl).origin;

  static Widget _fadeIn(
    BuildContext _,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) => wasSynchronouslyLoaded
      ? child
      : AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    // Ảnh do server lưu có thể là đường dẫn tương đối `/api/v1/...`
    // (VD poster shop); ghép origin của API để tải được.
    final path = resolveMediaUrl(this.path) ?? this.path;
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
    final isHttp = path.startsWith('http://') || path.startsWith('https://');
    // Trên web, ảnh ngoài (CDN) và blob URL của image_picker để trình duyệt
    // tự tải và cache như cũ
    if (isHttp && (!kIsWeb || _isOwnServer(path))) {
      return Image(
        image: ResizeImage(
          // Thumbnail nhỏ từ server cho ô danh sách, ảnh gốc khi xem lớn
          AppNetworkImage(thumbnailUrl(path, cacheWidth)),
          width: cacheWidth ?? maxNetworkDecodeWidth,
          policy: ResizeImagePolicy.fit,
        ),
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        frameBuilder: _fadeIn,
        errorBuilder: errorBuilder,
      );
    }
    if (kIsWeb || isHttp) {
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
