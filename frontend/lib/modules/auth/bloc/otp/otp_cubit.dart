import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'otp_state.dart';

class OtpCubit extends Cubit<OtpState> {
  OtpCubit() : super(const OtpState(secondsRemaining: 900)); // 15 mins

  Timer? _timer;

  void startTimer({int duration = 900}) {
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

  void resetTimer() {
    startTimer();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
