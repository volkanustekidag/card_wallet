import 'package:get/get.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/core/controllers/add_iban_card_controller.dart';
import 'package:wallet_app/core/controllers/change_pin_controller.dart';
import 'package:wallet_app/core/controllers/credit_card_controller.dart';
import 'package:wallet_app/core/controllers/home_controller.dart';
import 'package:wallet_app/core/controllers/iban_card_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut<AuthenticationService>(() => AuthenticationService());
    Get.lazyPut<CreditCardService>(() => CreditCardService());
    Get.lazyPut<IbanCardService>(() => IbanCardService());

    // Controllers
    Get.lazyPut<AuthController>(
        () => AuthController(Get.find<AuthenticationService>()));
    Get.lazyPut<CreditCardController>(
        () => CreditCardController(Get.find<CreditCardService>()));
    Get.lazyPut<IbanCardController>(
        () => IbanCardController(Get.find<IbanCardService>()));
    Get.lazyPut<AddCreditCardController>(
        () => AddCreditCardController(Get.find<CreditCardService>()));
    Get.lazyPut<AddIbanCardController>(
        () => AddIbanCardController(Get.find<IbanCardService>()));
    Get.lazyPut<HomeController>(() => HomeController(
        Get.find<CreditCardService>(), Get.find<IbanCardService>()));
    Get.lazyPut<ChangePinController>(
        () => ChangePinController(Get.find<AuthenticationService>()));
  }
}

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(
        Get.find<CreditCardService>(), Get.find<IbanCardService>()));
  }
}

class AuthBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(Get.find<AuthenticationService>()));
  }
}

class CreditCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(CreditCardController(Get.find<CreditCardService>()));
  }
}

class AddCreditCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AddCreditCardController(Get.find<CreditCardService>()));
  }
}

class IbanCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(IbanCardController(Get.find<IbanCardService>()));
  }
}

class AddIbanCardBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AddIbanCardController(Get.find<IbanCardService>()));
  }
}

class ChangePinBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(ChangePinController(Get.put(AuthenticationService())));
  }
}
