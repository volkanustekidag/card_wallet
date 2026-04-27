import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/feature/add_loyalty_card/controller/add_loyalty_card_controller.dart';
import 'package:wallet_app/core/controllers/change_pin_controller.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut<AuthenticationService>(() => AuthenticationService());
    Get.lazyPut<BiometricService>(() => BiometricService());
    Get.lazyPut<CreditCardService>(() => CreditCardService());
    Get.lazyPut<IbanCardService>(() => IbanCardService());
    Get.lazyPut<LoyaltyCardService>(() => LoyaltyCardService());

    // Controllers
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<CreditCardController>(() => CreditCardController());
    Get.lazyPut<IbanCardController>(() => IbanCardController());
    Get.lazyPut<LoyaltyCardController>(() => LoyaltyCardController());
    Get.lazyPut<AddCreditCardController>(() => AddCreditCardController());
    Get.lazyPut<AddIbanCardController>(() => AddIbanCardController());
    Get.lazyPut<AddLoyaltyCardController>(() => AddLoyaltyCardController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ChangePinController>(
        () => ChangePinController(Get.find<AuthenticationService>()));
    Get.lazyPut<PremiumController>(() => PremiumController());
  }
}

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.find<HomeController>();
  }
}

class AuthBindings extends Bindings {
  @override
  void dependencies() {
    Get.find<AuthController>();
  }
}

class CreditCardBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CreditCardController>()) {
      Get.lazyPut<CreditCardController>(() => CreditCardController());
    }
  }
}

class AddCreditCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddCreditCardController>(() => AddCreditCardController());
  }
}

class IbanCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IbanCardController>(() => IbanCardController());
  }
}

class AddIbanCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddIbanCardController>(() => AddIbanCardController());
  }
}

class LoyaltyCardBindings extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoyaltyCardController>()) {
      Get.lazyPut<LoyaltyCardController>(() => LoyaltyCardController());
    }
  }
}

class AddLoyaltyCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddLoyaltyCardController>(() => AddLoyaltyCardController());
  }
}

class ChangePinBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChangePinController>(
        () => ChangePinController(Get.find<AuthenticationService>()));
  }
}
