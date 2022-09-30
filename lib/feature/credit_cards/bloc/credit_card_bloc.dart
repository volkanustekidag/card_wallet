import 'package:wallet_app/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/domain/models/credit_card_model/credit_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'credit_card_event.dart';
part 'credit_card_state.dart';

class CreditCardBloc extends Bloc<CreditCardEvent, CreditCardState> {
  final CreditCardService _creditCardServices;
  CreditCardBloc(this._creditCardServices) : super(CreditCardInitial()) {
    on<LoadCreditCardsEvent>((event, emit) async {
      await _creditCardServices.openBox();

      final result = await _creditCardServices.getAllCreditCards();
      emit(CreditCardLoadedState(result));
    });

    on<RemoveCreditCardsEvent>(((event, emit) {
      _creditCardServices.removeToCreditCard(event.creditCard);
      add(LoadCreditCardsEvent());
    }));
  }
}
