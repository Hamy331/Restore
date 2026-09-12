import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthUnauthenticated());
    });

    on<LoggedIn>((event, emit) {
      emit(AuthAuthenticated());
    });

    on<LoggedOut>((event, emit) {
      emit(AuthUnauthenticated());
    });
  }
}
