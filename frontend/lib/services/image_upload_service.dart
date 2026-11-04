import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/api_client.dart';

/// Tải ảnh cục bộ lên `POST /media/images` (Cloudinary), trả về URL HTTPS.
/// Dùng chung cho ảnh bài viết và ảnh đại diện.
class ImageUploadService {
  ImageUploadService({Dio? dio}) : _dio = dio ?? ApiClient().dio;
  final Dio _dio;

  static const maxBytes = 5 * 1024 * 1024;

  Future<String> upload(String path) async {
    final bytes = await XFile(path).readAsBytes();
    if (bytes.length > maxBytes) throw const ImageTooLargeException();
    final response = await _dio.post(
      '/media/images',
      data: Stream.value(bytes),
      options: Options(
        contentType: contentType(bytes),
        headers: {'Content-Length': bytes.length},
      ),
    );
    return response.data['data']['imageUrl'];
  }

  /// Nhận dạng theo magic bytes; picker đã nén nên mặc định là JPEG.
  static String contentType(List<int> bytes) {
    if (bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50) {
      return 'image/png';
    }
    if (bytes.length > 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

class ImageTooLargeException implements Exception {
  const ImageTooLargeException();
}
