import 'package:equatable/equatable.dart';
import 'package:restore/core/network/media_url.dart';

import 'trusted_shop_item.dart';

/// Shop người dùng đang theo dõi (`GET /shops/following`): Shop kèm
/// `isFollowing`, `followedAt` và `newListingCount` (tin đăng 7 ngày qua).
class FollowedShop extends Equatable {
  final TrustedShopItem item;
  final int newListingCount;
  final DateTime? followedAt;

  const FollowedShop({
    required this.item,
    this.newListingCount = 0,
    this.followedAt,
  });

  factory FollowedShop.fromJson(Map<String, dynamic> json) => FollowedShop(
    item: TrustedShopItem.fromJson({'isFollowing': true, ...json}),
    newListingCount: (json['newListingCount'] as num?)?.toInt() ?? 0,
    followedAt: DateTime.tryParse('${json['followedAt'] ?? ''}'),
  );

  String get id => item.shop.id;

  FollowedShop withFollowing(bool following) => FollowedShop(
    item: item.withFollowing(following),
    newListingCount: newListingCount,
    followedAt: followedAt,
  );

  @override
  List<Object?> get props => [item, newListingCount, followedAt];
}

/// Một người đang theo dõi shop của mình (`GET /shops/me/followers`)
class ShopFollower extends Equatable {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final DateTime? followedAt;

  const ShopFollower({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.followedAt,
  });

  factory ShopFollower.fromJson(Map<String, dynamic> json) => ShopFollower(
    id: '${json['id']}',
    fullName: json['fullName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    avatarUrl: resolveMediaUrl(json['avatarUrl'] as String?),
    followedAt: DateTime.tryParse('${json['followedAt'] ?? ''}'),
  );

  @override
  List<Object?> get props => [id, fullName, username, avatarUrl, followedAt];
}
