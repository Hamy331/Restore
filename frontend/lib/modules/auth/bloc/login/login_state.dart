import 'package:equatable/equatable.dart';
import 'package:restore/data/models/user_model.dart';

abstract class LoginState extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  LoginSuccess(this.user);

  final UserModel user;

  @override
  List<Object> get props => [user];
}

class LoginFailure extends LoginState {
  final String error;
  final String? code;
  LoginFailure(this.error, {this.code});

  @override
  List<Object> get props => [error, if (code != null) code!];
}
