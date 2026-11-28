import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';

import 'profile_repository.dart';

/// Gửi ID token Firebase (sau khi nhập đúng OTP) để backend xác minh số điện
/// thoại. Trả số đã xác minh (dạng 0901234567). Lỗi ném
/// [ProfileUpdateException] với mã backend: INVALID_PHONE_TOKEN,
/// INVALID_PHONE, PHONE_IN_USE, PHONE_VERIFY_UNAVAILABLE.
class PhoneVerificationRepository {
  PhoneVerificationRepository({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();
  final ApiClient _client;

  Future<String> verify(String idToken) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/users/me/phone/verify',
        data: {'idToken': idToken},
      );
      return (response.data!['data'] as Map)['phone'] as String;
    } on DioException catch (error) {
      final body = error.response?.data;
      throw body is Map
          ? ProfileUpdateException(
              body['code'] as String?,
              body['error'] as String?,
            )
          : const ProfileUpdateException(null);
    }
  }
}
