import 'package:wallet_app/data/local_services/card_services/iban_card_service.dart';
import 'package:wallet_app/domain/models/iban_card_model/iban_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'iban_card_event.dart';
part 'iban_card_state.dart';

class IbanCardBloc extends Bloc<IbanCardEvent, IbanCardState> {
  final IbanCardService _ibanCardServices;
  IbanCardBloc(this._ibanCardServices) : super(IbanCardInitial()) {
    on<LoadIbanCardEvent>((event, emit) async {
      await _ibanCardServices.openBox();
      final result = await _ibanCardServices.getAllIbanCards();
      emit(IbanCardLoadedState(result));
    });

    on<RemoveIbanCardsEvent>(((event, emit) {
      _ibanCardServices.removeIbanCard(event.ibanCard);
      add(LoadIbanCardEvent());
    }));
  }
}
