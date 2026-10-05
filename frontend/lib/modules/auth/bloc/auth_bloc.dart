import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final user = await _authRepository.restoreSession();
      emit(
        user != null
            ? AuthAuthenticated(role: user['role'] as String? ?? 'USER')
            : AuthUnauthenticated(),
      );
    });
    on<LoggedIn>((event, emit) {
      emit(AuthAuthenticated(role: event.role));
    });
    on<LoggedOut>((event, emit) async {
      try {
        await _authRepository.logout();
      } finally {
        emit(AuthUnauthenticated());
      }
    });
  }

  final AuthRepository _authRepository;
}
