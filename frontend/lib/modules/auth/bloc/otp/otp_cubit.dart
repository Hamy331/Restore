import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  final AuthRepository? _authRepository;

  OtpCubit([this._authRepository])
    : super(const OtpState(secondsRemaining: 60));

  Timer? _timer;

  void startTimer({int duration = 60}) {
    _timer?.cancel();
    emit(OtpState(secondsRemaining: duration));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 0) {
        emit(OtpState(secondsRemaining: state.secondsRemaining - 1));
      } else {
        timer.cancel();
      }
    });
  }

  void resetTimer() => startTimer();

  Future<void> resendOtp(String email) async {
    await _authRepository!.resendRegistrationOtp(email);
    startTimer();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
