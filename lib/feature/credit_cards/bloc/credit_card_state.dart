part of 'credit_card_bloc.dart';

abstract class CreditCardState extends Equatable {
  const CreditCardState();

  @override
  List<Object> get props => [];
}

class CreditCardInitial extends CreditCardState {}

// ignore: must_be_immutable
class CreditCardLoadedState extends CreditCardState {
  List<CreditCard> creditCardList;

  CreditCardLoadedState(this.creditCardList);

  @override
  List<Object> get props => [creditCardList];
}

class RemoveCreditCardsState extends CreditCardState {}
