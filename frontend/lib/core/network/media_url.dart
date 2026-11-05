import '../config/app_environment.dart';

/// Backend trả ảnh do server lưu (tin đăng, bài viết, ảnh đại diện) dạng
/// đường dẫn tương đối `/api/v1/...`; ghép thêm origin của API để hiển thị.
/// URL tuyệt đối (ảnh ngoài, ảnh cục bộ) giữ nguyên.
String? resolveMediaUrl(String? url, {String? apiBaseUrl}) {
  if (url == null || !url.startsWith('/api/')) return url;
  return '${Uri.parse(apiBaseUrl ?? AppEnvironment.apiBaseUrl).origin}$url';
}
