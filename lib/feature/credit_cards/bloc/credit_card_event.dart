part of 'credit_card_bloc.dart';

abstract class CreditCardEvent extends Equatable {
  const CreditCardEvent();

  @override
  List<Object> get props => [];
}

class CreditCardInitialEvent extends CreditCardEvent {}

class LoadCreditCardsEvent extends CreditCardEvent {}

class RemoveCreditCardsEvent extends CreditCardEvent {
  final CreditCard creditCard;

  const RemoveCreditCardsEvent(this.creditCard);

  @override
  List<Object> get props => [creditCard];
}
