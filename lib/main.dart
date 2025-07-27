import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/auth_services/authentication_service.dart';
import 'package:wallet_app/core/controllers/theme_controller.dart';
import 'package:wallet_app/core/data/local_services/theme_services/theme_services.dart';
import 'package:wallet_app/core/styles/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Hive initialization
  await Hive.initFlutter();

  // Service initializations
  await CreditCardService().init();
  await IbanCardService().init();
  await AuthenticationService().init();

  // Theme service initialization
  final themeService = ThemeService();
  await themeService.init();

  // Screen orientation settings
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale("tr", "TR"),
        Locale("en", "US"),
        Locale("de", "DE"),
        Locale("fr", "FR"),
      ],
      saveLocale: true,
      path: "assets/docs/lang",
      child: const AppWrapper(),
    ),
  );
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());
    
    return Sizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.routes,
          initialBinding: AppBindings(),
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          title: 'Card Wallet',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeController.themeMode,
        );
      },
    );
  }
}
