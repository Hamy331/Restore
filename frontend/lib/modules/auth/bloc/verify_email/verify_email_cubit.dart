import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'verify_email_state.dart';

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  final AuthRepository _authRepository;

  VerifyEmailCubit(this._authRepository) : super(VerifyEmailInitial());

  Future<void> verifyOtp(String email, String otp) async {
    if (otp.length != 6) {
      emit(const VerifyEmailFailure('Mã OTP không hợp lệ.'));
      return;
    }

    emit(VerifyEmailLoading());
    try {
      await _authRepository.verifyRegistrationOtp(email, otp);
      emit(VerifyEmailSuccess());
    } catch (e) {
      emit(VerifyEmailFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
