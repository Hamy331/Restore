import 'dart:io';
import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import 'package:restore/core/config/app_environment.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';

/// Hiển thị ảnh từ asset (`assets/...`), URL (`http...`) hoặc file trên máy
/// (đường dẫn trả về từ image_picker). Lỗi tải ảnh sẽ hiện icon dự phòng.
class AppLocalImage extends StatefulWidget {
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
  State<AppLocalImage> createState() => _AppLocalImageState();
}

class _AppLocalImageState extends State<AppLocalImage> {
  Future<Uint8List>? _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AppLocalImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  void _load() {
    _bytes = null;
    final uri = Uri.tryParse(widget.path);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.origin == Uri.parse(AppEnvironment.apiBaseUrl).origin &&
        uri.path.startsWith('/api/v1/listings/media/')) {
      _bytes = ApiClient().dio
          .get<List<int>>(
            widget.path,
            options: Options(responseType: ResponseType.bytes),
          )
          .then((response) => Uint8List.fromList(response.data!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path,
        fit = widget.fit,
        width = widget.width,
        height = widget.height;
    final cacheWidth = widget.cacheWidth, fallbackIcon = widget.fallbackIcon;
    Widget errorBuilder(BuildContext _, Object _, StackTrace? _) => Center(
      child: Icon(fallbackIcon, color: AppColors.primaryDark, size: 32),
    );

    if (_bytes != null) {
      return FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (_, snapshot) => snapshot.hasData
            ? Image.memory(
                snapshot.data!,
                fit: fit,
                width: width,
                height: height,
                cacheWidth: cacheWidth,
                errorBuilder: errorBuilder,
              )
            : snapshot.hasError
            ? errorBuilder(context, snapshot.error!, null)
            : SizedBox(
                width: width,
                height: height,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      );
    }

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
