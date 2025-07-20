import 'package:get/get.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';

class AuthController extends GetxController {
  final AuthenticationService _authenticationService;

  AuthController(this._authenticationService);

  var isLoading = false.obs;
  var isRegistering = false.obs;
  var hasPassword = false.obs;
  var authenticationSuccess = false.obs;
  var authenticationFailed = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkHavePassword();
  }

  Future<void> checkHavePassword() async {
    try {
      isLoading.value = true;
      await _authenticationService.openBox();
      final result = await _authenticationService.checkHavePassword();

      if (result == null) {
        isRegistering.value = true;
        hasPassword.value = false;
      } else {
        hasPassword.value = true;
        isRegistering.value = false;
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred while checking password');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String password) async {
    try {
      isLoading.value = true;
      final result = await _authenticationService.authenticate(password);

      if (result == true) {
        authenticationSuccess.value = true;
        Get.offAllNamed('/home');
      } else {
        authenticationFailed.value = true;
        // Don't show snackbar here, let the UI handle the error display
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during authentication');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String password) async {
    try {
      isLoading.value = true;
      await _authenticationService.creatPassword(password);
      isRegistering.value = false;
      hasPassword.value = true;
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during registration');
    } finally {
      isLoading.value = false;
    }
  }

  void resetAuthenticationState() {
    authenticationFailed.value = false;
    authenticationSuccess.value = false;
  }
}
