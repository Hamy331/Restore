import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>?> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];

        await _apiClient.secureStorage.write(key: 'jwt_token', value: token);

        return data['user'];
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Đăng nhập thất bại.');
      }
      throw Exception('Lỗi kết nối máy chủ.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi hệ thống.');
    }
  }

  Future<void> logout() async {
    await _apiClient.secureStorage.delete(key: 'jwt_token');
  }
}
