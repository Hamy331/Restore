import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Trạng thái đăng nhập của cả app.
///
/// Phiên luôn được ghi nhớ (60 ngày, tự gia hạn khi dùng app): mở app thì
/// [AuthCheckRequested] khôi phục phiên đã lưu. Router đọc state này để chuyển trang.
///
/// Đây là nơi duy nhất giữ người dùng hiện tại cho cả app; widget đọc qua
/// `context.watchUser()` / `context.currentUser` (auth_context.dart).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository, {Stream<void>? sessionExpired})
    : super(const AuthChecking()) {
    on<AuthCheckRequested>(_onCheck);
    on<LoggedIn>((event, emit) => emit(AuthAuthenticated(event.user)));
    on<LoggedOut>(_onLoggedOut);
    on<SessionExpired>((event, emit) {
      emit(AuthUnauthenticated(sessionExpired: state is AuthAuthenticated));
    });
    _sessionExpiredSubscription = sessionExpired?.listen(
      (_) => add(const SessionExpired()),
    );
  }

  final AuthRepository _authRepository;
  StreamSubscription<void>? _sessionExpiredSubscription;

  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Có người dùng lưu sẵn: vào app ngay, kiểm tra phiên với máy chủ ở phía sau
    final cached = await _authRepository.cachedUser();
    if (cached != null) emit(AuthAuthenticated(cached));
    final user = await _authRepository.restoreSession();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else if (state is! AuthUnauthenticated) {
      // Đang hiện người dùng lưu sẵn mà máy chủ từ chối phiên: báo hết hạn
      emit(AuthUnauthenticated(sessionExpired: cached != null));
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    try {
      await _authRepository.logout();
    } finally {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() async {
    await _sessionExpiredSubscription?.cancel();
    return super.close();
  }
}
