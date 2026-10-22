import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/theme_controller.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';

Future<void> showThemeBottomSheet(BuildContext context) async {
  final controller = Get.find<ThemeController>();
  final picked = await showCwChoiceSheet<AppThemeMode>(
    context,
    title: 'cwAppearance'.tr(),
    selected: controller.appThemeMode,
    options: [
      CwChoice(AppThemeMode.system, 'themeSystem'.tr(), icon: CwIcons.phone),
      CwChoice(AppThemeMode.light, 'themeLight'.tr(), icon: CwIcons.sun),
      CwChoice(AppThemeMode.dark, 'themeDark'.tr(), icon: CwIcons.theme),
    ],
  );
  if (picked != null) controller.setThemeMode(picked);
}
