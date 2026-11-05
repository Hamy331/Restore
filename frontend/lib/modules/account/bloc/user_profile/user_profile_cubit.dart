import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/image_upload_service.dart';
import '../../repositories/profile_repository.dart';
import 'user_profile_state.dart';

/// Hồ sơ của chính người dùng (tab Tài khoản).
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._repository, {ImageUploadService? uploader})
    : _uploader = uploader,
      super(const UserProfileState());
  final ProfileRepository _repository;
  final ImageUploadService? _uploader;

  /// Giữ hồ sơ đang hiển thị khi làm mới để không nháy "Đang tải…".
  Future<void> load() async {
    if (state.profile == null) emit(const UserProfileState());
    try {
      final profile = await _repository.getMe();
      if (!isClosed) emit(UserProfileState(profile: profile, loading: false));
    } catch (_) {
      if (!isClosed) {
        emit(
          UserProfileState(
            profile: state.profile,
            loading: false,
            failed: state.profile == null,
          ),
        );
      }
    }
  }

  Future<ProfileSaveResult> update(Map<String, dynamic> changes) async {
    emit(
      UserProfileState(profile: state.profile, loading: false, saving: true),
    );
    try {
      final profile = await _repository.update(changes);
      if (!isClosed) emit(UserProfileState(profile: profile, loading: false));
      return ProfileSaveResult.saved;
    } catch (error) {
      if (!isClosed) {
        emit(UserProfileState(profile: state.profile, loading: false));
      }
      final code = error is ProfileUpdateException ? error.code : null;
      return switch (code) {
        'USERNAME_TAKEN' => ProfileSaveResult.usernameTaken,
        'INVALID_USERNAME' => ProfileSaveResult.invalidUsername,
        _ => ProfileSaveResult.failed,
      };
    }
  }

  /// Tải ảnh lên và trả về URL để form lưu cùng các trường khác.
  Future<String> uploadAvatar(String path) =>
      (_uploader ?? ImageUploadService()).upload(
        path,
        purpose: ImagePurpose.avatar,
      );
}
