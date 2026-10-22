import 'dart:async';
import 'dart:io';

import 'package:apple_passkit/apple_passkit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/services/wallet_pass_export_service.dart';
import 'package:wallet_app/core/services/app_lock_service.dart';
import 'package:wallet_app/core/services/analytics_service.dart';
import 'package:wallet_app/core/services/error_reporter.dart';
import 'package:wallet_app/core/utils/premium_gate.dart';

/// Shared "Add to Apple Wallet / Google Wallet" entry point. Used by the
/// loyalty card detail page and the home detail sheet so both surfaces fire
/// the same flow: render gradient-derived pass colours, hit the export
/// service, hand the response to the platform-native add (PassKit / Google
/// Wallet save), and fall back to the launch URL when native isn't
/// available.

/// Localized label for the wallet button. Falls back to a neutral string on
/// platforms where Wallet integration isn't supported.
String loyaltyWalletActionLabel(BuildContext context) {
  final provider = _providerForPlatform(context);
  if (provider == WalletPassProvider.apple) {
    return 'addToAppleWalletAction'.tr();
  }
  if (provider == WalletPassProvider.google) {
    return 'addToGoogleWalletAction'.tr();
  }
  return 'addToWalletAction'.tr();
}

/// Asset path for the platform-native wallet glyph (used as a leading icon).
/// Returns null when no asset is bundled for the current platform.
String? loyaltyWalletActionAsset(BuildContext context) {
  final provider = _providerForPlatform(context);
  if (provider == WalletPassProvider.apple) {
    return 'assets/icons/wallets/apple_wallet.png';
  }
  if (provider == WalletPassProvider.google) {
    return 'assets/icons/wallets/google_wallet.png';
  }
  return null;
}

/// Hands the loyalty card off to the platform's native wallet app. Shows a
/// loading dialog during the round-trip; surfaces export / network errors
/// via snackbars; falls back to the export service's launchUri when native
/// flows aren't available.
Future<void> addLoyaltyCardToWallet(
  BuildContext context,
  LoyaltyCard card,
) async {
  if (!PremiumService.isPremium) {
    await openPremiumGate('walletExport');
    return;
  }

  final provider = _providerForPlatform(context);
  if (provider == null) {
    context.showErrorSnackBar('walletExportPlatformUnsupported');
    return;
  }

  final analytics = AnalyticsService.instance;
  final providerName = provider.name;
  void fail(String errorKey) => analytics.logWalletExportFailed(
        provider: providerName,
        errorKey: errorKey,
      );
  analytics.logWalletExportAttempt(providerName);

  final service = WalletPassExportService();
  if (!service.isConfigured) {
    fail('walletExportNotConfigured');
    context.showErrorSnackBar('walletExportNotConfigured');
    return;
  }
  if (!service.isBarcodeSupported(provider, card)) {
    final key = service.unsupportedBarcodeMessageKey(provider);
    fail(key);
    context.showErrorSnackBar(key);
    return;
  }

  HapticFeedback.lightImpact();
  var loadingShown = false;
  try {
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      barrierDismissible: false,
    );
    loadingShown = true;

    final colors = _walletPassColors(card);
    final response = await service.createLoyaltyPass(
      provider: provider,
      card: card,
      locale: context.locale.toLanguageTag(),
      backgroundColor: colors.background,
      foregroundColor: colors.foreground,
      labelColor: colors.label,
    );
    if (loadingShown && Get.isDialogOpen == true) {
      Get.back();
      loadingShown = false;
    }
    if (!context.mounted) return;

    if (provider == WalletPassProvider.apple) {
      final added = await _presentApplePass(response.launchUri);
      if (added) {
        analytics.logWalletExportSuccess(providerName);
        return;
      }
      // Native PassKit reddetti — Safari fallback'e düş.
    }

    if (provider == WalletPassProvider.google) {
      final added = await _presentGooglePass(response.launchUri);
      if (added == true) {
        analytics.logWalletExportSuccess(providerName);
        return;
      }
      if (added == false) {
        // kullanıcı iptal etti, fallback açma
        fail('canceled');
        return;
      }
      // null = native başarısız, Chrome fallback'e düş.
    }

    final opened = await AppLockService.guard(() => launchUrl(
      response.launchUri,
      mode: LaunchMode.externalApplication,
    ));
    if (opened) {
      // Browser fallback: the add itself completes on the wallet web page.
      analytics.logWalletExportSuccess(providerName);
    } else {
      fail('walletExportOpenFailed');
      if (context.mounted) context.showErrorSnackBar('walletExportOpenFailed');
    }
  } on WalletPassExportException catch (e) {
    if (loadingShown && Get.isDialogOpen == true) {
      Get.back();
      loadingShown = false;
    }
    fail(e.messageKey);
    if (!context.mounted) return;
    if (e.messageKey == 'walletExportNetworkError' ||
        e.messageKey == 'walletExportTimeout') {
      // Offline: the card itself works without a connection.
      final retry = await showOfflineWalletSheet(context);
      if (retry && context.mounted) {
        await addLoyaltyCardToWallet(context, card);
      }
      return;
    }
    context.showErrorSnackBar(e.messageKey);
  } catch (e, st) {
    if (loadingShown && Get.isDialogOpen == true) {
      Get.back();
      loadingShown = false;
    }
    fail('walletExportFailed');
    ErrorReporter.report(e, st, reason: 'walletExport');
    if (context.mounted) context.showErrorSnackBar('walletExportFailed');
  }
}

WalletPassProvider? _providerForPlatform(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
      return WalletPassProvider.apple;
    case TargetPlatform.android:
      return WalletPassProvider.google;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return null;
  }
}

Future<bool> _presentApplePass(Uri passUri) async {
  try {
    final passKit = ApplePassKit();
    final isAvailable = await passKit.isPassLibraryAvailable();
    final canAddPasses = await passKit.canAddPasses();
    if (!isAvailable || !canAddPasses) return false;

    final passBytes = await _downloadPkPass(passUri);
    await AppLockService.guard(() => passKit.addPass(passBytes));
    return true;
  } catch (e, st) {
    debugPrint('Apple PassKit native add failed: $e\n$st');
    return false;
  }
}

Future<Uint8List> _downloadPkPass(Uri passUri) async {
  // Cloud Run + Dart HttpClient bazı durumlarda stream'i yarıda kapatıyor
  // ("Connection closed while receiving data"). Bir kez retry yap.
  HttpException? lastError;
  for (var attempt = 0; attempt < 2; attempt++) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 30)
      ..autoUncompress = false;
    try {
      final request =
          await client.getUrl(passUri).timeout(const Duration(seconds: 20));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.apple.pkpass')
        ..set(HttpHeaders.acceptEncodingHeader, 'identity')
        ..set(HttpHeaders.connectionHeader, 'close');
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const WalletPassExportException('walletExportOpenFailed');
      }
      return await consolidateHttpClientResponseBytes(response);
    } on TimeoutException {
      throw const WalletPassExportException('walletExportTimeout');
    } on SocketException {
      throw const WalletPassExportException('walletExportNetworkError');
    } on HttpException catch (e) {
      lastError = e;
    } finally {
      client.close(force: true);
    }
  }
  throw lastError ?? const WalletPassExportException('walletExportOpenFailed');
}

/// Returns:
/// - true  → kart başarıyla eklendi
/// - false → kullanıcı iptal etti (fallback yok)
/// - null  → native Google Wallet kullanılamadı, Chrome fallback gerekir
Future<bool?> _presentGooglePass(Uri passUri) async {
  final jwt = passUri.pathSegments.isNotEmpty ? passUri.pathSegments.last : '';
  if (jwt.isEmpty) return null;
  try {
    const channel = MethodChannel('app.cardwallet/google_wallet');
    final ok = await AppLockService.guard(() => channel.invokeMethod<bool>(
          'saveToWallet',
          <String, dynamic>{'jwt': jwt},
        ));
    return ok;
  } on MissingPluginException {
    // iOS veya channel kayıtlı değil — fallback iste.
    return null;
  } catch (e, st) {
    debugPrint('Google Wallet native add failed: $e\n$st');
    return null;
  }
}

class _WalletPassColors {
  final String background;
  final String foreground;
  final String label;
  const _WalletPassColors({
    required this.background,
    required this.foreground,
    required this.label,
  });
}

_WalletPassColors _walletPassColors(LoyaltyCard card) {
  // Same colours the card has in the app (brand colour or material).
  final blended = materialForItem(WalletItem.loyalty(card)).base;
  final useDarkText = blended.computeLuminance() > 0.55;
  return _WalletPassColors(
    background: _rgbString(blended),
    foreground: useDarkText ? 'rgb(20,20,20)' : 'rgb(255,255,255)',
    label: useDarkText ? 'rgb(60,60,60)' : 'rgb(235,235,235)',
  );
}

String _rgbString(Color c) {
  final r = (c.r * 255).round();
  final g = (c.g * 255).round();
  final b = (c.b * 255).round();
  return 'rgb($r,$g,$b)';
}

/// "You're offline" — adding to Apple/Google Wallet needs the network for a
/// moment; the barcode works here regardless. True = try again.
Future<bool> showOfflineWalletSheet(BuildContext context) async {
  final retry = await showCwSheet<bool>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CwIcon(CwIcons.offline, size: 34, color: c.ink),
              const SizedBox(height: 12),
              Text('cwOfflineTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
              const SizedBox(height: 6),
              Text('cwOfflineBody'.tr(),
                  textAlign: TextAlign.center,
                  style: CwType.callout.copyWith(color: c.ink2, height: 1.4)),
              const SizedBox(height: 20),
              CwButton('cwShowBarcode'.tr(),
                  onPressed: () => Navigator.pop(sheet, false)),
              const SizedBox(height: 6),
              CwButton.ghost('tryAgain'.tr(),
                  onPressed: () => Navigator.pop(sheet, true)),
            ],
          ),
        ),
      );
    },
  );
  return retry == true;
}
