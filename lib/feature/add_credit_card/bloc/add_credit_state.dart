part of 'add_credit_bloc.dart';

abstract class AddCreditState extends Equatable {
  const AddCreditState();

  @override
  List<Object> get props => [];
}

class UpdadeCreditCardState extends AddCreditState {
  final CreditCard creditCard;

  const UpdadeCreditCardState(this.creditCard);

  @override
  List<Object> get props => [creditCard];
}

class SaveCreditCardState extends AddCreditState {
  final CreditCard creditCard;

  const SaveCreditCardState(this.creditCard);

  @override
  List<Object> get props => [creditCard];
}

class AddNewCreditCardState extends AddCreditState {
  const AddNewCreditCardState();

  @override
  List<Object> get props => [];
}
