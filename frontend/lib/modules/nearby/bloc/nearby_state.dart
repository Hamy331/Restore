import 'package:equatable/equatable.dart';
import 'package:restore/shared/models/listing_card_item.dart';
import 'package:restore/shared/models/listing_filter.dart';

import '../models/nearby_origin.dart';

enum NearbyStatus {
  /// Đang lấy vị trí, chưa có điểm gốc
  locating,

  /// Đang tải trang đầu (lần đầu hoặc vừa đổi bộ lọc)
  loading,
  ready,
  failure,
}

class NearbyState extends Equatable {
  /// Các mức bán kính cho người dùng chọn (km)
  static const List<double> radiusOptions = [2, 5, 10, 20];

  /// Cách sắp xếp trang hỗ trợ (không có "Phù hợp nhất" vì không có từ khoá)
  static const List<ListingSort> sortOptions = [
    ListingSort.nearest,
    ListingSort.newest,
    ListingSort.priceLow,
    ListingSort.priceHigh,
  ];

  static const ListingFilter defaultFilter = ListingFilter(
    sort: ListingSort.nearest,
    radiusKm: 5,
  );

  final NearbyStatus status;
  final NearbyOrigin? origin;
  final ListingFilter filter;
  final List<ListingCardItem> items;

  /// Trang cuối đã tải của [items]
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Đang lấy lại vị trí GPS theo yêu cầu (vẫn giữ danh sách cũ)
  final bool isRelocating;

  const NearbyState({
    this.status = NearbyStatus.locating,
    this.origin,
    this.filter = defaultFilter,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isRelocating = false,
  });

  /// Mức bán kính lớn hơn kế tiếp, để gợi ý khi không có tin nào
  double? get widerRadius {
    final current = filter.radiusKm;
    if (current == null) return null;
    for (final radius in radiusOptions) {
      if (radius > current) return radius;
    }
    return null;
  }

  NearbyState copyWith({
    NearbyStatus? status,
    NearbyOrigin? origin,
    ListingFilter? filter,
    List<ListingCardItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRelocating,
  }) => NearbyState(
    status: status ?? this.status,
    origin: origin ?? this.origin,
    filter: filter ?? this.filter,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isRelocating: isRelocating ?? this.isRelocating,
  );

  @override
  List<Object?> get props => [
    status,
    origin,
    filter,
    items,
    page,
    hasMore,
    isLoadingMore,
    isRelocating,
  ];
}
