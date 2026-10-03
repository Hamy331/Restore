import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc(this._authRepository) : super(LoginInitial()) {
    on<SubmitLoginEvent>(_onSubmitLogin);
  }

  Future<void> _onSubmitLogin(
    SubmitLoginEvent event,
    Emitter<LoginState> emit,
  ) async {
    if (event.email.isEmpty || event.password.isEmpty) {
      emit(LoginFailure('Vui lòng nhập đầy đủ email và mật khẩu.'));
      return;
    }

    emit(LoginLoading());

    try {
      final user = await _authRepository.loginWithEmailAndPassword(
        event.email,
        event.password,
      );

      emit(LoginSuccess(user['role'] as String? ?? 'USER'));
    } on AuthException catch (e) {
      emit(LoginFailure(e.message, code: e.code));
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(LoginFailure(errorMessage));
    }
  }
}
