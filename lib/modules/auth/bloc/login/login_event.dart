import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

// Sự kiện khi người dùng bấm nút "Đăng nhập"
class SubmitLoginEvent extends LoginEvent {
  final String email;
  final String password;

  const SubmitLoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}