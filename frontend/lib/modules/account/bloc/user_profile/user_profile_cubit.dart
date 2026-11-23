import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/image_upload_service.dart';
import '../../repositories/profile_repository.dart';
import '../../models/profile_models.dart';
import 'user_profile_state.dart';

/// Hồ sơ của chính người dùng (tab Tài khoản). [initial] là thông tin của
/// người đang đăng nhập (AuthBloc) để hiện ngay trong lúc tải số liệu đầy đủ.
class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(
    this._repository, {
    ImageUploadService? uploader,
    ProfileData? initial,
  }) : _uploader = uploader,
       super(UserProfileState(profile: initial, loading: initial == null));
  final ProfileRepository _repository;
  final ImageUploadService? _uploader;
  int _revision = 0;

  /// Giữ hồ sơ đang hiển thị khi làm mới để không nháy "Đang tải…".
  Future<void> load() async {
    if (isClosed || state.saving) return;
    final revision = ++_revision;
    if (state.profile == null) emit(const UserProfileState());
    try {
      final profile = await _repository.getMe();
      if (!isClosed && revision == _revision) {
        emit(UserProfileState(profile: profile, loading: false));
      }
    } catch (_) {
      if (!isClosed && revision == _revision) {
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
    if (isClosed || state.saving) return ProfileSaveResult.failed;
    _revision++;
    emit(
      UserProfileState(profile: state.profile, loading: false, saving: true),
    );
    try {
      final updated = await _repository.update(changes);
      final profile = updated.copyWith(
        email: updated.email ?? state.profile?.email,
        phone: updated.phone ?? state.profile?.phone,
        clearPhone: changes.containsKey('phone') && changes['phone'] == null,
      );
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
        'INVALID_PHONE' => ProfileSaveResult.invalidPhone,
        _ => ProfileSaveResult.failed,
      };
    }
  }

  /// Gửi mã OTP tới [email] mới; trả số giây phải chờ trước khi gửi lại.
  /// Lỗi (sai mật khẩu, email đã có người dùng...) ném [ProfileUpdateException].
  Future<int> requestEmailChange(String email, String password) =>
      _repository.requestEmailChange(email, password);

  /// Nhập đúng [otp] thì đổi email trên hồ sơ đang hiển thị, trả email mới
  Future<String> verifyEmailChange(String otp) async {
    final email = await _repository.verifyEmailChange(otp);
    final profile = state.profile;
    if (!isClosed && profile != null) {
      emit(
        UserProfileState(
          profile: profile.copyWith(email: email),
          loading: false,
        ),
      );
    }
    return email;
  }

  /// Tải ảnh đại diện đã cắt lên và trả về URL để lưu cùng các trường khác.
  Future<String> uploadAvatar(Uint8List bytes) =>
      (_uploader ?? ImageUploadService()).uploadBytes(
        bytes,
        purpose: ImagePurpose.avatar,
      );
}
