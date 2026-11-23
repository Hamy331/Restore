import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import '../models/profile_models.dart';

/// Lỗi khi lưu hồ sơ; [code] là mã lỗi backend (ví dụ `USERNAME_TAKEN`),
/// [message] là câu báo lỗi backend gửi kèm (nếu có).
class ProfileUpdateException implements Exception {
  const ProfileUpdateException(this.code, [this.message]);
  final String? code;
  final String? message;
}

ProfileUpdateException _profileError(DioException error) {
  final body = error.response?.data;
  return body is Map
      ? ProfileUpdateException(
          body['code'] as String?,
          body['error'] as String?,
        )
      : const ProfileUpdateException(null);
}

abstract class ProfileRepository {
  Future<ProfileData> getMe();
  Future<ProfileData> getUser(String id);
  Future<ProfileData> update(Map<String, dynamic> changes);

  /// Gửi mã OTP tới [email] mới (cần mật khẩu hiện tại); trả số giây phải
  /// chờ trước khi gửi lại mã
  Future<int> requestEmailChange(String email, String password);

  /// Nhập đúng [otp] thì đổi email, trả email mới
  Future<String> verifyEmailChange(String otp);
  Future<void> follow(String id);
  Future<void> unfollow(String id);
  Future<({List<FollowUser> items, bool hasMore})> follows(
    String id,
    FollowListKind kind, {
    int page = 1,
  });
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();
  final ApiClient _client;

  ProfileData _parse(Response<Map<String, dynamic>> response) =>
      ProfileData.fromJson(
        Map<String, dynamic>.from(response.data!['data'] as Map),
      );

  @override
  Future<ProfileData> getUser(String id) async =>
      _parse(await _client.dio.get<Map<String, dynamic>>('/users/$id'));

  @override
  Future<void> follow(String id) async =>
      _client.dio.post<void>('/users/$id/follow');

  @override
  Future<void> unfollow(String id) async =>
      _client.dio.delete<void>('/users/$id/follow');

  @override
  Future<ProfileData> getMe() async =>
      _parse(await _client.dio.get<Map<String, dynamic>>('/users/me'));

  @override
  Future<ProfileData> update(Map<String, dynamic> changes) async {
    try {
      return _parse(
        await _client.dio.patch<Map<String, dynamic>>(
          '/users/me',
          data: changes,
        ),
      );
    } on DioException catch (error) {
      throw _profileError(error);
    }
  }

  @override
  Future<int> requestEmailChange(String email, String password) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/users/me/email',
        data: {'email': email, 'password': password},
      );
      final data = response.data!['data'] as Map;
      return (data['resendAfterSeconds'] as num?)?.toInt() ?? 60;
    } on DioException catch (error) {
      throw _profileError(error);
    }
  }

  @override
  Future<String> verifyEmailChange(String otp) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/users/me/email/verify',
        data: {'otp': otp},
      );
      return (response.data!['data'] as Map)['email'] as String;
    } on DioException catch (error) {
      throw _profileError(error);
    }
  }

  @override
  Future<({List<FollowUser> items, bool hasMore})> follows(
    String id,
    FollowListKind kind, {
    int page = 1,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/users/$id/${kind.name}',
      queryParameters: {'page': page},
    );
    final data = Map<String, dynamic>.from(response.data!['data'] as Map);
    return (
      items: [
        for (final item in data['items'] as List)
          FollowUser.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      hasMore: data['hasMore'] == true,
    );
  }
}
