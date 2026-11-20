import 'package:equatable/equatable.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';

import '../models/search_user_item.dart';
import 'search_results_state.dart';

/// Một danh sách tài khoản có phân trang (tab Cửa hàng hoặc Người dùng)
class SearchAccountList<T> extends Equatable {
  final SearchResultsStatus status;
  final List<T> items;

  /// Trang cuối đã tải của [items]
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const SearchAccountList({
    this.status = SearchResultsStatus.loading,
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  SearchAccountList<T> copyWith({
    SearchResultsStatus? status,
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) => SearchAccountList(
    status: status ?? this.status,
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [status, items, page, hasMore, isLoadingMore];
}

/// Cửa hàng và người dùng khớp từ khoá ở trang kết quả
class SearchAccountsState extends Equatable {
  final String query;
  final SearchAccountList<TrustedShopItem> shops;
  final SearchAccountList<SearchUserItem> users;

  const SearchAccountsState({
    required this.query,
    this.shops = const SearchAccountList(),
    this.users = const SearchAccountList(),
  });

  SearchAccountsState copyWith({
    SearchAccountList<TrustedShopItem>? shops,
    SearchAccountList<SearchUserItem>? users,
  }) => SearchAccountsState(
    query: query,
    shops: shops ?? this.shops,
    users: users ?? this.users,
  );

  @override
  List<Object?> get props => [query, shops, users];
}
