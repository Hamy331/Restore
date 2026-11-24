import '../models/home_listing_filter.dart';
import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';

import '../models/home_banner.dart';
import 'package:restore/shared/models/listing_card_item.dart';

enum HomeStatus { loading, ready, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final HomeListingFilter? _filter;
  final bool? _feedFailed;
  HomeListingFilter get filter => _filter ?? HomeListingFilter.newest;
  bool get feedFailed => _feedFailed ?? false;
  final List<HomeBanner> banners;
  final List<CategoryModel> categories;
  final List<ListingCardItem> recommended;

  final List<ListingCardItem> latest;

  /// Trang cuối đã tải của [latest]
  final int latestPage;
  final bool hasMoreLatest;

  /// Đang tải thêm trang tiếp theo khi cuộn xuống
  final bool isLoadingMore;

  const HomeState({
    HomeListingFilter filter = HomeListingFilter.newest,
    bool feedFailed = false,
    this.status = HomeStatus.loading,
    this.banners = const [],
    this.categories = const [],
    this.recommended = const [],
    this.latest = const [],
    this.latestPage = 0,
    this.hasMoreLatest = false,
    this.isLoadingMore = false,
  }) : _filter = filter,
       _feedFailed = feedFailed;

  HomeState copyWith({
    HomeStatus? status,
    HomeListingFilter? filter,
    bool? feedFailed,
    List<HomeBanner>? banners,
    List<CategoryModel>? categories,
    List<ListingCardItem>? recommended,
    List<ListingCardItem>? latest,
    int? latestPage,
    bool? hasMoreLatest,
    bool? isLoadingMore,
  }) => HomeState(
    filter: filter ?? this.filter,
    feedFailed: feedFailed ?? this.feedFailed,
    status: status ?? this.status,
    banners: banners ?? this.banners,
    categories: categories ?? this.categories,
    recommended: recommended ?? this.recommended,
    latest: latest ?? this.latest,
    latestPage: latestPage ?? this.latestPage,
    hasMoreLatest: hasMoreLatest ?? this.hasMoreLatest,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [
    filter,
    feedFailed,
    status,
    banners,
    categories,
    recommended,
    latest,
    latestPage,
    hasMoreLatest,
    isLoadingMore,
  ];
}
