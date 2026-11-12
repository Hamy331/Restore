import 'package:equatable/equatable.dart';
import 'package:restore/modules/account/models/profile_models.dart';
import 'package:restore/modules/feeds/models/feed_models.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/shared/models/listing_card_item.dart';

enum FollowingHubStatus { loading, ready, failure }

class FollowingHubState extends Equatable {
  const FollowingHubState({
    this.status = FollowingHubStatus.loading,
    this.shops = const [],
    this.shopTotal = 0,
    this.people = const [],
    this.peopleTotal = 0,
    this.myId,
    this.suggestions = const [],
    this.posts = const [],
    this.selectedShopId,
    this.listings = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingListings = false,
    this.isLoadingMore = false,
  });

  final FollowingHubStatus status;

  /// Shop đang theo dõi (trang đầu), dùng cho hàng lọc theo shop
  final List<FollowedShop> shops;
  final int shopTotal;

  /// Người đang theo dõi (trang đầu) và tổng số
  final List<FollowUser> people;
  final int peopleTotal;

  /// Id của mình, để mở trang danh sách theo dõi
  final String? myId;

  /// Shop gợi ý theo dõi
  final List<ShopSuggestion> suggestions;

  /// Bài đăng mới trên Bảng tin của những người mình theo dõi
  final List<FeedPost> posts;

  /// Shop đang lọc, null là mọi shop
  final String? selectedShopId;

  final List<ListingCardItem> listings;
  final int page;
  final bool hasMore, isLoadingListings, isLoadingMore;

  /// Chưa theo dõi shop nào: trang chuyển sang màn gợi ý
  bool get isOnboarding => shops.isEmpty;

  /// Số shop đã bấm theo dõi ngay trên màn gợi ý
  int get followedFromSuggestions =>
      suggestions.where((s) => s.item.isFollowing).length;

  /// Tổng tin mới trong 7 ngày của các shop đang theo dõi
  int get newListingCount =>
      shops.fold(0, (sum, shop) => sum + shop.newListingCount);

  FollowedShop? get selectedShop {
    for (final shop in shops) {
      if (shop.id == selectedShopId) return shop;
    }
    return null;
  }

  FollowingHubState copyWith({
    FollowingHubStatus? status,
    List<FollowedShop>? shops,
    int? shopTotal,
    List<FollowUser>? people,
    int? peopleTotal,
    String? myId,
    List<ShopSuggestion>? suggestions,
    List<FeedPost>? posts,
    String? Function()? selectedShopId,
    List<ListingCardItem>? listings,
    int? page,
    bool? hasMore,
    bool? isLoadingListings,
    bool? isLoadingMore,
  }) => FollowingHubState(
    status: status ?? this.status,
    shops: shops ?? this.shops,
    shopTotal: shopTotal ?? this.shopTotal,
    people: people ?? this.people,
    peopleTotal: peopleTotal ?? this.peopleTotal,
    myId: myId ?? this.myId,
    suggestions: suggestions ?? this.suggestions,
    posts: posts ?? this.posts,
    selectedShopId: selectedShopId == null
        ? this.selectedShopId
        : selectedShopId(),
    listings: listings ?? this.listings,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingListings: isLoadingListings ?? this.isLoadingListings,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    status,
    shops,
    shopTotal,
    people,
    peopleTotal,
    myId,
    suggestions,
    posts,
    selectedShopId,
    listings,
    page,
    hasMore,
    isLoadingListings,
    isLoadingMore,
  ];
}
