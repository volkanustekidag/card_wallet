import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/constants/app_locales.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';

const List<String> _displayNames = [
  'English',
  'Türkçe',
  'Deutsch',
  'Français',
  'Español',
  'Português',
  'Italiano',
  'Nederlands',
  'Polski',
];

/// Language picker. True when the language changed.
Future<bool?> showLangChoseeBottomSheet(BuildContext context) async {
  final current = context.locale;
  final picked = await showCwChoiceSheet<int>(
    context,
    title: 'cwLanguage'.tr(),
    selected: kAppLocales
        .indexWhere((l) => l.languageCode == current.languageCode),
    options: [
      for (var i = 0; i < kAppLocales.length; i++)
        CwChoice(i, _displayNames[i]),
    ],
  );
  if (picked == null || !context.mounted) return false;
  final locale = kAppLocales[picked];
  if (locale.languageCode == current.languageCode) return false;
  // GetMaterialApp builds MaterialApp with `locale: Get.locale ?? locale`,
  // and Get.locale is seeded only once in initState. Without this the
  // rebuild that setLocale triggers keeps the old locale.
  Get.locale = locale;
  await context.setLocale(locale);
  // Scheduled notifications carry their text; re-render them.
  unawaited(CardReminderService().rescheduleAll(locale: locale));
  return true;
}
