import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restore/data/models/user_model.dart';

import 'auth_bloc.dart';
import 'auth_state.dart';

/// Đọc người dùng đang đăng nhập ở bất kỳ widget nào (AuthBloc cấp ở main.dart)
extension AuthContext on BuildContext {
  /// Người dùng hiện tại, `null` nếu là khách. Widget tự build lại khi đăng
  /// nhập, đăng xuất hoặc thông tin người dùng đổi. Chỉ gọi trong `build`.
  UserModel? watchUser() =>
      select<AuthBloc, UserModel?>((bloc) => _userOf(bloc.state));

  /// Người dùng tại thời điểm gọi (dùng trong callback, không build lại)
  UserModel? get currentUser => _userOf(read<AuthBloc>().state);

  bool get isSignedIn => currentUser != null;
}

UserModel? _userOf(AuthState state) =>
    state is AuthAuthenticated ? state.user : null;
