import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:restore/core/constants/app_colors.dart';
import 'package:restore/core/constants/app_icons.dart';
import 'package:restore/core/network/media_url.dart';
import 'package:restore/shared/widgets/app_local_image.dart';

/// Ảnh poster tỉ lệ 2:1, bo góc. Nhận đường dẫn server (`/api/...`),
/// asset, file trên máy hoặc [bytes] vừa cắt; chưa có ảnh thì hiện [placeholder].
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.path,
    this.bytes,
    this.radius = 16,
    this.placeholder,
  });

  final String? path;

  /// Ảnh vừa cắt trong bộ nhớ, ưu tiên hơn [path]
  final Uint8List? bytes;
  final double radius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 2,
        child: ColoredBox(
          color: AppColors.cream,
          child: bytes != null
              ? Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true)
              : resolved == null || resolved.isEmpty
              ? placeholder ??
                    const Center(
                      child: Icon(AppIcons.image, color: AppColors.primaryDark),
                    )
              : AppLocalImage(path: resolved, cacheWidth: 1200),
        ),
      ),
    );
  }
}
