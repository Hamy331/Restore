import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/trusted_shop/models/trusted_shop_item.dart';
import 'package:restore/shared/models/paged_result.dart';

import '../models/search_user_item.dart';

import '../repositories/search_repository.dart';
import 'search_accounts_state.dart';
import 'search_results_state.dart';

/// Tab Cửa hàng, Người dùng (và dải cửa hàng ở tab Tin đăng) của trang kết quả
class SearchAccountsCubit extends Cubit<SearchAccountsState> {
  SearchAccountsCubit({
    required SearchRepository searchRepository,
    required String query,
  }) : _repository = searchRepository,
       super(SearchAccountsState(query: query));

  final SearchRepository _repository;

  @override
  void emit(SearchAccountsState state) {
    // Bỏ qua kết quả về muộn sau khi trang đã đóng
    if (!isClosed) super.emit(state);
  }

  /// Tải trang đầu của cả hai danh sách
  Future<void> start() => Future.wait([reloadShops(), reloadUsers()]);

  /// [showLoading] false khi kéo để làm mới (giữ danh sách cũ tới khi có mới)
  Future<void> reloadShops({bool showLoading = true}) => _reload(
    load: (page) => _repository.searchShops(state.query, page: page),
    get: () => state.shops,
    set: (list) => emit(state.copyWith(shops: list)),
    showLoading: showLoading,
  );

  Future<void> reloadUsers({bool showLoading = true}) => _reload(
    load: (page) => _repository.searchUsers(state.query, page: page),
    get: () => state.users,
    set: (list) => emit(state.copyWith(users: list)),
    showLoading: showLoading,
  );

  Future<void> loadMoreShops() => _loadMore(
    load: (page) => _repository.searchShops(state.query, page: page),
    get: () => state.shops,
    set: (list) => emit(state.copyWith(shops: list)),
  );

  Future<void> loadMoreUsers() => _loadMore(
    load: (page) => _repository.searchUsers(state.query, page: page),
    get: () => state.users,
    set: (list) => emit(state.copyWith(users: list)),
  );

  /// Theo dõi / bỏ theo dõi shop ngay trên UI, lỗi API thì trả lại như cũ
  Future<void> toggleShopFollowing(TrustedShopItem item) async {
    final id = item.shop.id;
    final following = !item.isFollowing;
    syncShopFollowing(id, following);
    try {
      await _repository.setShopFollowing(id, following);
    } catch (_) {
      syncShopFollowing(id, !following);
    }
  }

  /// Theo dõi / bỏ theo dõi người dùng ngay trên UI, lỗi API thì trả lại
  Future<void> toggleUserFollowing(SearchUserItem user) async {
    final following = !user.isFollowing;
    syncUserFollowing(user.id, following);
    try {
      await _repository.setUserFollowing(user.id, following);
    } catch (_) {
      syncUserFollowing(user.id, !following);
    }
  }

  void syncUserFollowing(String userId, bool following) => emit(
    state.copyWith(
      users: state.users.copyWith(
        items: [
          for (final user in state.users.items)
            user.id == userId ? user.withFollowing(following) : user,
        ],
      ),
    ),
  );

  /// Cập nhật trạng thái theo dõi sau khi đổi ở trang shop
  void syncShopFollowing(String shopId, bool following) => emit(
    state.copyWith(
      shops: state.shops.copyWith(
        items: [
          for (final item in state.shops.items)
            item.shop.id == shopId ? item.withFollowing(following) : item,
        ],
      ),
    ),
  );

  Future<void> _reload<T>({
    required Future<PagedResult<T>> Function(int page) load,
    required SearchAccountList<T> Function() get,
    required void Function(SearchAccountList<T>) set,
    required bool showLoading,
  }) async {
    if (showLoading) {
      set(
        get().copyWith(
          status: SearchResultsStatus.loading,
          isLoadingMore: false,
        ),
      );
    }
    try {
      final result = await load(1);
      set(
        get().copyWith(
          status: SearchResultsStatus.ready,
          items: result.items,
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      // Làm mới thất bại thì giữ nội dung đang có
      final current = get();
      if (showLoading || current.status != SearchResultsStatus.ready) {
        set(current.copyWith(status: SearchResultsStatus.failure));
      }
    }
  }

  Future<void> _loadMore<T>({
    required Future<PagedResult<T>> Function(int page) load,
    required SearchAccountList<T> Function() get,
    required void Function(SearchAccountList<T>) set,
  }) async {
    final current = get();
    if (current.status != SearchResultsStatus.ready ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    set(current.copyWith(isLoadingMore: true));
    try {
      final result = await load(current.page + 1);
      final latest = get();
      set(
        latest.copyWith(
          items: [...latest.items, ...result.items],
          page: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      set(get().copyWith(isLoadingMore: false));
    }
  }
}
