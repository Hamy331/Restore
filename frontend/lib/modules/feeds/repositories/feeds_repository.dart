import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';

class FeedsRepository {
  final Dio dio = ApiClient().dio;
  Future<Map<String, dynamic>> get(
    String path, [
    Map<String, dynamic>? query,
  ]) async => Map<String, dynamic>.from(
    (await dio.get(path, queryParameters: query)).data['data'],
  );
  Future<dynamic> post(String path, Map<String, dynamic> data) async =>
      (await dio.post(path, data: data)).data['data'];
  Future<Map<String, dynamic>> like(String path, bool value) async =>
      Map<String, dynamic>.from(
        (await dio.request(
          path,
          options: Options(method: value ? 'PUT' : 'DELETE'),
        )).data['data'],
      );
  Future<void> follow(String id, bool value) async {
    await dio.request(
      '/users/$id/follow',
      options: Options(method: value ? 'POST' : 'DELETE'),
    );
  }

  Future<String> upload(String path) async {
    final bytes = await XFile(path).readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) throw Exception('Image exceeds 5 MB');
    final type = bytes.length > 12 && bytes[0] == 137
        ? 'image/png'
        : bytes.length > 12 && bytes[0] == 82
        ? 'image/webp'
        : 'image/jpeg';
    final response = await dio.post(
      '/media/images',
      data: Stream.value(bytes),
      options: Options(
        contentType: type,
        headers: {'Content-Length': bytes.length},
      ),
    );
    return response.data['data']['imageUrl'];
  }
}
