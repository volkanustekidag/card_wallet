import 'package:get/get.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/feature/add_credit_card/add_credit_card_page.dart';
import 'package:wallet_app/feature/add_iban_card/add_iban_card_page.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/auth/authentication_page.dart';
import 'package:wallet_app/feature/change_pin/change_pin_page.dart';
import 'package:wallet_app/feature/credit_cards/credit_cards_page.dart';
import 'package:wallet_app/feature/home/home_page.dart';
import 'package:wallet_app/feature/iban_card/iban_cards_page.dart';
import 'package:wallet_app/feature/loyalty_card/loyalty_cards_page.dart';
import 'package:wallet_app/feature/onboarding/onboarding_page.dart';
import 'package:wallet_app/feature/premium/premium_page.dart';
import 'package:wallet_app/feature/settings/settings_page.dart';
import 'package:wallet_app/feature/splash/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String changePin = '/changePin';
  static const String creditCards = '/creditCards';
  static const String ibanCards = '/ibanCards';
  static const String loyaltyCards = '/loyaltyCards';
  static const String addCreditCard = '/addCreditCard';
  static const String addIbanCard = '/addIbanCard';
  static const String addLoyaltyCard = '/addLoyaltyCard';
  static const String premium = '/premium';

  // Lighter than the default cupertino slide. The Material/Cupertino
  // slide-from-right path runs an opacity + scale + transform on the
  // entire incoming subtree; on a sliver-heavy home page that's tens of
  // ms per frame on Android. fadeIn renders a single Opacity over the
  // tree and lets us hit 60fps even when the destination is doing its
  // own initial layout.
  static const _kPageTransition = Transition.fadeIn;
  static const _kPageTransitionDuration = Duration(milliseconds: 220);

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => SplashPage(),
      binding: AppBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingPage(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: auth,
      page: () => const AuthenticationPage(),
      binding: AuthBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: HomeBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsPage(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: changePin,
      page: () => const ChangePinPage(),
      binding: ChangePinBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: creditCards,
      page: () => const CreditCardsPage(),
      binding: CreditCardBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: ibanCards,
      page: () => const IbanCardsPage(),
      binding: IbanCardBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: addCreditCard,
      page: () => const AddCreditCardPage(),
      binding: AddCreditCardBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: addIbanCard,
      page: () => const AddIbanCardPage(),
      binding: AddIbanCardBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: loyaltyCards,
      page: () => const LoyaltyCardsPage(),
      binding: LoyaltyCardBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: addLoyaltyCard,
      page: () => const AddLoyaltyCardPage(),
      binding: AddLoyaltyCardBindings(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
    GetPage(
      name: premium,
      page: () => const PremiumPage(),
      transition: _kPageTransition,
      transitionDuration: _kPageTransitionDuration,
    ),
  ];
}
