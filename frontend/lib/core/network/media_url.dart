import '../config/app_environment.dart';

/// Backend trả ảnh do server lưu (tin đăng, bài viết, ảnh đại diện) dạng
/// đường dẫn tương đối `/api/v1/...`; ghép thêm origin của API để hiển thị.
/// URL tuyệt đối (ảnh ngoài, ảnh cục bộ) giữ nguyên.
String? resolveMediaUrl(String? url, {String? apiBaseUrl}) {
  if (url == null || !url.startsWith('/api/')) return url;
  return '${Uri.parse(apiBaseUrl ?? AppEnvironment.apiBaseUrl).origin}$url';
}

/// Các cỡ thumbnail backend tạo sẵn (`?w=`), xem image-thumbnail.service.ts
const thumbnailWidths = [240, 480, 960];

/// URL thumbnail WebP của ảnh do server lưu, đủ cho bề ngang giải mã [width]
/// (pixel thật). Ảnh tin (`/listings/media/`) và ảnh `/media/` (bảng tin,
/// avatar, shop) mới có thumbnail; ảnh khác, [width] null hoặc lớn hơn cỡ
/// lớn nhất thì giữ URL gốc.
String thumbnailUrl(String url, int? width, {String? apiBaseUrl}) {
  if (width == null || width <= 0 || width > thumbnailWidths.last) return url;
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.hasQuery ||
      uri.origin !=
          Uri.parse(apiBaseUrl ?? AppEnvironment.apiBaseUrl).origin ||
      !(uri.path.startsWith('/api/v1/listings/media/') ||
          uri.path.startsWith('/api/v1/media/'))) {
    return url;
  }
  final size = thumbnailWidths.firstWhere((size) => size >= width);
  return uri.replace(queryParameters: {'w': '$size'}).toString();
}
