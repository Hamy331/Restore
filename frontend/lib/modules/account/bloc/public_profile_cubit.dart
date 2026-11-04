import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/profile_repository.dart';

class PublicProfileState {
  const PublicProfileState({
    this.profile,
    this.loading = true,
    this.failed = false,
    this.following = false,
    this.actionFailed = false,
  });
  final ProfileData? profile;
  final bool loading, failed;

  /// Đang gửi yêu cầu theo dõi / bỏ theo dõi.
  final bool following;
  final bool actionFailed;
}

/// Trang hồ sơ của người khác (`/users/:id`).
class PublicProfileCubit extends Cubit<PublicProfileState> {
  PublicProfileCubit(this._repository, this.userId)
    : super(const PublicProfileState());
  final ProfileRepository _repository;
  final String userId;

  Future<void> load() async {
    if (state.profile == null) emit(const PublicProfileState());
    try {
      final profile = await _repository.getUser(userId);
      if (!isClosed) emit(PublicProfileState(profile: profile, loading: false));
    } catch (_) {
      if (!isClosed) {
        emit(
          PublicProfileState(
            profile: state.profile,
            loading: false,
            failed: state.profile == null,
          ),
        );
      }
    }
  }

  Future<void> toggleFollow() async {
    final profile = state.profile;
    if (profile == null || state.following) return;
    emit(PublicProfileState(profile: profile, loading: false, following: true));
    final value = !profile.isFollowing;
    try {
      value
          ? await _repository.follow(userId)
          : await _repository.unfollow(userId);
      if (isClosed) return;
      emit(
        PublicProfileState(
          loading: false,
          profile: profile.copyWith(
            isFollowing: value,
            followerCount: profile.followerCount + (value ? 1 : -1),
          ),
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          PublicProfileState(
            profile: profile,
            loading: false,
            actionFailed: true,
          ),
        );
      }
    }
  }
}
