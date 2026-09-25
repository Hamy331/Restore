import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SubmitRegisterEvent extends RegisterEvent {
  final String email;
  final String password;
  final String username;
  final String fullName;

  SubmitRegisterEvent({
    required this.email,
    required this.password,
    required this.username,
    required this.fullName,
  });

  @override
  List<Object> get props => [email, password, username, fullName];
}