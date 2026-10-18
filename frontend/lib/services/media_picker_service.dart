import 'package:image_picker/image_picker.dart';

enum MediaSource { camera, gallery }

/// Bọc image_picker để view/bloc không phụ thuộc trực tiếp vào plugin
class MediaPickerService {
  MediaPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double _maxDimension = 1600;
  static const int _imageQuality = 85;

  /// Trả về danh sách đường dẫn ảnh đã chọn, tối đa [limit] ảnh.
  /// Ném [PlatformException] nếu người dùng từ chối quyền truy cập.
  Future<List<String>> pickImages({
    required MediaSource source,
    required int limit,
  }) async {
    if (limit <= 0) return const [];

    if (source == MediaSource.camera || limit == 1) {
      final file = await _picker.pickImage(
        source: source == MediaSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _imageQuality,
      );
      return file == null ? const [] : [file.path];
    }

    final files = await _picker.pickMultiImage(
      limit: limit,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _imageQuality,
    );
    return files.take(limit).map((file) => file.path).toList();
  }
}
