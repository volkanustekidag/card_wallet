part of 'add_iban_card_bloc.dart';

abstract class AddIbanCardEvent extends Equatable {
  const AddIbanCardEvent();

  @override
  List<Object> get props => [];
}

class SaveIbanCardEvent extends AddIbanCardEvent {
  final IbanCard ibanCard;

  const SaveIbanCardEvent(this.ibanCard);

  @override
  List<Object> get props => [ibanCard];
}

class UpdateIbanCardEvent extends AddIbanCardEvent {
  final value;
  final fieldTitle;

  const UpdateIbanCardEvent(this.value, this.fieldTitle);

  @override
  List<Object> get props => [value, fieldTitle];
}

class AddNewIbanCardEvent extends AddIbanCardEvent {}
