import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/constants/legal_urls.dart';
import 'package:wallet_app/core/controllers/auth_controller.dart';
import 'package:wallet_app/core/controllers/premium_controller.dart';
import 'package:wallet_app/core/controllers/theme_controller.dart';
import 'package:wallet_app/core/data/local_services/auth_services/biometric_service.dart';
import 'package:wallet_app/core/data/services/backup_service.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/services/barcode_display_boost.dart';
import 'package:wallet_app/core/services/card_reminder_service.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/services/rate_app_service.dart';
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/core/services/wallet_data_wiper.dart';
import 'package:wallet_app/core/utils/locale_format.dart';
import 'package:wallet_app/core/utils/premium_gate.dart';
import 'package:wallet_app/feature/auth/pin_action_page.dart';
import 'package:wallet_app/feature/import/import_page.dart';
import 'package:wallet_app/feature/settings/backup_restore_flow.dart';
import 'package:wallet_app/feature/settings/biometric_toggle_flow.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/auto_lock_bottom_sheet.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/lang_bottom_sheet.dart';
import 'package:wallet_app/feature/settings/bottom_sheet/theme_bottom_sheet.dart';
import 'package:wallet_app/ui/card/card_face.dart';
import 'package:wallet_app/ui/card/card_material.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Settings v2: inset grouped rows — Premium, Security, Checkout,
/// Notifications, Data, General, About. Every row does something real.
class SettingsBody extends StatefulWidget {
  const SettingsBody({Key? key}) : super(key: key);

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<SettingsBody>
    with WidgetsBindingObserver {
  bool? _notificationsEnabled;
  String? _version;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshNotificationStatus();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = '${i.version} (${i.buildNumber})');
    }).catchError((_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshNotificationStatus();
  }

  Future<void> _refreshNotificationStatus() async {
    final enabled = await CardReminderService().notificationsEnabled();
    if (!mounted) return;
    if (enabled != _notificationsEnabled) {
      setState(() => _notificationsEnabled = enabled);
    }
  }

  static String languageName(String code) => switch (code) {
        'tr' => 'Türkçe',
        'de' => 'Deutsch',
        'fr' => 'Français',
        'es' => 'Español',
        'pt' => 'Português',
        'it' => 'Italiano',
        'nl' => 'Nederlands',
        'pl' => 'Polski',
        _ => 'English',
      };

  String _themeLabel(AppThemeMode mode) => switch (mode) {
        AppThemeMode.light => 'themeLight'.tr(),
        AppThemeMode.dark => 'themeDark'.tr(),
        AppThemeMode.system => 'themeSystem'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());
    final c = CwColors.of(context);

    return ListView(
      padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 6),
          child: Text('settings'.tr(),
              style: CwType.display.copyWith(color: c.ink)),
        ),
        _premiumRow(context),
        CwSectionHeader('cwSecSecurity'.tr()),
        Obx(() {
          final hasPin = auth.hasPassword.value;
          return CwGroup(children: [
            CwRow(
              leading: CwIconTile(CwIcons.lock, color: c.ink),
              title: 'cwLockApp'.tr(),
              subtitle: 'lockAppSubtitle'.tr(),
              trailing: CwSwitch(
                value: hasPin,
                onChanged: (v) => _handleAppLockToggle(context, auth, v),
              ),
            ),
            if (auth.isBiometricAvailable.value)
              CwRow(
                leading: CwIconTile(CwIcons.faceId, color: c.ok),
                title: auth.getBiometricDisplayName(),
                trailing: CwSwitch(
                  value: auth.isBiometricEnabled.value,
                  onChanged: (v) => handleBiometricToggle(auth, v),
                ),
              ),
            if (hasPin)
              Obx(() {
                final lock = Get.find<AppLockService>();
                return CwRow(
                  leading: CwIconTile(CwIcons.clock, color: c.accent),
                  title: 'autoLock'.tr(),
                  value: AutoLockTime.label(lock.autoLockSeconds.value),
                  chevron: true,
                  onTap: () => showAutoLockBottomSheet(context),
                );
              }),
            if (hasPin)
              CwRow(
                leading: CwIconTile(CwIcons.hash, color: c.ink2),
                title: 'chanPIN'.tr(),
                chevron: true,
                onTap: () => Get.toNamed('/changePin'),
              ),
            if (auth.isBiometricRecoveryAvailable)
              CwRow(
                leading: CwIconTile(CwIcons.restore, color: c.warn),
                title: 'resetPinTitle'.tr(),
                subtitle: 'resetPinSubtitle'.tr(),
                chevron: true,
                onTap: () => _handleBiometricPinReset(context, auth),
              ),
          ]);
        }),
        CwSectionHeader('cwSecCheckout'.tr()),
        Obx(() {
          final boost = BarcodeDisplayBoost.instance;
          final upNext = UiPrefs.instance.upNext.value;
          return CwGroup(children: [
            CwRow(
              leading: CwIconTile(CwIcons.sun, color: c.warn),
              title: 'barcodeBrightnessTitle'.tr(),
              subtitle: 'barcodeBrightnessSubtitle'.tr(),
              trailing: CwSwitch(
                value: boost.enabled.value,
                onChanged: boost.setEnabled,
              ),
            ),
            CwRow(
              leading: CwIconTile(CwIcons.sparkle, color: c.ok),
              title: 'cwUpNextSetting'.tr(),
              subtitle: 'cwUpNextSettingSub'.tr(),
              trailing: CwSwitch(
                value: upNext,
                onChanged: UiPrefs.instance.setUpNext,
              ),
            ),
          ]);
        }),
        CwSectionHeader('cwSecNotifications'.tr()),
        CwGroup(children: [
          CwRow(
            leading: CwIconTile(CwIcons.bell,
                color: _notificationsEnabled == false ? c.danger : c.accent),
            title: 'notificationsRowTitle'.tr(),
            subtitle: _notificationsEnabled == null
                ? null
                : (_notificationsEnabled!
                    ? 'notificationsStatusEnabled'.tr()
                    : 'notificationsStatusDisabled'.tr()),
            subtitleColor: _notificationsEnabled == false ? c.danger : null,
            trailing: CwIcon(CwIcons.external, size: 16, color: c.mute),
            onTap: () => CardReminderService().openNotificationSettings(),
          ),
        ]),
        CwSectionHeader('cwSecData'.tr()),
        Obx(() {
          final premium = Get.find<PremiumController>().isPremium;
          final last = UiPrefs.instance.lastBackup.value;
          final lastText = last == null
              ? 'cwNever'.tr()
              : LocaleFormat.yearMonthDay(context.locale).format(last);
          return CwGroup(children: [
            CwRow(
              leading: CwIconTile(CwIcons.cloudUp, color: c.accent),
              title: 'cwBackupRestore'.tr(),
              subtitle: 'cwLastBackup'.tr(args: [lastText]),
              trailing: premium
                  ? null
                  : CwPill.accent(context, 'cwPremium'.tr(),
                      icon: CwIcons.gem),
              chevron: premium,
              onTap: premium
                  ? () => _backupSheet(context)
                  : () => openPremiumGate('backupRestore'),
            ),
            CwRow(
              leading: CwIconTile(CwIcons.import, color: c.ok),
              title: 'cwImportRow'.tr(),
              chevron: true,
              onTap: () => Get.to<void>(() => const ImportPage()),
            ),
            CwRow(
              leading: CwIconTile(CwIcons.trash, color: c.danger),
              title: 'cwDeleteAll'.tr(),
              titleColor: c.danger,
              onTap: () => showDialogDeleteData(context),
            ),
          ]);
        }),
        CwSectionHeader('cwSecGeneral'.tr()),
        GetX<ThemeController>(
          builder: (theme) => CwGroup(children: [
            CwRow(
              leading: CwIconTile(CwIcons.globe, color: c.ink2),
              title: 'cwLanguage'.tr(),
              value: languageName(context.locale.languageCode),
              chevron: true,
              onTap: () async {
                final changed = await showLangChoseeBottomSheet(context);
                if (changed == true && mounted) setState(() {});
              },
            ),
            CwRow(
              leading: CwIconTile(CwIcons.theme, color: c.ink2),
              title: 'cwAppearance'.tr(),
              value: _themeLabel(theme.appThemeMode),
              chevron: true,
              onTap: () => showThemeBottomSheet(context),
            ),
          ]),
        ),
        CwSectionHeader('cwSecAbout'.tr()),
        Obx(() {
          final premium = Get.find<PremiumController>().isPremium;
          return CwGroup(children: [
            // Apple 3.1.2(a): a path back to the store-managed subscription.
            if (premium && PremiumService.hasActiveSubscription)
              CwRow(
                leading: CwIconTile(CwIcons.gem, color: c.accent),
                title: 'manageSubscription'.tr(),
                trailing: CwIcon(CwIcons.external, size: 16, color: c.mute),
                onTap: _openManageSubscription,
              ),
            CwRow(
              leading: CwIconTile(CwIcons.star, color: c.warn),
              title: 'rateApp'.tr(),
              chevron: true,
              onTap: () => RateAppService.instance.openStoreListing(),
            ),
            CwRow(
              leading: CwIconTile(CwIcons.shield, color: c.ink2),
              title: 'PP'.tr(),
              trailing: CwIcon(CwIcons.external, size: 16, color: c.mute),
              onTap: () => _launch(LegalUrls.privacyPolicy),
            ),
            CwRow(
              leading: CwIconTile(CwIcons.document, color: c.ink2),
              title: 'termsOfUse'.tr(),
              trailing: CwIcon(CwIcons.external, size: 16, color: c.mute),
              onTap: () => _launch(LegalUrls.termsOfUse),
            ),
          ]);
        }),
        if (_version != null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text('cwVersion'.tr(args: [_version!]),
                textAlign: TextAlign.center,
                style: CwType.caption.copyWith(color: c.mute)),
          ),
        const SizedBox(height: 8),
        CwTrustLine('cwEncryptedLocal'.tr()),
      ],
    );
  }

  Widget _premiumRow(BuildContext context) {
    final c = CwColors.of(context);
    return Obx(() {
      final premium = Get.find<PremiumController>().isPremium;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: CwSpace.gutter),
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(CwRadius.l),
          child: InkWell(
            borderRadius: BorderRadius.circular(CwRadius.l),
            onTap: () => premium
                ? Get.toNamed('/premium')
                : Get.toNamed('/premium',
                    arguments: {'trigger': 'settings'}),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CardFace(
                    material: CardMaterial.of(23),
                    width: 56,
                    height: 36,
                    radius: 7,
                    shadow: false,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          premium
                              ? 'premiumActiveTitle'.tr()
                              : 'cwPremiumRow'.tr(),
                          style: CwType.headline.copyWith(color: c.ink),
                        ),
                        Text('cwPremiumRowSub'.tr(),
                            style: CwType.footnote.copyWith(color: c.mute)),
                      ],
                    ),
                  ),
                  CwIcon(CwIcons.chevronRight, size: 18, color: c.mute),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Future<void> _backupSheet(BuildContext context) async {
    final c = CwColors.of(context);
    final pick = await showCwSheet<String>(
      context,
      builder: (sheet) => SafeArea(
        top: false,
        child: CwGroup(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            CwRow(
              leading: CwIconTile(CwIcons.cloudUp, color: c.accent),
              title: 'cwCreateBackup'.tr(),
              chevron: true,
              onTap: () => Navigator.pop(sheet, 'create'),
            ),
            CwRow(
              leading: CwIconTile(CwIcons.restore, color: c.ok),
              title: 'cwRestoreBackup'.tr(),
              chevron: true,
              onTap: () => Navigator.pop(sheet, 'restore'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || pick == null) return;
    if (pick == 'create') {
      // ignore: use_build_context_synchronously
      await _createBackup(context);
    } else {
      // ignore: use_build_context_synchronously
      await restoreFromBackupFlow(context);
    }
  }

  Future<void> _launch(String url) async {
    final ok = await AppLockService.guard(() =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication));
    if (!ok && mounted) context.showErrorSnackBar('couldNotLaunchUrl');
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
      // ignore: use_build_context_synchronously
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
      // hasPassword on success, so the switch flips on its own.
      final created = await Get.to<bool>(
        () => const PinActionPage(),
        arguments: PinAction.create,
      );
      if (created == true && mounted) {
        // ignore: use_build_context_synchronously
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
          // ignore: use_build_context_synchronously
          context.showSuccessSnackBar('appLockDisabled');
        }
      }
    }
  }

  Future<void> _openManageSubscription() async {
    final uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    final launched = await AppLockService.guard(
        () => launchUrl(uri, mode: LaunchMode.externalApplication));
    if (!launched && mounted) {
      // ignore: use_build_context_synchronously
      context.showErrorSnackBar('couldNotLaunchUrl');
    }
  }

  Future<void> _createBackup(BuildContext context) async {
    final password = await promptBackupPassword(
      context,
      title: 'backupPasswordTitle'.tr(),
      description: 'backupPasswordDescription'.tr(),
      confirmRequired: true,
    );
    if (password == null) return;

    try {
      final filePath = await BackupService().createBackupFile(
        password: password,
        dialogTitle: 'backupData'.tr(),
      );
      if (!mounted) return;
      if (filePath == null) return; // User cancelled the save dialog.
      AnalyticsService.instance.logBackupCreated();
      await UiPrefs.instance.markBackup();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      context.showSuccessSnackBar('backupSuccess'.tr());
    } on BackupError catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      context.showErrorSnackBar(localizeBackupError(e));
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'createBackup');
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      context.showErrorSnackBar('backupError');
    }
  }

  Future<void> showDialogDeleteData(BuildContext context) async {
    final confirmed = await showConfirmActionSheet(
      context: context,
      title: 'areUSure'.tr(),
      cancelText: 'cancel'.tr(),
    );
    if (!confirmed || !mounted) return;

    // Wiping the wallet is as sensitive as turning the lock off: someone
    // holding the unlocked phone must not be able to do it without the PIN.
    final auth = Get.find<AuthController>();
    if (auth.hasPassword.value) {
      final verified = await Get.to<bool>(
        () => const PinActionPage(),
        arguments: PinAction.verify,
      );
      if (verified != true || !mounted) return;
    }

    try {
      await WalletDataWiper().wipe();
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      context.showSuccessSnackBar('deleteAllDataSuccess');
    } catch (e, st) {
      ErrorReporter.report(e, st, reason: 'deleteAllData');
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      context.showErrorSnackBar('deleteAllDataError');
    }
  }
}
