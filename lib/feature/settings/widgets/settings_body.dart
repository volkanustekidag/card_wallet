import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/controllers/theme_controller.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/lang_bottom_sheet.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/privacy_policy_bottom_sheet.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/feature/settings/widgets/premium_card.dart';
import 'package:wallet_app/feature/settings/widgets/settings_card.dart';
import 'package:wallet_app/core/data/services/backup_service.dart';

class SettingsBody extends StatefulWidget {
  const SettingsBody({Key? key}) : super(key: key);

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody> {
  String _getCurrentLanguageName(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.put(AuthController());

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            PremiumCard(),
            SettingsCard(
              iconData: Icons.lightbulb,
              title: "theme".tr(),
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
              onTap: () {},
            ),
            SettingsCard(
              iconData: Icons.language,
              title: _getCurrentLanguageName(context),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () async {
                final languageChanged =
                    await showLangChoseeBottomSheet(context);
                if (languageChanged == true && mounted) {
                  setState(() {});
                }
              },
            ),

            // Biometric Authentication Setting
            Obx(() {
              if (!authController.isBiometricAvailable.value) {
                return const SizedBox.shrink();
              }

              return SettingsCard(
                iconData: Icons.fingerprint,
                title: authController.getBiometricDisplayName(),
                trailing: Switch(
                  value: authController.isBiometricEnabled.value,
                  onChanged: (value) {
                    authController.toggleBiometric(value);
                  },
                  activeColor: Colors.green,
                ),
                onTap: () {
                  authController.toggleBiometric(
                      !authController.isBiometricEnabled.value);
                },
              );
            }),

            SettingsCard(
                iconData: Icons.privacy_tip,
                title: "PP".tr(),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: () => showPrivacyPolicyBottomSheet(context)),
            SettingsCard(
              iconData: Icons.backup,
              title: "backupData".tr(),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () => _createBackup(context),
            ),
            SettingsCard(
              iconData: Icons.restore,
              title: "restoreData".tr(),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () => _restoreBackup(context),
            ),
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

  Future<void> _createBackup(BuildContext context) async {
    try {
      final backupService = BackupService();
      final filePath = await backupService.createBackupFile();

      print(filePath); // For debugging purposes

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'backupSuccess'.tr()} $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Yedekleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'backupError'.tr()} $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('restoreTitle'.tr()),
          content: Text(
              'Bu işlem mevcut tüm verileri silecek ve yedekleme dosyasındaki verilerle değiştirecektir. Devam etmek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                navigator.pop();

                try {
                  final backupService = BackupService();
                  await backupService.restoreFromFile();

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('restoreSuccess'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Geri yükleme hatası: $e');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('${'restoreError'.tr()} $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('yes'.tr()),
            ),
          ],
        );
      },
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
