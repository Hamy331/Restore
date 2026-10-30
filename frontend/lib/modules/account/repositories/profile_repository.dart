import 'package:restore/core/network/api_client.dart';

class ProfileData {
  const ProfileData({
    required this.fullName,
    required this.username,
    required this.followerCount,
    required this.followingCount,
    required this.ratingAverage,
    this.avatarUrl,
    this.bio,
  });
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final double ratingAverage;

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    fullName: json['fullName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    bio: json['bio'] as String?,
    followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
  );
}

abstract class ProfileRepository {
  Future<ProfileData> getMe();
  Future<ProfileData> update(Map<String, dynamic> changes);
}

class MockProfileRepository implements ProfileRepository {
  ProfileData _profile = const ProfileData(
    fullName: 'Nguyễn Hoàng Huy',
    username: 'hoanghuy',
    followerCount: 0,
    followingCount: 0,
    ratingAverage: 4.9,
  );
  @override
  Future<ProfileData> getMe() async => _profile;
  @override
  Future<ProfileData> update(Map<String, dynamic> changes) async {
    _profile = ProfileData(
      fullName: changes['fullName'] as String? ?? _profile.fullName,
      username: changes['username'] as String? ?? _profile.username,
      bio: changes['bio'] as String? ?? _profile.bio,
      avatarUrl: changes['avatarUrl'] as String? ?? _profile.avatarUrl,
      followerCount: _profile.followerCount,
      followingCount: _profile.followingCount,
      ratingAverage: _profile.ratingAverage,
    );
    return _profile;
  }
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();
  final ApiClient _client;

  Future<ProfileData> getUser(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>('/users/$id');
    return ProfileData.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }

  Future<void> follow(String id) async =>
      _client.dio.post<void>('/users/$id/follow');

  Future<void> unfollow(String id) async =>
      _client.dio.delete<void>('/users/$id/follow');

  @override
  Future<ProfileData> getMe() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/users/me');
    return ProfileData.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }

  @override
  Future<ProfileData> update(Map<String, dynamic> changes) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/users/me',
      data: changes,
    );
    return ProfileData.fromJson(
      Map<String, dynamic>.from(response.data!['data'] as Map),
    );
  }
}
