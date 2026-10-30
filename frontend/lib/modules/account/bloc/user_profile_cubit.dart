import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/profile_repository.dart';

class UserProfileState {
  const UserProfileState({
    this.profile,
    this.loading = true,
    this.saving = false,
    this.error,
  });
  final ProfileData? profile;
  final bool loading;
  final bool saving;
  final String? error;
}

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._repository) : super(const UserProfileState());
  final ProfileRepository _repository;

  Future<void> load() async {
    try {
      emit(
        UserProfileState(profile: await _repository.getMe(), loading: false),
      );
    } catch (_) {
      emit(
        const UserProfileState(loading: false, error: 'Không tải được hồ sơ.'),
      );
    }
  }

  Future<bool> update(Map<String, dynamic> changes) async {
    emit(
      UserProfileState(profile: state.profile, loading: false, saving: true),
    );
    try {
      final profile = await _repository.update(changes);
      emit(UserProfileState(profile: profile, loading: false));
      return true;
    } catch (_) {
      emit(
        UserProfileState(
          profile: state.profile,
          loading: false,
          error: 'Không lưu được hồ sơ.',
        ),
      );
      return false;
    }
  }
}
