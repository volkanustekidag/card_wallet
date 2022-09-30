part of 'change_pin_bloc.dart';

abstract class ChangePinState extends Equatable {
  const ChangePinState();

  @override
  List<Object> get props => [];
}

class ChangePinInitial extends ChangePinState {}

class CurrentPinVerificationState extends ChangePinState {}

class FaiulerState extends ChangePinState {}

class SaveNewPinState extends ChangePinState {}

class CompletedState extends ChangePinState {}
