import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';

import 'app_image_disk_cache.dart';

/// Hàm tải bytes ảnh theo URL (thay được trong test)
typedef AppImageFetcher = Future<Uint8List> Function(String url);

/// Ảnh mạng có cache 2 tầng:
/// - Bộ nhớ: khóa theo URL nên Flutter `ImageCache` giữ ảnh đã giải mã; cuộn
///   ra khỏi màn hình rồi quay lại hiện ngay, không tải hay giải mã lại.
/// - Đĩa: [AppImageDiskCache]; mở lại app không phải tải lại từ mạng.
///
/// Ảnh trên máy chủ của app đi qua [ApiClient] (tự gắn token, tự làm mới
/// phiên) vì ảnh tin chưa duyệt chỉ chủ tin xem được. Ảnh ngoài (CDN...)
/// tải bằng Dio riêng, không gửi token.
@immutable
class AppNetworkImage extends ImageProvider<AppNetworkImage> {
  const AppNetworkImage(this.url);

  final String url;

  /// Thay cách tải ảnh trong test
  @visibleForTesting
  static AppImageFetcher? debugFetcher;

  static final Dio _publicDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static const _listingMediaPath = '/listings/media/';

  @override
  Future<AppNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<AppNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(
    AppNetworkImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _loadCodec(key, decode),
    scale: 1,
    debugLabel: key.url,
    informationCollector: () => [
      DiagnosticsProperty<ImageProvider>('Image provider', this),
    ],
  );

  Future<ui.Codec> _loadCodec(
    AppNetworkImage key,
    ImageDecoderCallback decode,
  ) async {
    final cache = AppImageDiskCache.instance;
    final cached = await cache.read(key.url);
    if (cached != null) {
      try {
        return await decode(await ui.ImmutableBuffer.fromUint8List(cached));
      } catch (_) {
        // File hỏng: xóa rồi tải lại
        await cache.remove(key.url);
      }
    }
    final bytes = await (debugFetcher ?? _fetch)(key.url);
    if (bytes.isEmpty) throw StateError('Empty image: ${key.url}');
    final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    // Chỉ lưu khi giải mã được (không lưu trang lỗi HTML...)
    unawaited(cache.write(key.url, bytes));
    return codec;
  }

  static Future<Uint8List> _fetch(String url) async {
    final uri = Uri.parse(url);
    final options = Options(responseType: ResponseType.bytes);
    final Response<List<int>> response;
    if (uri.origin == Uri.parse(AppEnvironment.apiBaseUrl).origin) {
      response = await ApiClient().dio.get<List<int>>(url, options: options);
    } else {
      // Ảnh tin ở origin khác (VD môi trường dev) vẫn cần token như trước
      if (uri.path.contains(_listingMediaPath)) {
        final token = await ApiClient().tokenStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers = {'Authorization': 'Bearer $token'};
        }
      }
      response = await _publicDio.get<List<int>>(url, options: options);
    }
    final data = response.data ?? const <int>[];
    return data is Uint8List ? data : Uint8List.fromList(data);
  }

  @override
  bool operator ==(Object other) =>
      other is AppNetworkImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => '${objectRuntimeType(this, 'AppNetworkImage')}("$url")';
}
