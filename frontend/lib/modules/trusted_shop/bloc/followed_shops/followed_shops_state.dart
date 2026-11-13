import 'package:equatable/equatable.dart';

import '../../models/followed_shop.dart';

class FollowedShopsState extends Equatable {
  const FollowedShopsState({
    this.shops = const [],
    this.page = 0,
    this.hasMore = false,
    this.total = 0,
    this.loading = true,
    this.failed = false,
    this.actionFailed = false,
  });

  /// Shop đã bỏ theo dõi vẫn ở lại danh sách (nút chuyển thành "Theo dõi")
  /// tới lần tải lại sau, để lỡ tay bấm thì theo dõi lại được ngay.
  final List<FollowedShop> shops;
  final int page;
  final bool hasMore;

  /// Tổng số shop đang theo dõi theo API
  final int total;
  final bool loading, failed;

  /// Chỉ đúng ở một lần emit để thông báo lỗi hiện một lần
  final bool actionFailed;

  FollowedShopsState copyWith({
    List<FollowedShop>? shops,
    int? page,
    bool? hasMore,
    int? total,
    bool? loading,
    bool? failed,
    bool actionFailed = false,
  }) => FollowedShopsState(
    shops: shops ?? this.shops,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    total: total ?? this.total,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    actionFailed: actionFailed,
  );

  @override
  List<Object?> get props => [
    shops,
    page,
    hasMore,
    total,
    loading,
    failed,
    actionFailed,
  ];
}
