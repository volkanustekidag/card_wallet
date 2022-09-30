import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/constants/provider_list.dart';
import 'package:wallet_app/core/router/router.dart';
import 'package:wallet_app/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/data/local_services/card_services/iban_card_service.dart';
import 'package:wallet_app/data/local_services/auth_services/authentication_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();
  await CreditCardService().init();
  await IbanCardService().init();
  await AuthenticationService().init();

  RouterFluro.initRoutes();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale("tr", "TR"),
        Locale("en", "US"),
      ],
      saveLocale: true,
      path: "assets/docs/lang",
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: ProviderList().providers,
      child: Sizer(
        builder: (context, orientation, deviceType) => MaterialApp(
          initialRoute: "/",
          onGenerateRoute: RouterFluro.fluroRouter.generator,
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          title: 'Card Wallet',
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
