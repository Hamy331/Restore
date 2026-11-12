import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/followed_shop.dart';
import '../../repositories/shop_following_repository.dart';
import 'followed_shops_state.dart';

/// Shop mình đang theo dõi: tab "Shop" ở trang Đang theo dõi và dải shop ở
/// trang Shop uy tín.
class FollowedShopsCubit extends Cubit<FollowedShopsState> {
  FollowedShopsCubit(this._repository) : super(const FollowedShopsState());

  final ShopFollowingRepository _repository;
  final Set<String> _pending = {};

  Future<void> load({bool more = false}) async {
    if (more && (!state.hasMore || state.loading)) return;
    final page = more ? state.page + 1 : 1;
    emit(state.copyWith(loading: true, failed: false));
    try {
      final result = await _repository.followedShops(page: page);
      if (isClosed) return;
      emit(
        FollowedShopsState(
          shops: [if (more) ...state.shops, ...result.items],
          page: page,
          hasMore: result.hasMore,
          total: result.totalItems ?? result.items.length,
          loading: false,
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loading: false, failed: !more));
    }
  }

  /// Bỏ / theo dõi lại, cập nhật ngay rồi gọi API; lỗi thì trả về như cũ
  Future<void> toggleFollow(FollowedShop shop) async {
    if (!_pending.add(shop.id)) return;
    final following = !shop.item.isFollowing;
    sync(shop.id, following);
    try {
      await _repository.setFollowing(shop.id, following);
    } catch (_) {
      sync(shop.id, !following);
      if (!isClosed) emit(state.copyWith(actionFailed: true));
    } finally {
      _pending.remove(shop.id);
    }
  }

  /// Cập nhật trạng thái theo dõi khi đổi ở trang khác (VD trang của shop)
  void sync(String shopId, bool following) {
    if (isClosed) return;
    final index = state.shops.indexWhere((shop) => shop.id == shopId);
    if (index < 0 || state.shops[index].item.isFollowing == following) return;
    final shops = [...state.shops];
    shops[index] = shops[index].withFollowing(following);
    emit(
      state.copyWith(shops: shops, total: state.total + (following ? 1 : -1)),
    );
  }
}
