import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wallet_app/data/local_services/auth_services/authentication_service.dart';

part 'change_pin_event.dart';
part 'change_pin_state.dart';

class ChangePinBloc extends Bloc<ChangePinEvent, ChangePinState> {
  final AuthenticationService _authenticationService;
  ChangePinBloc(this._authenticationService)
      : super(
          ChangePinInitial(),
        ) {
    on<CurrentPinVerificationEvent>((event, emit) async {
      await _authenticationService.openBox();

      final result = await _authenticationService.authenticate(event.pin);

      if (result == true) {
        emit(SaveNewPinState());
      } else {
        emit(FaiulerState());
      }
    });
    on<SaveNewPinEvent>((event, emit) async {
      await _authenticationService.updatePin(event.newPin);
      emit(CompletedState());
    });
  }
}
