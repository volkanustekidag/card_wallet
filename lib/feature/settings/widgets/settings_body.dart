import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/controllers/theme_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card_service.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/lang_bottom_sheet.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/privacy_policy_bottom_sheet.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/feature/settings/widgets/premium_card.dart';
import 'package:wallet_app/feature/settings/widgets/settings_card.dart';
// import 'package:wallet_app/core/controllers/theme_controller.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            PremiumCard(),
            SettingsCard(
              iconData: Icons.language,
              title: "Tema",
              trailing: GetX<ThemeController>(
                builder: (controller) {
                  return Switch(
                    value: controller.isDarkMode,
                    onChanged: (value) {
                      controller.setDarkMode(value);
                    },
                    activeColor: Colors.blue,
                  );
                },
              ),
              onTap: () => showLangChoseeBottomSheet(context),
            ),
            SettingsCard(
              iconData: Icons.language,
              title: "lang".tr(),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () => showLangChoseeBottomSheet(context),
            ),
            SettingsCard(
              iconData: Icons.password,
              title: "chanPIN".tr(),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () => Get.toNamed(AppRoutes.changePin),
            ),
            SettingsCard(
                iconData: Icons.privacy_tip,
                title: "PP".tr(),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: () => showPrivacyPolicyBottomSheet(context)),
            SettingsCard(
              iconData: Icons.delete,
              title: "clearAllD".tr(),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () => showDialogDeleteData(context),
            ),
            SettingsCard(
                iconData: Icons.rate_review,
                title: "rateApp".tr(),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: () {
                  launchUrl(Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.volkan.wallet_app'));
                }),
          ],
        ),
      ),
    );
  }

  Future<void> showDialogDeleteData(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          onConfirm: () async {
            await CreditCardService().deleteAllData();

            await IbanCardService().deleteAllData();

            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
