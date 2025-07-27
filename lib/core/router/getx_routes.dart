import 'package:get/get.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';
import 'package:wallet_app/feature/add_iban_card/add_iban_card_page.dart';
import 'package:wallet_app/feature/auth/authentication_page.dart';
import 'package:wallet_app/feature/change_pin/change_pin_page.dart';
import 'package:wallet_app/feature/credit_cards/credit_cards_page.dart';
import 'package:wallet_app/feature/home/home_page.dart';
import 'package:wallet_app/feature/iban_card/iban_cards_page.dart';
import 'package:wallet_app/feature/premium/premium_page.dart';
import 'package:wallet_app/feature/settings/settings_page.dart';
import 'package:wallet_app/feature/splash/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String changePin = '/changePin';
  static const String creditCards = '/creditCards';
  static const String ibanCards = '/ibanCards';
  static const String addCreditCard = '/addCreditCard';
  static const String addIbanCard = '/addIbanCard';
  static const String premium = '/premium';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => SplashPage(),
      binding: AppBindings(),
    ),
    GetPage(
      name: auth,
      page: () => const AuthenticationPage(),
      binding: AuthBindings(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: HomeBindings(),
      transition: Transition.upToDown,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: changePin,
      page: () => ChangePinPage(),
      binding: ChangePinBindings(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: creditCards,
      page: () => const CreditCardsPage(),
      binding: CreditCardBindings(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: ibanCards,
      page: () => const IbanCardsPage(),
      binding: IbanCardBindings(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: addCreditCard,
      page: () => const AddCreditCardPage(),
      binding: AddCreditCardBindings(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: addIbanCard,
      page: () => const AddIbanCardPage(),
      binding: AddIbanCardBindings(),
      transition: Transition.upToDown,
    ),
    GetPage(
      name: changePin,
      page: () => ChangePinPage(),
      binding: ChangePinBindings(),
      transition: Transition.upToDown,
    ),
    GetPage(
      name: premium,
      page: () => const PremiumPage(),
      transition: Transition.rightToLeft,
    ),
  ];
}
