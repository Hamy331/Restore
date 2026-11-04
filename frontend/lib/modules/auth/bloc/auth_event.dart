import 'package:equatable/equatable.dart';
import 'package:restore/data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Kiểm tra phiên đã lưu: lúc mở app, và sau khi xác minh email (token vừa được lưu)
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Đăng nhập thành công (phiên đã được lưu bởi AuthRepository)
class LoggedIn extends AuthEvent {
  const LoggedIn(this.user);

  final UserModel user;

  @override
  List<Object?> get props => [user];
}

class LoggedOut extends AuthEvent {
  const LoggedOut();
}

/// ApiClient báo refresh token hết hạn hoặc bị thu hồi
class SessionExpired extends AuthEvent {
  const SessionExpired();
}
