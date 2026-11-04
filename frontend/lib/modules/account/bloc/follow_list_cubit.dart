import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/profile_repository.dart';

class FollowListState {
  const FollowListState({
    this.users = const [],
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failed = false,
    this.actionFailed = false,
  });
  final List<FollowUser> users;
  final int page;
  final bool hasMore, loading, failed, actionFailed;

  FollowListState copyWith({
    List<FollowUser>? users,
    int? page,
    bool? hasMore,
    bool? loading,
    bool? failed,
    bool actionFailed = false,
  }) => FollowListState(
    users: users ?? this.users,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failed: failed ?? this.failed,
    actionFailed: actionFailed,
  );
}

/// Danh sách người theo dõi hoặc đang theo dõi của [userId].
class FollowListCubit extends Cubit<FollowListState> {
  FollowListCubit(this._repository, this.userId, this.kind)
    : super(const FollowListState());
  final ProfileRepository _repository;
  final String userId;
  final FollowListKind kind;
  final Set<String> _pending = {};

  Future<void> load({bool more = false}) async {
    if (more && (!state.hasMore || state.loading)) return;
    final page = more ? state.page + 1 : 1;
    emit(state.copyWith(loading: true, failed: false));
    try {
      final result = await _repository.follows(userId, kind, page: page);
      if (isClosed) return;
      emit(
        FollowListState(
          users: [if (more) ...state.users, ...result.items],
          page: page,
          hasMore: result.hasMore,
          loading: false,
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loading: false, failed: !more));
    }
  }

  Future<void> toggleFollow(FollowUser user) async {
    if (user.isMe || !_pending.add(user.id)) return;
    final value = !user.isFollowing;
    try {
      value
          ? await _repository.follow(user.id)
          : await _repository.unfollow(user.id);
      if (isClosed) return;
      emit(
        state.copyWith(
          users: [
            for (final u in state.users)
              u.id == user.id ? u.copyWith(isFollowing: value) : u,
          ],
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(actionFailed: true));
    } finally {
      _pending.remove(user.id);
    }
  }
}
