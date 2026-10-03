import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.role});
  final String role;

  bool get isAdmin => role == 'ADMIN';

  @override
  List<Object> get props => [role];
}

class AuthUnauthenticated extends AuthState {}
