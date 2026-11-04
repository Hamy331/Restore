import 'package:dio/dio.dart';
import 'package:restore/core/config/app_environment.dart';
import 'package:restore/core/network/api_client.dart';

class ProfileData {
  const ProfileData({
    required this.id,
    required this.fullName,
    required this.username,
    required this.followerCount,
    required this.followingCount,
    required this.ratingAverage,
    this.ratingCount = 0,
    this.avatarUrl,
    this.bio,
    this.isFollowing = false,
  });
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int followerCount;
  final int followingCount;
  final double ratingAverage;
  final int ratingCount;

  /// Người đang xem có theo dõi hồ sơ này không (chỉ có ở hồ sơ công khai).
  final bool isFollowing;

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    id: '${json['id'] ?? ''}',
    fullName: json['fullName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    bio: json['bio'] as String?,
    followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
    ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    isFollowing: json['isFollowing'] == true,
  );

  ProfileData copyWith({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    bool clearAvatar = false,
    int? followerCount,
    bool? isFollowing,
  }) => ProfileData(
    id: id,
    fullName: fullName ?? this.fullName,
    username: username ?? this.username,
    bio: bio ?? this.bio,
    avatarUrl: clearAvatar ? null : avatarUrl ?? this.avatarUrl,
    followerCount: followerCount ?? this.followerCount,
    followingCount: followingCount,
    ratingAverage: ratingAverage,
    ratingCount: ratingCount,
    isFollowing: isFollowing ?? this.isFollowing,
  );
}

/// Một dòng trong danh sách người theo dõi / đang theo dõi.
class FollowUser {
  const FollowUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.isFollowing = false,
    this.isMe = false,
  });
  factory FollowUser.fromJson(Map<String, dynamic> json) => FollowUser(
    id: '${json['id']}',
    fullName: json['fullName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    isFollowing: json['isFollowing'] == true,
    isMe: json['isMe'] == true,
  );
  final String id, fullName, username;
  final String? avatarUrl;
  final bool isFollowing, isMe;

  FollowUser copyWith({bool? isFollowing}) => FollowUser(
    id: id,
    fullName: fullName,
    username: username,
    avatarUrl: avatarUrl,
    isFollowing: isFollowing ?? this.isFollowing,
    isMe: isMe,
  );
}

enum FollowListKind { followers, following }

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

class MockProfileRepository implements ProfileRepository {
  ProfileData _profile = const ProfileData(
    id: 'mock-user',
    fullName: 'Nguyễn Hoàng Huy',
    username: 'hoanghuy',
    followerCount: 0,
    followingCount: 0,
    ratingAverage: 4.9,
    ratingCount: 12,
  );
  final Set<String> _following = {};
  @override
  Future<ProfileData> getMe() async => _profile;
  @override
  Future<ProfileData> getUser(String id) async => id == _profile.id
      ? _profile
      : ProfileData(
          id: id,
          fullName: 'Minh Anh',
          username: 'minhanh',
          followerCount: _following.contains(id) ? 1 : 0,
          followingCount: 0,
          ratingAverage: 0,
          isFollowing: _following.contains(id),
        );
  @override
  Future<ProfileData> update(Map<String, dynamic> changes) async {
    if (changes['username'] == 'taken') {
      throw const ProfileUpdateException('USERNAME_TAKEN');
    }
    _profile = _profile.copyWith(
      fullName: changes['fullName'] as String?,
      username: changes['username'] as String?,
      bio: changes['bio'] as String?,
      avatarUrl: changes['avatarUrl'] as String?,
      clearAvatar:
          changes.containsKey('avatarUrl') && changes['avatarUrl'] == null,
    );
    return _profile;
  }

  @override
  Future<void> follow(String id) async => _following.add(id);
  @override
  Future<void> unfollow(String id) async => _following.remove(id);
  @override
  Future<({List<FollowUser> items, bool hasMore})> follows(
    String id,
    FollowListKind kind, {
    int page = 1,
  }) async => (items: const <FollowUser>[], hasMore: false);
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

/// Repository theo môi trường: dữ liệu mẫu hoặc API thật.
ProfileRepository createProfileRepository() => AppEnvironment.useMockData
    ? MockProfileRepository()
    : ApiProfileRepository();
