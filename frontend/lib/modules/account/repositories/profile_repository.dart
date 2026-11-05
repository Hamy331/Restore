import 'package:dio/dio.dart';
import 'package:restore/core/network/api_client.dart';
import '../models/profile_models.dart';

/// Lỗi khi lưu hồ sơ; [code] là mã lỗi backend (ví dụ `USERNAME_TAKEN`).
class ProfileUpdateException implements Exception {
  const ProfileUpdateException(this.code);
  final String? code;
}

abstract class ProfileRepository {
  Future<ProfileData> getMe();
  Future<ProfileData> getUser(String id);
  Future<ProfileData> update(Map<String, dynamic> changes);
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
      final body = error.response?.data;
      throw ProfileUpdateException(
        body is Map ? body['code'] as String? : null,
      );
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
