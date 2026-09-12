import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<SubmitLoginEvent>((event, emit) async {
      emit(LoginLoading());
      
      try {
        // Giả lập gọi API kiểm tra tài khoản
        await Future.delayed(const Duration(seconds: 2));
        
        if (event.email == 'admin@restore.com' && event.password == '123456') {
          emit(LoginSuccess());
        } else {
          emit(LoginFailure('Email hoặc mật khẩu không chính xác'));
        }
      } catch (e) {
        emit(LoginFailure('Lỗi kết nối máy chủ'));
      }
    });
  }
}