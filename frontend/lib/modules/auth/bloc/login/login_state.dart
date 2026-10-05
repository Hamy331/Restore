import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  LoginSuccess(this.role);

  final String role;

  @override
  List<Object> get props => [role];
}

class LoginFailure extends LoginState {
  final String error;
  final String? code;
  LoginFailure(this.error, {this.code});

  @override
  List<Object> get props => [error, if (code != null) code!];
}
