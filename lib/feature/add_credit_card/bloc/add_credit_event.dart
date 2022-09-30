// ignore_for_file: prefer_const_constructors_in_immutables, prefer_typing_uninitialized_variables

part of 'add_credit_bloc.dart';

abstract class AddCreditEvent extends Equatable {
  const AddCreditEvent();

  @override
  List<Object> get props => [];
}

class UpdateCreditCardEvent extends AddCreditEvent {
  final value;
  final fieldTitle;

  UpdateCreditCardEvent(this.value, this.fieldTitle);

  @override
  List<Object> get props => [value];
}

class SaveCreditCardEvent extends AddCreditEvent {
  final CreditCard creditCard;

  SaveCreditCardEvent(this.creditCard);

  @override
  List<Object> get props => [creditCard];
}

class AddNewCreditCardEvent extends AddCreditEvent {}
