import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/account/repositories/profile_repository.dart';

/// Hồ sơ trong bộ nhớ cho test; username `taken` giả lập lỗi trùng tên.
class FakeProfileRepository implements ProfileRepository {
  ProfileData _profile = const ProfileData(
    id: 'me',
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
