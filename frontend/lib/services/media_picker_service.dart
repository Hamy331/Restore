import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

enum MediaSource { camera, gallery }

/// Bọc image_picker để view/bloc không phụ thuộc trực tiếp vào plugin
class MediaPickerService {
  MediaPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const double _maxDimension = 1600;
  static const int _imageQuality = 85;

  /// Thư mục riêng của app giữ ảnh đã chọn cho tới khi tải lên
  static const String _keepFolder = 'picked_photos';

  /// Ảnh giữ quá lâu thì chắc chắn không còn tin nào đang soạn dùng tới
  static const Duration _keepFor = Duration(days: 2);

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
      return file == null ? const [] : _keep([file]);
    }

    final files = await _picker.pickMultiImage(
      limit: limit,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: _imageQuality,
    );
    return _keep(files.take(limit).toList());
  }

  /// Chép ảnh từ bộ nhớ tạm của image_picker sang thư mục riêng của app.
  /// Bộ nhớ tạm có thể bị dọn (hoặc ghi đè khi chọn lại cùng ảnh) trước lúc
  /// lưu tin, khi đó tải ảnh lên sẽ lỗi vì không còn file.
  Future<List<String>> _keep(List<XFile> files) async {
    if (kIsWeb || files.isEmpty) return files.map((file) => file.path).toList();
    try {
      final root = await getApplicationSupportDirectory();
      final folder = Directory(
        '${root.path}${Platform.pathSeparator}$_keepFolder',
      );
      await folder.create(recursive: true);
      await _cleanUp(folder);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final kept = <String>[];
      for (var i = 0; i < files.length; i++) {
        final path = files[i].path;
        final dot = path.lastIndexOf('.');
        final extension = dot > path.lastIndexOf(Platform.pathSeparator)
            ? path.substring(dot)
            : '.jpg';
        final target =
            '${folder.path}${Platform.pathSeparator}${stamp}_$i$extension';
        try {
          kept.add((await File(path).copy(target)).path);
        } on FileSystemException catch (error) {
          debugPrint('Không chép được ảnh $path: $error');
          kept.add(path);
        }
      }
      return kept;
    } on Exception catch (error) {
      debugPrint('Không giữ được ảnh đã chọn: $error');
      return files.map((file) => file.path).toList();
    }
  }

  /// Xóa ảnh cũ đã chọn từ lâu (đã tải lên hoặc bỏ dở)
  Future<void> _cleanUp(Directory folder) async {
    final before = DateTime.now().subtract(_keepFor);
    await for (final entity in folder.list()) {
      if (entity is! File) continue;
      try {
        if ((await entity.lastModified()).isBefore(before)) {
          await entity.delete();
        }
      } on FileSystemException {
        // Bỏ qua, lần chọn ảnh sau dọn tiếp
      }
    }
  }
}
