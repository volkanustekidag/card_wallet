part of 'iban_card_bloc.dart';

abstract class IbanCardState extends Equatable {
  const IbanCardState();

  @override
  List<Object> get props => [];
}

class IbanCardInitial extends IbanCardState {}

class IbanCardLoadedState extends IbanCardState {
  final List<IbanCard> ibanCardList;

  // ignore: prefer_const_constructors_in_immutables
  IbanCardLoadedState(this.ibanCardList);

  @override
  List<Object> get props => [ibanCardList];
}

class RemoveIbanCardsState extends IbanCardState {}
