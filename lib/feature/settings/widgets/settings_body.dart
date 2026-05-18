import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/controllers/theme_controller.dart';
import 'package:wallet_app/core/data/local_services/card_services/credi_card/credit_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_card_service.dart';
import 'package:wallet_app/core/data/local_services/card_services/loyalty_card/loyalty_card_service.dart';
import 'package:wallet_app/core/data/services/backup_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/services/rate_app_service.dart';
import 'package:wallet_app/core/widgets/premium_status_widget.dart';
import 'package:wallet_app/feature/auth/pin_action_page.dart';
import 'package:wallet_app/core/widgets/premium_upgrade_widget.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_animations.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/lang_bottom_sheet.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/theme_bottom_sheet.dart';
import 'package:wallet_app/feature/settings/widgets/settings_card.dart';

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
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'it':
        return 'Italiano';
      case 'nl':
        return 'Nederlands';
      case 'pl':
        return 'Polski';
      default:
        return 'English';
    }
  }

  String _themeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'themeLight'.tr();
      case AppThemeMode.dark:
        return 'themeDark'.tr();
      case AppThemeMode.system:
        return 'themeSystem'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FadeSlideIn(
              delay: Duration.zero,
              child: PremiumUpgradeWidget(margin: EdgeInsets.only(bottom: 8)),
            ),
            const FadeSlideIn(
              delay: Duration(milliseconds: 60),
              child: PremiumStatusWidget(margin: EdgeInsets.only(bottom: 8)),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: _buildAppearanceSection(context),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: _buildSecuritySection(context, authController),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: _buildDataSection(context),
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 380),
              child: _buildAboutSection(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    return _Section(
      title: 'sectionAppearance'.tr(),
      children: [
        GetX<ThemeController>(
          builder: (controller) {
            return SettingsCard(
              iconData: Icons.lightbulb,
              title: 'theme'.tr(),
              subtitle: _themeLabel(controller.appThemeMode),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => showThemeBottomSheet(context),
            );
          },
        ),
        SettingsCard(
          iconData: Icons.language,
          title: _getCurrentLanguageName(context),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            final languageChanged = await showLangChoseeBottomSheet(context);
            if (languageChanged == true && mounted) {
              setState(() {});
            }
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySection(
    BuildContext context,
    AuthController authController,
  ) {
    return _Section(
      title: 'sectionSecurity'.tr(),
      children: [
        Obx(() {
          // Master toggle. Off by default for fresh installs; flips on/off
          // via PinActionPage (create / verify) so we never quietly mutate
          // the encrypted PIN box from a switch tap.
          return SettingsCard(
            iconData: Icons.lock_outline_rounded,
            title: 'lockApp'.tr(),
            subtitle: 'lockAppSubtitle'.tr(),
            trailing: Switch(
              value: authController.hasPassword.value,
              onChanged: (value) =>
                  _handleAppLockToggle(context, authController, value),
            ),
            onTap: () => _handleAppLockToggle(
              context,
              authController,
              !authController.hasPassword.value,
            ),
          );
        }),
        Obx(() {
          final premiumController = Get.find<PremiumController>();
          if (!authController.isBiometricAvailable.value) {
            return const SizedBox.shrink();
          }
          final isPremium = premiumController.isPremium;
          // Same Switch / arrow chrome regardless of premium state. Tapping
          // when not premium routes to the paywall; tapping without a PIN
          // routes through PIN creation first (biometric is a shortcut to
          // skip PIN entry, so it has no meaning without one).
          return SettingsCard(
            iconData: Icons.fingerprint,
            title: authController.getBiometricDisplayName(),
            premiumLocked: !isPremium,
            trailing: Switch(
              value: isPremium && authController.isBiometricEnabled.value,
              onChanged: (value) =>
                  _handleBiometricToggle(authController, isPremium, value),
            ),
            onTap: () => _handleBiometricToggle(
              authController,
              isPremium,
              !authController.isBiometricEnabled.value,
            ),
          );
        }),
        Obx(() {
          if (!authController.hasPassword.value) {
            return const SizedBox.shrink();
          }
          return SettingsCard(
            iconData: Icons.pin,
            title: 'chanPIN'.tr(),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Get.toNamed('/changePin'),
          );
        }),
        Obx(() {
          // Biometric-gated PIN reset. Surfaces only when there is a PIN to
          // reset *and* the device has biometric enrollment we can use as
          // proof of ownership. Independent of the in-app biometric login
          // toggle — recovery is always available if the hardware is.
          if (!authController.isBiometricRecoveryAvailable) {
            return const SizedBox.shrink();
          }
          return SettingsCard(
            iconData: Icons.lock_reset,
            title: 'resetPinTitle'.tr(),
            subtitle: 'resetPinSubtitle'.tr(),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _handleBiometricPinReset(context, authController),
          );
        }),
      ],
    );
  }

  Future<void> _handleBiometricPinReset(
    BuildContext context,
    AuthController authController,
  ) async {
    HapticFeedback.lightImpact();
    final passed = await authController.verifyBiometricForReset();
    if (!passed || !mounted) return;
    final created = await Get.to<bool>(
      () => const PinActionPage(),
      arguments: PinAction.create,
    );
    if (created == true && mounted) {
      context.showSuccessSnackBar('resetPinSuccess');
    }
  }

  Future<void> _handleAppLockToggle(
    BuildContext context,
    AuthController authController,
    bool desiredValue,
  ) async {
    HapticFeedback.lightImpact();
    if (desiredValue) {
      // Enabling: push the create flow. registerStandalone updates
      // hasPassword on success, so the Obx switch flips on its own.
      final created = await Get.to<bool>(
        () => const PinActionPage(),
        arguments: PinAction.create,
      );
      if (created == true && mounted) {
        context.showSuccessSnackBar('appLockEnabled');
      }
    } else {
      // Disabling: require verification first so a stranger holding the
      // unlocked phone can't strip the lock.
      final verified = await Get.to<bool>(
        () => const PinActionPage(),
        arguments: PinAction.verify,
      );
      if (verified == true) {
        await authController.removePassword();
        if (mounted) {
          context.showSuccessSnackBar('appLockDisabled');
        }
      }
    }
  }

  Future<void> _handleBiometricToggle(
    AuthController authController,
    bool isPremium,
    bool desiredValue,
  ) async {
    HapticFeedback.lightImpact();
    if (!isPremium) {
      Get.toNamed('/premium', arguments: {'feature': 'biometric'});
      return;
    }
    if (desiredValue && !authController.hasPassword.value) {
      // Biometric is a shortcut for the PIN; force the user to set a PIN
      // before enabling biometric so we always have a fallback.
      Get.context?.showInfoSnackBar('setupPinForBiometric');
      final created = await Get.to<bool>(
        () => const PinActionPage(),
        arguments: PinAction.create,
      );
      if (created != true) return;
    }
    await authController.toggleBiometric(desiredValue);
  }

  Widget _buildDataSection(BuildContext context) {
    return _Section(
      title: 'sectionData'.tr(),
      children: [
        Obx(() {
          final premiumController = Get.find<PremiumController>();
          final isPremium = premiumController.isPremium;
          return SettingsCard(
            iconData: Icons.backup,
            title: 'backupData'.tr(),
            premiumLocked: !isPremium,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isPremium
                ? () => _createBackup(context)
                : () => Get.toNamed('/premium',
                    arguments: {'feature': 'backupRestore'}),
          );
        }),
        Obx(() {
          final premiumController = Get.find<PremiumController>();
          final isPremium = premiumController.isPremium;
          return SettingsCard(
            iconData: Icons.restore,
            title: 'restoreData'.tr(),
            premiumLocked: !isPremium,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: isPremium
                ? () => _restoreBackup(context)
                : () => Get.toNamed('/premium',
                    arguments: {'feature': 'backupRestore'}),
          );
        }),
        SettingsCard(
          iconData: Icons.delete,
          title: 'clearAllD'.tr(),
          isDestructive: true,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => showDialogDeleteData(context),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _Section(
      title: 'sectionAbout'.tr(),
      children: [
        // Apple Guideline 3.1.2(a) — surface a path back to the store-managed
        // subscription. Hidden for lifetime / free users since neither has a
        // recurring subscription to manage.
        Obx(() {
          final premiumController = Get.find<PremiumController>();
          if (!premiumController.isPremium || !PremiumService.hasActiveSubscription) {
            return const SizedBox.shrink();
          }
          return SettingsCard(
            iconData: Icons.subscriptions_outlined,
            title: 'manageSubscription'.tr(),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: _openManageSubscription,
          );
        }),
        SettingsCard(
          iconData: Icons.privacy_tip,
          title: 'PP'.tr(),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => launchUrl(
            Uri.parse('https://www.olkan.dev/privacy/cardwallet'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        SettingsCard(
          iconData: Icons.description_outlined,
          title: 'termsOfUse'.tr(),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => launchUrl(
            Uri.parse('https://www.olkan.dev/terms/cardwallet'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        SettingsCard(
          iconData: Icons.rate_review,
          title: 'rateApp'.tr(),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => RateAppService.instance.openStoreListing(),
        ),
      ],
    );
  }

  Future<void> _openManageSubscription() async {
    final uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      // ignore: use_build_context_synchronously
      context.showErrorSnackBar('couldNotLaunchUrl');
    }
  }

  Future<void> _createBackup(BuildContext context) async {
    final password = await _promptPassword(
      context,
      title: 'backupPasswordTitle'.tr(),
      description: 'backupPasswordDescription'.tr(),
      confirmRequired: true,
    );
    if (password == null) return;

    try {
      final backupService = BackupService();
      final filePath = await backupService.createBackupFile(
        password: password,
        dialogTitle: 'backupData'.tr(),
      );
      if (!mounted) return;
      if (filePath == null) return; // User cancelled the save dialog.
      debugPrint(filePath);
      context.showSuccessSnackBar('backupSuccess'.tr());
    } on BackupError catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_localizeBackupError(e));
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('${'backupError'.tr()} $e');
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: Text('restoreTitle'.tr()),
            content: Text('restoreContent'.tr()),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: Text('confirm'.tr()),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      final backupService = BackupService();
      await backupService.restoreFromFile(
        passwordProvider: () async => _promptPassword(
          Get.context ?? context,
          title: 'restorePasswordTitle'.tr(),
          description: 'restorePasswordDescription'.tr(),
          confirmRequired: false,
        ),
      );
      if (!mounted) return;
      context.showSuccessSnackBar('restoreSuccess');
    } on BackupError catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(_localizeBackupError(e));
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('${'restoreError'.tr()} $e');
    }
  }

  String _localizeBackupError(BackupError e) {
    switch (e.kind) {
      case BackupErrorKind.passwordRequired:
        return 'backupPasswordRequired'.tr();
      case BackupErrorKind.wrongPassword:
        return 'backupWrongPassword'.tr();
      case BackupErrorKind.invalidFormat:
        return 'backupInvalidFormat'.tr();
      case BackupErrorKind.io:
        return 'backupIoError'.tr();
    }
  }

  Future<String?> _promptPassword(
    BuildContext context, {
    required String title,
    required String description,
    required bool confirmRequired,
  }) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'backupPasswordLabel'.tr(),
                    ),
                  ),
                  if (confirmRequired) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'backupPasswordConfirmLabel'.tr(),
                      ),
                    ),
                  ],
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, null),
                child: Text('cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  final pw = passwordController.text;
                  if (pw.length < 6) {
                    setLocal(() => errorText = 'backupPasswordTooShort'.tr());
                    return;
                  }
                  if (confirmRequired && pw != confirmController.text) {
                    setLocal(() => errorText = 'backupPasswordMismatch'.tr());
                    return;
                  }
                  Navigator.pop(dialogContext, pw);
                },
                child: Text('confirm'.tr()),
              ),
            ],
          );
        });
      },
    );

    return result;
  }

  Future<void> showDialogDeleteData(BuildContext context) async {
    await showConfirmActionSheet(
      context: context,
      title: 'areUSure'.tr(),
      cancelText: 'cancel'.tr(),
      onConfirm: () async {
        await CreditCardService().deleteAllData();
        await IbanCardService().deleteAllData();
        await LoyaltyCardService().deleteAllData();
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final filtered =
        children.where((c) => c is! SizedBox || c.height != 0).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
