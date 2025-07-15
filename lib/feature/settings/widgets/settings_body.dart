import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/constants/paddings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wallet_app/core/router/getx_routes.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/lang_bottom_sheet.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/privacy_policy_bottom_sheet.dart';
import 'package:wallet_app/feature/settings/dialog/delete_dialog.dart';
import 'package:wallet_app/feature/settings/widgets/settings_card.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const PaddingConstants.normal(),
        child: Column(
          children: [
            SettingsCard(
              iconData: Icons.language,
              title: "lang".tr(),
              trailing: null,
              onTap: () => showLangChoseeBottomSheet(context),
            ),
            SettingsCard(
              iconData: Icons.delete,
              title: "clearAllD".tr(),
              trailing: null,
              onTap: () => showDialogDeleteData(context),
            ),
            SettingsCard(
                iconData: Icons.privacy_tip,
                title: "PP".tr(),
                trailing: null,
                onTap: () => showPrivacyPolicyBottomSheet(context)),
            SettingsCard(
              iconData: Icons.password,
              title: "chanPIN".tr(),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
              ),
              onTap: () => Get.toNamed(AppRoutes.changePin),
            )
          ],
        ),
      ),
    );
  }
}
