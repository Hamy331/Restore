import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/profile_models.dart';
import '../../repositories/profile_repository.dart';
import 'follow_list_state.dart';

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
    // Xoá cờ lỗi cũ để lỗi lặp lại vẫn phát ra state mới.
    emit(state.copyWith());
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
