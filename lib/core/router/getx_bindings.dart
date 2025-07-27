import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/core/controllers/change_pin_controller.dart';
import 'package:wallet_app/feature/credit_cards/controller/credit_card_controller.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/feature/iban_card/controller/iban_card_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut<AuthenticationService>(() => AuthenticationService());
    Get.lazyPut<BiometricService>(() => BiometricService());
    Get.lazyPut<CreditCardService>(() => CreditCardService());
    Get.lazyPut<IbanCardService>(() => IbanCardService());

    // Controllers
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<CreditCardController>(() => CreditCardController());
    Get.lazyPut<IbanCardController>(() => IbanCardController());
    Get.lazyPut<AddCreditCardController>(() => AddCreditCardController());
    Get.lazyPut<AddIbanCardController>(() => AddIbanCardController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ChangePinController>(
        () => ChangePinController(Get.find<AuthenticationService>()));
    Get.lazyPut<PremiumController>(() => PremiumController());
  }
}

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
  }
}

class AuthBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController());
  }
}

class CreditCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(CreditCardController());
  }
}

class AddCreditCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AddCreditCardController);
  }
}

class IbanCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(IbanCardController());
  }
}

class AddIbanCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AddIbanCardController());
  }
}

class ChangePinBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(ChangePinController(Get.put(AuthenticationService())));
  }
}
