import 'package:wallet_app/data/local_services/auth_services/authentication_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationService _authenticationService;
  AuthenticationBloc(this._authenticationService)
      : super(
          RegisteringServiceState(),
        ) {
    on<LoginEvent>((event, emit) async {
      final result = await _authenticationService.authenticate(event.password);
      if (result == true) {
        emit(
          SuccessfulLoginState(),
        );
      } else {
        emit(
          FaiulerLoginState(),
        );
      }
    });

    on<RegisterEvent>((event, emit) {
      _authenticationService.creatPassword(event.password);
      emit(
        AuthenticationInitial(),
      );
    });

    on<CheckHavePasswordEvent>((event, emit) async {
      await _authenticationService.openBox();
      final result = await _authenticationService.checkHavePassword();

      if (result == null) {
        emit(
          RequiredRegisterState(),
        );
      } else {
        emit(
          AuthenticationInitial(),
        );
      }
    });
  }
}
