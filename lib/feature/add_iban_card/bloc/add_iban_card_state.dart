part of 'add_iban_card_bloc.dart';

abstract class AddIbanCardState extends Equatable {
  const AddIbanCardState();

  @override
  List<Object> get props => [];
}

class AddIbanCardInitial extends AddIbanCardState {}

class SaveIbanCardState extends AddIbanCardState {
  final IbanCard ibanCard;

  const SaveIbanCardState(this.ibanCard);

  @override
  List<Object> get props => [ibanCard];
}

class UpdateIbanCardState extends AddIbanCardState {
  final IbanCard ibanCard;

  const UpdateIbanCardState(this.ibanCard);

  @override
  List<Object> get props => [ibanCard];
}

class AddNewIbanCardState extends AddIbanCardState {}
