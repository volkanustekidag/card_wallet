part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class LoadedHomeContent extends HomeState {
  final List<IbanCard> ibanCardList;
  final List<CreditCard> creditCardList;

  const LoadedHomeContent(this.creditCardList, this.ibanCardList);

  @override
  List<Object> get props => [ibanCardList, creditCardList];
}
