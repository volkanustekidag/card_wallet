part of 'authentication_bloc.dart';

abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthenticationEvent {
  final String password;

  const LoginEvent(this.password);

  @override
  List<Object> get props => [password];
}

class RegisterEvent extends AuthenticationEvent {
  final String password;

  const RegisterEvent(this.password);

  @override
  List<Object> get props => [password];
}

class CheckHavePasswordEvent extends AuthenticationEvent {
  @override
  List<Object> get props => [];
}
