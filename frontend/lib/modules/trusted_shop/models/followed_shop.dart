import 'package:equatable/equatable.dart';
import 'package:restore/core/network/media_url.dart';
import 'package:restore/shared/models/listing_card_item.dart';

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

/// Vì sao shop được gợi ý theo dõi
enum ShopSuggestionReason {
  /// Shop bán đúng danh mục những tin mình hay lưu
  matchesInterest,

  /// Đối tác của ReStore: shop đang có gói Cửa hàng hoặc thương hiệu chính hãng
  partner,

  /// Shop nhiều người theo dõi
  popular;

  static ShopSuggestionReason parse(Object? value) => switch (value) {
    'MATCHES_INTEREST' => matchesInterest,
    'PARTNER' => partner,
    _ => popular,
  };
}

/// Shop gợi ý theo dõi (`GET /shops/following/suggestions`): Shop kèm
/// `isFollowing`, `reason` và tối đa 3 tin xem trước (`previews`).
class ShopSuggestion extends Equatable {
  final TrustedShopItem item;
  final ShopSuggestionReason reason;

  /// Đối tác của ReStore (hiện nhãn riêng kể cả khi lý do gợi ý là sở thích)
  final bool isPartner;
  final List<ListingCardItem> previews;

  const ShopSuggestion({
    required this.item,
    this.reason = ShopSuggestionReason.popular,
    this.isPartner = false,
    this.previews = const [],
  });

  factory ShopSuggestion.fromJson(Map<String, dynamic> json) => ShopSuggestion(
    item: TrustedShopItem.fromJson(json),
    reason: ShopSuggestionReason.parse(json['reason']),
    isPartner: json['isPartner'] == true,
    previews: [
      for (final preview in json['previews'] as List? ?? const [])
        ListingCardItem.fromJson(Map<String, dynamic>.from(preview as Map)),
    ],
  );

  String get id => item.shop.id;

  ShopSuggestion withFollowing(bool following) => ShopSuggestion(
    item: item.withFollowing(following),
    reason: reason,
    isPartner: isPartner,
    previews: previews,
  );

  @override
  List<Object?> get props => [item, reason, isPartner, previews];
}
