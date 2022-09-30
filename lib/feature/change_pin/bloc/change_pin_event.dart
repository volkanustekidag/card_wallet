part of 'change_pin_bloc.dart';

abstract class ChangePinEvent extends Equatable {
  const ChangePinEvent();

  @override
  List<Object> get props => [];
}

class CurrentPinVerificationEvent extends ChangePinEvent {
  final String pin;

  const CurrentPinVerificationEvent(this.pin);

  @override
  List<Object> get props => [pin];
}

class SaveNewPinEvent extends ChangePinEvent {
    final String newPin;

  const SaveNewPinEvent(this.newPin);

  @override
  List<Object> get props => [newPin];
}
