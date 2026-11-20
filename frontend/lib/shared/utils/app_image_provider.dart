import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/media_url.dart';
import 'package:restore/shared/utils/image_cache/app_network_image.dart';

/// Ảnh từ URL (http/https) hoặc ảnh trong assets của app (VD logo shop seed
/// "assets/images/shops/samsung.png"), dùng cho CircleAvatar.foregroundImage.
/// Ảnh mạng có cache bộ nhớ + đĩa ([AppNetworkImage]) và giải mã ở cỡ nhỏ
/// [decodeWidth] (avatar chỉ cần vài trăm px).
ImageProvider appImageProvider(String path, {int decodeWidth = 256}) {
  if (path.startsWith('assets/')) return AssetImage(path);
  final url = resolveMediaUrl(path) ?? path;
  // Trên web, ảnh ngoài (CDN) để trình duyệt tự tải như cũ
  if (kIsWeb &&
      Uri.tryParse(url)?.origin !=
          Uri.parse(AppEnvironment.apiBaseUrl).origin) {
    return ResizeImage(NetworkImage(url), width: decodeWidth);
  }
  return ResizeImage(
    AppNetworkImage(thumbnailUrl(url, decodeWidth)),
    width: decodeWidth,
    policy: ResizeImagePolicy.fit,
  );
}
