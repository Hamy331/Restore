import 'package:equatable/equatable.dart';
import 'package:restore/data/models/category_model.dart';
import 'package:restore/data/models/user_model.dart';

import '../models/home_banner.dart';
import '../models/home_listing_item.dart';

enum HomeStatus { loading, ready, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final UserModel? user;
  final String areaName;
  final List<HomeBanner> banners;
  final List<CategoryModel> categories;
  final List<HomeListingItem> recommended;

  final List<HomeListingItem> latest;

  /// Trang cuối đã tải của [latest]
  final int latestPage;
  final bool hasMoreLatest;

  /// Đang tải thêm trang tiếp theo khi cuộn xuống
  final bool isLoadingMore;

  const HomeState({
    this.status = HomeStatus.loading,
    this.user,
    this.areaName = '',
    this.banners = const [],
    this.categories = const [],
    this.recommended = const [],
    this.latest = const [],
    this.latestPage = 0,
    this.hasMoreLatest = false,
    this.isLoadingMore = false,
  });

  /// Tên gọi trong lời chào: chữ cuối của họ tên (VD "Nguyễn Minh Anh" → "Anh")
  String get greetingName {
    final parts = (user?.fullName ?? '').trim().split(RegExp(r'\s+'));
    return parts.last;
  }

  HomeState copyWith({
    HomeStatus? status,
    UserModel? user,
    String? areaName,
    List<HomeBanner>? banners,
    List<CategoryModel>? categories,
    List<HomeListingItem>? recommended,
    List<HomeListingItem>? latest,
    int? latestPage,
    bool? hasMoreLatest,
    bool? isLoadingMore,
  }) => HomeState(
    status: status ?? this.status,
    user: user ?? this.user,
    areaName: areaName ?? this.areaName,
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
    status,
    user,
    areaName,
    banners,
    categories,
    recommended,
    latest,
    latestPage,
    hasMoreLatest,
    isLoadingMore,
  ];
}
