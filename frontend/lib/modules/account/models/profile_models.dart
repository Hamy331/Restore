import '../../../core/network/media_url.dart';
import 'package:restore/data/models/shop_opening_hours.dart';
import 'package:equatable/equatable.dart';

class SellerStorefront extends Equatable {
  const SellerStorefront({
    this.tier = 'PERSONAL',
    this.shopId,
    this.name,
    this.logo,
    this.cover,
    this.address,
    this.description,
    this.phone,
    this.verified = false,
    this.verificationType,
    this.openingHours = const [],
    this.shopFollowers = 0,
    this.followsShop = false,
    this.listings = 0,
    this.sold = 0,
  });
  final String tier;
  final String? shopId, name, logo, cover, address, description, phone;

  /// CERTIFIED | OFFICIAL_BRAND khi đã xác minh
  final String? verificationType;
  final List<ShopOpeningDay> openingHours;
  final bool verified, followsShop;
  final int shopFollowers, listings, sold;

  /// Đã lên Cửa hàng và được duyệt / xác minh: có nhãn Đối tác (không phụ thuộc gói tài khoản)
  bool get isShop => shopId != null;

  SellerStorefront withShopFollow(bool value) => SellerStorefront(
    tier: tier,
    shopId: shopId,
    name: name,
    logo: logo,
    cover: cover,
    address: address,
    description: description,
    phone: phone,
    verified: verified,
    verificationType: verificationType,
    openingHours: openingHours,
    listings: listings,
    sold: sold,
    followsShop: value,
    shopFollowers:
        shopFollowers +
        (value == followsShop
            ? 0
            : value
            ? 1
            : -1),
  );

  factory SellerStorefront.fromJson(Map<String, dynamic> data) {
    final shop = data['shop'] as Map?;
    return SellerStorefront(
      tier: data['tier'] as String? ?? 'PERSONAL',
      phone: data['phone'] as String?,
      listings: data['listingCount'] as int? ?? 0,
      sold: data['soldCount'] as int? ?? 0,
      shopId: shop?['id'] as String?,
      name: shop?['name'] as String?,
      logo: resolveMediaUrl(shop?['logoUrl'] as String?),
      cover: resolveMediaUrl(shop?['coverUrl'] as String?),
      address: shop?['address'] as String?,
      description: shop?['description'] as String?,
      verified: shop?['verified'] == true,
      verificationType: shop?['verificationType'] as String?,
      openingHours: ShopOpeningDay.listFromJson(shop?['openingHours']),
      shopFollowers: shop?['followerCount'] as int? ?? 0,
      followsShop: shop?['isFollowing'] == true,
    );
  }

  @override
  List<Object?> get props => [
    tier,
    shopId,
    name,
    logo,
    cover,
    address,
    description,
    phone,
    verified,
    verificationType,
    openingHours,
    shopFollowers,
    followsShop,
    listings,
    sold,
  ];
}

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
    this.email,
    this.phone,
    this.isFollowing = false,
    this.followingShopCount = 0,
    this.storefront = const SellerStorefront(),
    this.joined,
    this.lastActive,
    this.online = false,
    this.shopStatus,
  });
  final SellerStorefront storefront;

  /// Chỉ có ở /users/me: PENDING | APPROVED | REJECTED, null = chưa lên Cửa hàng
  final String? shopStatus;
  final DateTime? joined, lastActive;
  final bool online;
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? email;
  final String? phone;
  final int followerCount;
  final int followingCount;

  /// Số shop uy tín đang theo dõi (tab "Shop" ở trang Đang theo dõi)
  final int followingShopCount;
  final double ratingAverage;
  final int ratingCount;

  /// Người đang xem có theo dõi hồ sơ này không (chỉ có ở hồ sơ công khai).
  final bool isFollowing;
  bool get followsSeller =>
      storefront.verified ? storefront.followsShop : isFollowing;

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    id: '${json['id'] ?? ''}',
    fullName: json['fullName'] as String? ?? '',
    username: json['username'] as String? ?? '',
    avatarUrl: resolveMediaUrl(json['avatarUrl'] as String?),
    bio: json['bio'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
    ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
    ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    storefront: SellerStorefront.fromJson(
      json['storefront'] as Map<String, dynamic>? ?? const {},
    ),
    joined: DateTime.tryParse('${json['createdAt']}'),
    lastActive: DateTime.tryParse('${json['presence']?['lastActiveAt']}'),
    online: json['presence']?['isOnline'] == true,
    isFollowing: json['isFollowing'] == true,
    followingShopCount: (json['followingShopCount'] as num?)?.toInt() ?? 0,
    shopStatus: json['shopStatus'] as String?,
  );

  ProfileData copyWith({
    String? fullName,
    String? username,
    String? bio,
    String? email,
    String? phone,
    String? avatarUrl,
    bool clearAvatar = false,
    bool clearPhone = false,
    SellerStorefront? storefront,
    int? followerCount,
    bool? isFollowing,
  }) => ProfileData(
    storefront: storefront ?? this.storefront,
    joined: joined,
    lastActive: lastActive,
    online: online,
    id: id,
    fullName: fullName ?? this.fullName,
    username: username ?? this.username,
    bio: bio ?? this.bio,
    email: email ?? this.email,
    phone: clearPhone ? null : phone ?? this.phone,
    avatarUrl: clearAvatar ? null : avatarUrl ?? this.avatarUrl,
    followerCount: followerCount ?? this.followerCount,
    followingCount: followingCount,
    ratingAverage: ratingAverage,
    ratingCount: ratingCount,
    isFollowing: isFollowing ?? this.isFollowing,
    followingShopCount: followingShopCount,
    shopStatus: shopStatus,
  );

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    avatarUrl,
    bio,
    email,
    phone,
    followerCount,
    followingCount,
    ratingAverage,
    ratingCount,
    isFollowing,
    followingShopCount,
    storefront,
    joined,
    lastActive,
    online,
    shopStatus,
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
