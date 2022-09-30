import 'package:wallet_app/data/local_services/card_services/iban_card_service.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'add_iban_card_event.dart';
part 'add_iban_card_state.dart';

class AddIbanCardBloc extends Bloc<AddIbanCardEvent, AddIbanCardState> {
  final IbanCardService _ibanCardServices;
  AddIbanCardBloc(this._ibanCardServices)
      : super(
          SaveIbanCardState(
            IbanCard("", "", "", "", 1),
          ),
        ) {
    on<UpdateIbanCardEvent>((event, emit) {
      final currentState = state as SaveIbanCardState;

      if ("cardHolder" == event.fieldTitle) {
        currentState.ibanCard.cardHolder = event.value;
      } else if ("iban" == event.fieldTitle) {
        currentState.ibanCard.iban = event.value;
      } else if ("swiftCode" == event.fieldTitle) {
        currentState.ibanCard.swiftCode = event.value;
      } else if ("cardHolder" == event.fieldTitle) {
        currentState.ibanCard.cardHolder = event.value;
      } else if ("bankName" == event.fieldTitle) {
        currentState.ibanCard.bankName = event.value;
      }

      emit(
        UpdateIbanCardState(currentState.ibanCard),
      );
    });

    on<SaveIbanCardEvent>(
      ((event, emit) {
        emit(
          SaveIbanCardState(event.ibanCard),
        );
      }),
    );

    on<AddNewIbanCardEvent>(
      ((event, emit) async {
        await _ibanCardServices.openBox();

        final currentState = state as SaveIbanCardState;
        await _ibanCardServices.addIbanCard(currentState.ibanCard);
        emit(
          SaveIbanCardState(
            IbanCard("", "", "", "", 1),
          ),
        );
      }),
    );
  }
}
