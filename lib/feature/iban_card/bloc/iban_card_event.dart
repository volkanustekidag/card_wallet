part of 'iban_card_bloc.dart';

abstract class IbanCardEvent extends Equatable {
  const IbanCardEvent();

  @override
  List<Object> get props => [];
}

class LoadIbanCardEvent extends IbanCardEvent {}

class RemoveIbanCardsEvent extends IbanCardEvent {
  final IbanCard ibanCard;

  const RemoveIbanCardsEvent(this.ibanCard);

  @override
  List<Object> get props => [ibanCard];
}
