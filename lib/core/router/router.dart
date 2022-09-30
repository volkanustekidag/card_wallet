import 'package:fluro/fluro.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card.dart';
import 'package:wallet_app/feature/add_iban_card/add_iban_card.dart';
import 'package:wallet_app/feature/auth/authentication_page.dart';
import 'package:wallet_app/feature/change_pin/change_pin_page.dart';
import 'package:wallet_app/feature/credit_cards/credit_cards_page.dart';
import 'package:wallet_app/feature/home/home_page.dart';
import 'package:wallet_app/feature/iban_card/iban_cards_page.dart';
import 'package:wallet_app/feature/settings/settings_page.dart';
import 'package:wallet_app/feature/splash/splash.dart';

class RouterFluro {
  static FluroRouter fluroRouter = FluroRouter();

  static var splash = Handler(
    handlerFunc: (context, parameters) => Splash(),
  );

  static var auth = Handler(
    handlerFunc: (context, parameters) => AuthenticationPage(),
  );

  static var homePage = Handler(
    handlerFunc: (context, parameters) => HomePage(),
  );

  static var settings = Handler(
    handlerFunc: (context, parameters) => SettingsPage(),
  );

  static var changePin = Handler(
    handlerFunc: (context, parameters) => ChangePinPage(),
  );

  static var creditCards = Handler(
    handlerFunc: (context, parameters) => CreditCardsPage(),
  );

  static var ibanCards = Handler(
    handlerFunc: (context, parameters) => IbanCardsPage(),
  );

  static var addCreditCard = Handler(
    handlerFunc: (context, parameters) => AddCreditCard(),
  );

  static var addIbanCard = Handler(
    handlerFunc: (context, parameters) => AddIbanCard(),
  );

  static initRoutes() {
    fluroRouter.define(
      "/",
      handler: splash,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      "auth",
      handler: auth,
      transitionType: TransitionType.fadeIn,
    );
    fluroRouter.define(
      "home",
      handler: homePage,
      transitionType: TransitionType.inFromBottom,
    );
    fluroRouter.define(
      "settings",
      handler: settings,
      transitionType: TransitionType.inFromRight,
    );
    fluroRouter.define(
      "changePin",
      handler: changePin,
      transitionType: TransitionType.inFromRight,
    );
    fluroRouter.define(
      "creditCards",
      handler: creditCards,
      transitionType: TransitionType.inFromRight,
    );
    fluroRouter.define(
      "ibanCards",
      handler: ibanCards,
      transitionType: TransitionType.inFromRight,
    );
    fluroRouter.define(
      "addCreditCard",
      handler: addCreditCard,
      transitionType: TransitionType.inFromTop,
    );
    fluroRouter.define(
      "addIbanCard",
      handler: addIbanCard,
      transitionType: TransitionType.inFromBottom,
    );
  }
}
