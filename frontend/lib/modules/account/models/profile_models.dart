import '../../../core/network/media_url.dart';
import 'package:equatable/equatable.dart';

class ProfileData extends Equatable {
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
    avatarUrl: resolveMediaUrl(json['avatarUrl'] as String?),
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

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    avatarUrl,
    bio,
    followerCount,
    followingCount,
    ratingAverage,
    ratingCount,
    isFollowing,
  ];
}

/// Một dòng trong danh sách người theo dõi / đang theo dõi.
class FollowUser extends Equatable {
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
    avatarUrl: resolveMediaUrl(json['avatarUrl'] as String?),
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

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    avatarUrl,
    isFollowing,
    isMe,
  ];
}

enum FollowListKind { followers, following }
