import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AdminRepository {
  AdminRepository({Dio? dio}) : dio = dio ?? ApiClient().dio;
  final Dio dio;
  Future<dynamic> get(String resource, {int page = 1, String q = ''}) async =>
      (await dio.get<Map<String, dynamic>>(
        '/admin/$resource',
        queryParameters: {'page': page, if (q.isNotEmpty) 'q': q},
      )).data!['data'];
  Future<void> save(
    String resource,
    Map<String, dynamic> data, {
    bool update = false,
    bool delete = false,
  }) async {
    await dio.request<void>(
      '/admin/$resource',
      data: data,
      options: Options(
        method: delete
            ? 'DELETE'
            : update
            ? 'PUT'
            : 'POST',
      ),
    );
  }

  Future<String> uploadCover(Uint8List bytes) async {
    final type = bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216
        ? 'image/jpeg'
        : bytes.length >= 8 && bytes[0] == 137 && bytes[1] == 80
        ? 'image/png'
        : 'image/webp';
    final response = await dio.post<Map<String, dynamic>>(
      '/content/media',
      data: bytes,
      options: Options(contentType: type),
    );
    return (response.data!['data'] as Map)['url'] as String;
  }

  Future<void> uploadKnowledge(String title, String content) async {
    await dio.post<void>(
      '/content/knowledge/upload',
      data: content,
      queryParameters: {'title': title},
      options: Options(contentType: 'text/plain; charset=utf-8'),
    );
  }

  String message(Object error) => error is FormatException
      ? (error.message.toString())
      : error is DioException && error.response?.data is Map
      ? '${(error.response!.data as Map)['error'] ?? 'Thao tác thất bại.'}'
      : 'Không kết nối được máy chủ. Vui lòng thử lại.';
}
