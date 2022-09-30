import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/data/local_services/card_services/iban_card_service.dart';
import 'package:wallet_app/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';
import 'package:equatable/equatable.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CreditCardService _creditCardServices;
  final IbanCardService _ibanCardServices;
  HomeBloc(this._creditCardServices, this._ibanCardServices)
      : super(HomeInitial()) {
    on<LoadHomeContentEvent>((event, emit) async {
      await _creditCardServices.openBox();
      await _ibanCardServices.openBox();
      final creditCardList = await _creditCardServices.getAllCreditCards();
      final ibanCardList = await _ibanCardServices.getAllIbanCards();

      emit(LoadedHomeContent(creditCardList, ibanCardList));
    });
  }
}
