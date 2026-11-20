import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/profile_repository.dart';
import 'public_profile_state.dart';
import '../../../trusted_shop/repositories/trusted_shop_repository.dart';

/// Trang hồ sơ của người khác (`/users/:id`).
class PublicProfileCubit extends Cubit<PublicProfileState> {
  PublicProfileCubit(this._repository, this.userId)
    : super(const PublicProfileState());
  final ProfileRepository _repository;
  final String userId;
  int _request = 0;

  Future<void> load() async {
    if (state.following || isClosed) return;
    final request = ++_request;
    if (state.profile == null) emit(const PublicProfileState());
    try {
      final profile = await _repository.getUser(userId);
      if (!isClosed && request == _request) {
        emit(PublicProfileState(profile: profile, loading: false));
      }
    } catch (_) {
      if (!isClosed && request == _request) {
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
    if (isClosed || profile == null || state.following) return;
    _request++;
    emit(PublicProfileState(profile: profile, loading: false, following: true));
    final value = !profile.followsSeller;
    final shop = profile.storefront;
    try {
      if (shop.verified) {
        await ApiTrustedShopRepository().setFollowing(shop.shopId!, value);
      } else if (value) {
        await _repository.follow(userId);
      } else {
        await _repository.unfollow(userId);
      }
      if (isClosed) return;
      emit(
        PublicProfileState(
          loading: false,
          profile: shop.verified
              ? profile.copyWith(storefront: shop.withShopFollow(value))
              : profile.copyWith(
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
