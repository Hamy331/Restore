import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/models/paged_result.dart';
import '../../models/account_listing.dart';
import '../../repositories/account_listings_repository.dart';
import 'account_listings_state.dart';

/// Tin đăng của tôi: mỗi tab tải trang đầu để lấy số lượng, cuộn tới cuối
/// thì tải thêm trang tiếp theo của tab đang chọn.
class AccountListingsCubit extends Cubit<AccountListingsState> {
  AccountListingsCubit(this._repository) : super(const AccountListingsState());

  final AccountListingsRepository _repository;

  /// Để màn hình lấy hạn mức / danh mục khi cần hỏi trả xu
  AccountListingsRepository get repository => _repository;

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
        for (final status in AccountListingStatus.values)
          _repository.mine(status),
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
      final result = await _repository.mine(status, page: tab.page + 1);
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

  /// Báo lỗi cập nhật tin (VD không tải được hạn mức trước khi gia hạn)
  void reportUpdateError() {
    if (!isClosed) emit(state.copyWith(error: AccountListingsError.update));
  }

  void select(AccountListingStatus status) =>
      emit(state.copyWith(selected: status));

  /// Chuyển tin sang tab mới ngay trên giao diện sau khi API thành công.
  /// Kích hoạt lại tin hết hạn thì tải lại để có hạn hiển thị mới.
  /// Backend từ chối có mã (hết suất, thiếu xu) thì ném lại
  /// [AccountListingActionException] để màn hình hỏi người dùng.
  Future<void> setStatus(
    String id,
    AccountListingStatus status, {
    bool payWithCredits = false,
  }) async {
    AccountListing? item;
    for (final tab in state.tabs.values) {
      for (final listing in tab.items) {
        if (listing.id == id) item = listing;
      }
    }
    if (item == null || item.status == status) return;
    try {
      await _repository.changeStatus(
        id,
        status,
        payWithCredits: payWithCredits,
      );
    } on AccountListingActionException {
      rethrow;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: AccountListingsError.update));
      return;
    }
    if (isClosed) return;
    if (item.isExpiredAt(DateTime.now())) {
      await load();
      return;
    }
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

  /// Gia hạn tin thêm [days] ngày bằng xu rồi tải lại để thấy hạn mới. Lỗi
  /// có mã (thiếu xu, vượt số ngày tối đa) ném [AccountListingActionException].
  Future<void> extend(String id, int days) async {
    try {
      await _repository.extend(id, days);
    } on AccountListingActionException {
      rethrow;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: AccountListingsError.update));
      return;
    }
    if (!isClosed) await load();
  }

  /// Bật/tắt tự gia hạn rồi tải lại. Lỗi có mã ném
  /// [AccountListingActionException].
  Future<void> setAutoExtend(String id, bool enabled) async {
    try {
      await _repository.setAutoExtend(id, enabled);
    } on AccountListingActionException {
      rethrow;
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: AccountListingsError.update));
      return;
    }
    if (!isClosed) await load();
  }
}
