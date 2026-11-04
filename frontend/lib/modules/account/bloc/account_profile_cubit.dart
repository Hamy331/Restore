import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/enums/listing_status.dart';
import '../../../shared/models/paged_result.dart';
import '../../listings/repositories/listings_repository.dart';

enum AccountListingStatus {
  visible(ListingStatus.available),
  pending(ListingStatus.pending),
  hidden(ListingStatus.hidden);

  const AccountListingStatus(this.listingStatus);
  final ListingStatus listingStatus;
}

class AccountListing {
  const AccountListing({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.views,
    required this.image,
    this.createdAt,
    this.status = AccountListingStatus.visible,
  });

  final String id;
  final String title;
  final int price;
  final String category;
  final DateTime? createdAt;
  final int views;
  final String image;
  final AccountListingStatus status;

  AccountListing withStatus(AccountListingStatus value) => AccountListing(
    id: id,
    title: title,
    price: price,
    category: category,
    createdAt: createdAt,
    views: views,
    image: image,
    status: value,
  );
}

/// Nguồn tin đăng của tài khoản; bản API bọc [ListingsRepository], bản mẫu
/// nằm ở `data/account_mock_listings.dart`.
abstract class AccountListingsSource {
  Future<PagedResult<AccountListing>> mine(
    AccountListingStatus status, {
    int page = 1,
  });
  Future<void> changeStatus(String id, AccountListingStatus status);
}

class ApiAccountListingsSource implements AccountListingsSource {
  ApiAccountListingsSource(this._repository);
  final ListingsRepository _repository;

  @override
  Future<PagedResult<AccountListing>> mine(
    AccountListingStatus status, {
    int page = 1,
  }) async {
    final result = await _repository.mine(
      page: page,
      status: status.listingStatus.apiValue,
    );
    return PagedResult(
      page: result.page,
      hasMore: result.hasMore,
      totalItems: result.totalItems,
      items: [
        for (final item in result.items)
          AccountListing(
            id: item.id,
            title: item.title,
            price: item.price ?? 0,
            category: item.categoryName,
            createdAt: item.createdAt,
            views: item.viewCount,
            image: item.coverImage ?? '',
            status: status,
          ),
      ],
    );
  }

  @override
  Future<void> changeStatus(String id, AccountListingStatus status) =>
      _repository.changeStatus(id, status.listingStatus);
}

class AccountListingsTab {
  const AccountListingsTab({
    this.items = const [],
    this.page = 0,
    this.hasMore = false,
    this.total = 0,
  });
  final List<AccountListing> items;
  final int page;
  final bool hasMore;
  final int total;
}

enum AccountListingsError { load, update }

class AccountProfileState {
  const AccountProfileState({
    this.tabs = const {},
    this.selected = AccountListingStatus.visible,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final Map<AccountListingStatus, AccountListingsTab> tabs;
  final AccountListingStatus selected;
  final bool loading;
  final bool loadingMore;
  final AccountListingsError? error;

  int count(AccountListingStatus status) => tabs[status]?.total ?? 0;

  List<AccountListing> get displayed => tabs[selected]?.items ?? const [];

  AccountProfileState copyWith({
    Map<AccountListingStatus, AccountListingsTab>? tabs,
    AccountListingStatus? selected,
    bool? loading,
    bool? loadingMore,
    AccountListingsError? error,
  }) => AccountProfileState(
    tabs: tabs ?? this.tabs,
    selected: selected ?? this.selected,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
  );
}

/// Tin đăng của tôi: mỗi tab tải trang đầu để lấy số lượng, cuộn tới cuối
/// thì tải thêm trang tiếp theo của tab đang chọn.
class AccountProfileCubit extends Cubit<AccountProfileState> {
  AccountProfileCubit(this._source) : super(const AccountProfileState());

  final AccountListingsSource _source;

  AccountListingsTab _tab(PagedResult<AccountListing> result) =>
      AccountListingsTab(
        items: result.items,
        page: result.page,
        hasMore: result.hasMore,
        total: result.totalItems ?? result.items.length,
      );

  Future<void> load() async {
    try {
      final results = await Future.wait([
        for (final status in AccountListingStatus.values) _source.mine(status),
      ]);
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          tabs: {
            for (final status in AccountListingStatus.values)
              status: _tab(results[status.index]),
          },
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(loading: false, error: AccountListingsError.load));
      }
    }
  }

  Future<void> loadMore() async {
    final status = state.selected, tab = state.tabs[status];
    if (tab == null || !tab.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final result = await _source.mine(status, page: tab.page + 1);
      if (isClosed) return;
      final ids = tab.items.map((item) => item.id).toSet();
      emit(
        state.copyWith(
          loadingMore: false,
          tabs: {
            ...state.tabs,
            status: AccountListingsTab(
              items: [
                ...tab.items,
                ...result.items.where((item) => !ids.contains(item.id)),
              ],
              page: result.page,
              hasMore: result.hasMore,
              total: result.totalItems ?? tab.total,
            ),
          },
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(loadingMore: false, error: AccountListingsError.load),
        );
      }
    }
  }

  void select(AccountListingStatus status) =>
      emit(state.copyWith(selected: status));

  /// Chuyển tin sang tab mới ngay trên giao diện sau khi API thành công.
  Future<void> setStatus(String id, AccountListingStatus status) async {
    AccountListing? item;
    for (final tab in state.tabs.values) {
      for (final listing in tab.items) {
        if (listing.id == id) item = listing;
      }
    }
    if (item == null || item.status == status) return;
    try {
      await _source.changeStatus(id, status);
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: AccountListingsError.update));
      return;
    }
    if (isClosed) return;
    final from = state.tabs[item.status] ?? const AccountListingsTab();
    final to = state.tabs[status] ?? const AccountListingsTab();
    emit(
      state.copyWith(
        tabs: {
          ...state.tabs,
          item.status: AccountListingsTab(
            items: from.items.where((listing) => listing.id != id).toList(),
            page: from.page,
            hasMore: from.hasMore,
            total: from.total - 1,
          ),
          status: AccountListingsTab(
            items: [item.withStatus(status), ...to.items],
            page: to.page,
            hasMore: to.hasMore,
            total: to.total + 1,
          ),
        },
      ),
    );
  }
}
