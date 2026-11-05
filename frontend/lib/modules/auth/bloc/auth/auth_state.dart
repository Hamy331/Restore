import 'package:equatable/equatable.dart';
import 'package:restore/data/models/enums/user_role.dart';
import 'package:restore/data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Đang khôi phục phiên đã lưu (lúc mở app): router giữ người dùng ở /splash
class AuthChecking extends AuthState {
  const AuthChecking();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  /// Người đang đăng nhập; các trang khác dùng lại, không cần gọi /auth/me nữa
  final UserModel user;

  bool get isAdmin => user.role == UserRole.admin;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.sessionExpired = false});

  /// Bị đăng xuất vì phiên hết hạn (không phải người dùng tự đăng xuất):
  /// trang đăng nhập hiện thông báo
  final bool sessionExpired;

  @override
  List<Object?> get props => [sessionExpired];
}
