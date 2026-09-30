import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  const LoggedIn({required this.role});

  final String role;

  @override
  List<Object> get props => [role];
}

class LoggedOut extends AuthEvent {}
