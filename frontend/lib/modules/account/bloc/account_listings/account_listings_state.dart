import 'package:equatable/equatable.dart';
import '../../models/account_listing.dart';

class AccountListingsTab extends Equatable {
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

  @override
  List<Object?> get props => [items, page, hasMore, total];
}

enum AccountListingsError { load, update }

class AccountListingsState extends Equatable {
  const AccountListingsState({
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

  /// [error] không được giữ qua các lần emit để snackbar chỉ hiện một lần.
  AccountListingsState copyWith({
    Map<AccountListingStatus, AccountListingsTab>? tabs,
    AccountListingStatus? selected,
    bool? loading,
    bool? loadingMore,
    AccountListingsError? error,
  }) => AccountListingsState(
    tabs: tabs ?? this.tabs,
    selected: selected ?? this.selected,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
  );

  @override
  List<Object?> get props => [tabs, selected, loading, loadingMore, error];
}
