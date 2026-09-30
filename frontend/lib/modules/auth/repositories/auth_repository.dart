import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.code, this.field});
  final String message;
  final String? code;
  final String? field;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final data = _responseData(response);
      await _storeTokens(data);
      return Map<String, dynamic>.from(data['user'] as Map);
    } on DioException catch (error) {
      throw _mapError(error, 'Không thể đăng nhập.');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    try {
      await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email.trim(),
          'password': password,
          'username': username.trim(),
          'fullName': fullName.trim(),
        },
      );
    } on DioException catch (error) {
      throw _mapError(error, 'Không thể đăng ký.');
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/verify-registration-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );
      final data = _responseData(response);
      await _storeTokens(data);
      return Map<String, dynamic>.from(data['user'] as Map);
    } on DioException catch (error) {
      throw _mapError(error, 'Không thể xác minh OTP.');
    }
  }

  Future<void> resendRegistrationOtp(String email) async {
    try {
      await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/resend-registration-otp',
        data: {'email': email.trim()},
      );
    } on DioException catch (error) {
      throw _mapError(error, 'Không thể gửi lại OTP.');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
    } on DioException catch (error) {
      throw _mapError(error, 'Không thể gửi OTP.');
    }
  }

  Future<String> verifyForgotPasswordOtp(String email, String otp) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );
      final data = _responseData(response);
      final resetToken = data['resetToken'];
      if (resetToken is! String || resetToken.isEmpty) {
        throw const FormatException();
      }
      return resetToken;
    } on DioException catch (error) {
      throw _mapError(error, 'Không thể xác minh OTP.');
    } on FormatException {
      throw const AuthException('Phản hồi từ máy chủ không hợp lệ.');
    }
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    try {
      await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {'resetToken': resetToken, 'newPassword': newPassword},
      );
      await _apiClient.tokenStorage.clear();
    } on DioException catch (error) {
      throw _mapError(error, 'Không thể đặt lại mật khẩu.');
    }
  }

  Future<Map<String, dynamic>> currentUser() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/auth/me',
      );
      return _responseData(response);
    } on DioException catch (error) {
      throw _mapError(error, 'Phiên đăng nhập không còn hiệu lực.');
    }
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    var accessToken = await _apiClient.tokenStorage.readAccessToken();
    final refreshToken = await _apiClient.tokenStorage.readRefreshToken();
    if ((accessToken == null || accessToken.isEmpty) &&
        refreshToken != null &&
        refreshToken.isNotEmpty) {
      if (!await _apiClient.refreshSession()) return null;
      accessToken = await _apiClient.tokenStorage.readAccessToken();
    }
    if (accessToken == null || accessToken.isEmpty) return null;
    try {
      return await currentUser();
    } catch (_) {
      await _apiClient.tokenStorage.clear();
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _apiClient.tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _apiClient.dio.post<Map<String, dynamic>>(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } on DioException {
      // Local logout must always complete, even while the API is unavailable.
    } finally {
      await _apiClient.tokenStorage.clear();
    }
  }

  Map<String, dynamic> _responseData(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is! Map) throw const FormatException('Missing response data');
    return Map<String, dynamic>.from(data);
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    final access = data['accessToken'];
    final refresh = data['refreshToken'];
    if (access is! String || refresh is! String) throw const FormatException();
    await _apiClient.tokenStorage.writeTokens(
      accessToken: access,
      refreshToken: refresh,
    );
  }

  AuthException _mapError(DioException error, String fallback) {
    final body = error.response?.data;
    if (body is Map) {
      return AuthException(
        body['error'] is String ? body['error'] as String : fallback,
        code: body['code'] as String?,
        field: body['field'] as String?,
      );
    }
    return const AuthException(
      'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.',
      code: 'NETWORK_ERROR',
    );
  }
}
