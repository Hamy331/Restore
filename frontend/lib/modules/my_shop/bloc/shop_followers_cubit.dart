import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/modules/trusted_shop/models/followed_shop.dart';
import 'package:restore/modules/trusted_shop/repositories/shop_following_repository.dart';

class ShopFollowersState extends Equatable {
  const ShopFollowersState({
    this.followers = const [],
    this.page = 0,
    this.hasMore = false,
    this.total = 0,
    this.loading = true,
    this.failed = false,
  });

  final List<ShopFollower> followers;
  final int page;
  final bool hasMore;
  final int total;
  final bool loading, failed;

  ShopFollowersState copyWith({bool? loading, bool? failed}) =>
      ShopFollowersState(
        followers: followers,
        page: page,
        hasMore: hasMore,
        total: total,
        loading: loading ?? this.loading,
        failed: failed ?? this.failed,
      );

  @override
  List<Object?> get props => [followers, page, hasMore, total, loading, failed];
}

/// Người đang theo dõi shop của mình, theo dõi gần nhất trước
class ShopFollowersCubit extends Cubit<ShopFollowersState> {
  ShopFollowersCubit(this._repository) : super(const ShopFollowersState());

  final ShopFollowingRepository _repository;

  Future<void> load({bool more = false}) async {
    if (more && (!state.hasMore || state.loading)) return;
    final page = more ? state.page + 1 : 1;
    emit(state.copyWith(loading: true, failed: false));
    try {
      final result = await _repository.myFollowers(page: page);
      if (isClosed) return;
      emit(
        ShopFollowersState(
          followers: [if (more) ...state.followers, ...result.items],
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
}
