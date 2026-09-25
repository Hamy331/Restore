import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc(this._authRepository) : super(RegisterInitial()) {
    on<SubmitRegisterEvent>(_onSubmitRegister);
  }

  Future<void> _onSubmitRegister(
    SubmitRegisterEvent event,
    Emitter<RegisterState> emit,
  ) async {
    if (event.email.isEmpty ||
        event.password.isEmpty ||
        event.username.isEmpty ||
        event.fullName.isEmpty) {
      emit(RegisterFailure('Please fill in all required fields.'));
      return;
    }

    emit(RegisterLoading());

    try {
      await _authRepository.register(
        email: event.email,
        password: event.password,
        username: event.username,
        fullName: event.fullName,
      );
      emit(RegisterSuccess());
    } catch (e) {
      emit(RegisterFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
