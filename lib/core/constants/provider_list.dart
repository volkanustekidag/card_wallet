import 'package:wallet_app/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/data/local_services/card_services/iban_card_service.dart';
import 'package:wallet_app/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/feature/add_credit_card/bloc/add_credit_bloc.dart';
import 'package:wallet_app/feature/add_iban_card/bloc/add_iban_card_bloc.dart';
import 'package:wallet_app/feature/auth/bloc/authentication_bloc.dart';
import 'package:wallet_app/feature/change_pin/bloc/change_pin_bloc.dart';
import 'package:wallet_app/feature/credit_cards/bloc/credit_card_bloc.dart';
import 'package:wallet_app/feature/home/bloc/home_bloc.dart';
import 'package:wallet_app/feature/iban_card/bloc/iban_card_bloc.dart';
import 'package:flutter_bloc/src/bloc_provider.dart';

class ProviderList {
  final List<BlocProviderSingleChildWidget> providers = [
    BlocProvider(
      create: (_) => AuthenticationBloc(AuthenticationService()),
    ),
    BlocProvider(
      create: (_) => IbanCardBloc(IbanCardService()),
    ),
    BlocProvider(
      create: (_) => AddCreditBloc(CreditCardService()),
    ),
    BlocProvider(
      create: (_) => CreditCardBloc(CreditCardService()),
    ),
    BlocProvider(create: (_) => AddIbanCardBloc(IbanCardService())),
    BlocProvider(
        create: (_) => HomeBloc(CreditCardService(), IbanCardService())),
    BlocProvider(
      create: (_) => ChangePinBloc(AuthenticationService()),
    ),
  ];
}
