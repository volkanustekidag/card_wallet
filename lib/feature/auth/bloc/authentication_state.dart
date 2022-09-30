part of 'authentication_bloc.dart';

abstract class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object> get props => [];
}

class AuthenticationInitial extends AuthenticationState {}

class SuccessfulLoginState extends AuthenticationState {}

class FaiulerLoginState extends AuthenticationState {}

class RequiredRegisterState extends AuthenticationState {}

class RegisteringServiceState extends AuthenticationState {}
