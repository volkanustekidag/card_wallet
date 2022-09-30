import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wallet_app/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/domain/models/credit_card_model/credit_card.dart';

part 'add_credit_event.dart';
part 'add_credit_state.dart';

class AddCreditBloc extends Bloc<AddCreditEvent, AddCreditState> {
  final CreditCardService _creditCardServices;

  AddCreditBloc(this._creditCardServices)
      : super(SaveCreditCardState(CreditCard(1, "", "", "", "", "", 1))) {
    on<UpdateCreditCardEvent>((event, emit) {
      final currentState = state as SaveCreditCardState;

      if ("cardColorId" == event.fieldTitle) {
        currentState.creditCard.cardColorId = event.value;
      } else if ("bankName" == event.fieldTitle) {
        currentState.creditCard.bankName = event.value;
      } else if ("creditCardNumber" == event.fieldTitle) {
        currentState.creditCard.creditCardNumber = event.value;
      } else if ("cardHolder" == event.fieldTitle) {
        currentState.creditCard.cardHolder = event.value;
      } else if ("expirationDate" == event.fieldTitle) {
        currentState.creditCard.expirationDate = event.value;
      } else if ("cvc2" == event.fieldTitle) {
        currentState.creditCard.cvc2 = event.value;
      }

      emit(UpdadeCreditCardState(currentState.creditCard));
    });

    on<SaveCreditCardEvent>(((event, emit) {
      emit(SaveCreditCardState(event.creditCard));
    }));

    on<AddNewCreditCardEvent>((event, emit) async {
      await _creditCardServices.openBox();
      final currentState = state as SaveCreditCardState;

      await _creditCardServices.addToCreditCard(currentState.creditCard);
      emit(SaveCreditCardState(CreditCard(1, "", "", "", "", "", 1)));
    });
  }
}
