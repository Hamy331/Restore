import 'package:equatable/equatable.dart';

/// Một người dùng trong kết quả tìm kiếm (`GET /search/users`)
class SearchUserItem extends Equatable {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final double ratingAverage;
  final int ratingCount;
  final int followerCount;

  /// Số tin đang bán
  final int listingCount;
  final bool isFollowing;

  /// Shop uy tín của người này, null nếu không có
  final String? shopId;

  const SearchUserItem({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.followerCount = 0,
    this.listingCount = 0,
    this.isFollowing = false,
    this.shopId,
  });

  factory SearchUserItem.fromJson(Map<String, dynamic> json) => SearchUserItem(
    id: '${json['id']}',
    fullName: json['fullName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    bio: json['bio'] as String?,
    ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
    ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    listingCount: (json['listingCount'] as num?)?.toInt() ?? 0,
    isFollowing: json['isFollowing'] as bool? ?? false,
    shopId: json['shopId'] as String?,
  );

  bool get hasShop => shopId != null;

  /// Đổi trạng thái theo dõi, số người theo dõi tăng / giảm theo
  SearchUserItem withFollowing(bool following) {
    if (following == isFollowing) return this;
    final count = followerCount + (following ? 1 : -1);
    return SearchUserItem(
      id: id,
      fullName: fullName,
      username: username,
      avatarUrl: avatarUrl,
      bio: bio,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
      followerCount: count < 0 ? 0 : count,
      listingCount: listingCount,
      isFollowing: following,
      shopId: shopId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    avatarUrl,
    bio,
    ratingAverage,
    ratingCount,
    followerCount,
    listingCount,
    isFollowing,
    shopId,
  ];
}
