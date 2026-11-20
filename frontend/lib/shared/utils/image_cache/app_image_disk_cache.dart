import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Cache ảnh mạng trên đĩa (thư mục cache của app), để ảnh đã tải không phải
/// tải lại khi cuộn qua lại hay mở lại app.
///
/// - Khóa là băm của URL; tên file ảnh trên server không đổi nên không cần
///   kiểm tra hết hạn theo header.
/// - [prune] dọn file quá [maxAge] và giữ tổng dung lượng dưới [maxBytes]
///   (xóa file ít dùng nhất trước). Gọi một lần khi mở app.
/// - Trên web hoặc khi không có thư mục cache (VD widget test) thì tắt, mọi
///   thao tác trả về rỗng.
class AppImageDiskCache {
  AppImageDiskCache._();

  /// Cache trên một thư mục cho trước (dùng trong test)
  @visibleForTesting
  AppImageDiskCache.withDirectory(Directory directory)
    : _directory = Future.value(directory);

  static final AppImageDiskCache instance = AppImageDiskCache._();

  static const int maxBytes = 200 * 1024 * 1024;
  static const Duration maxAge = Duration(days: 30);

  Future<Directory?>? _directory;

  Future<Directory?> get _dir => _directory ??= _open();

  Future<Directory?> _open() async {
    if (kIsWeb) return null;
    try {
      final base = await getApplicationCacheDirectory();
      return await Directory(
        '${base.path}${Platform.pathSeparator}app_images',
      ).create(recursive: true);
    } catch (_) {
      return null;
    }
  }

  /// Tên file từ URL: hai mã băm FNV-1a 32 bit (khác seed) + độ dài URL.
  /// Không dùng số 64 bit để code vẫn biên dịch được trên web.
  @visibleForTesting
  static String keyOf(String url) {
    var a = 0x811c9dc5, b = 0x01000193 ^ 0x5bd1e995;
    for (final unit in url.codeUnits) {
      a = ((a ^ unit) * 0x01000193) & 0xffffffff;
      b = ((b ^ unit) * 0x01000193 + 0x9e37) & 0xffffffff;
    }
    String hex(int v) => v.toRadixString(16).padLeft(8, '0');
    return '${hex(a)}${hex(b)}_${url.length.toRadixString(16)}';
  }

  Future<File?> _file(String url) async {
    final dir = await _dir;
    return dir == null
        ? null
        : File('${dir.path}${Platform.pathSeparator}${keyOf(url)}');
  }

  /// Bytes đã lưu của [url], hoặc null nếu chưa có
  Future<Uint8List?> read(String url) async {
    try {
      final file = await _file(url);
      if (file == null || !await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      // Đánh dấu vừa dùng để [prune] giữ lại ảnh hay xem
      unawaited(file.setLastModified(DateTime.now()).catchError((_) {}));
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String url, Uint8List bytes) async {
    try {
      final file = await _file(url);
      if (file == null) return;
      // Ghi ra file tạm rồi đổi tên để không bao giờ đọc phải file ghi dở
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(file.path);
    } catch (_) {}
  }

  Future<void> remove(String url) async {
    try {
      final file = await _file(url);
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Dọn cache: xóa file cũ hơn [maxAge], rồi xóa file ít dùng nhất cho tới
  /// khi tổng dung lượng còn dưới [maxBytes]
  Future<void> prune({DateTime? now}) async {
    try {
      final dir = await _dir;
      if (dir == null) return;
      final current = now ?? DateTime.now();
      final entries = <(File, FileStat)>[];
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (current.difference(stat.modified) > maxAge) {
          await entity.delete();
        } else {
          entries.add((entity, stat));
        }
      }
      entries.sort((x, y) => y.$2.modified.compareTo(x.$2.modified));
      var total = 0;
      for (final (file, stat) in entries) {
        total += stat.size;
        if (total > maxBytes) await file.delete();
      }
    } catch (_) {}
  }
}
