import 'dart:async';
import 'dart:io';

import 'package:apple_passkit/apple_passkit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/services/premium_service.dart';
import 'package:wallet_app/core/services/wallet_pass_export_service.dart';

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
    await Get.toNamed('/premium', arguments: {'feature': 'walletExport'});
    return;
  }

  final provider = _providerForPlatform(context);
  if (provider == null) {
    context.showErrorSnackBar('walletExportPlatformUnsupported');
    return;
  }

  final service = WalletPassExportService();
  if (!service.isConfigured) {
    context.showErrorSnackBar('walletExportNotConfigured');
    return;
  }
  if (!service.isBarcodeSupported(provider, card)) {
    context.showErrorSnackBar(service.unsupportedBarcodeMessageKey(provider));
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
    debugPrint(
      'Wallet pass colors → bg=${colors.background} fg=${colors.foreground} '
      'label=${colors.label} (colorId=${card.colorId})',
    );
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
      if (added) return;
      // Native PassKit reddetti — Safari fallback'e düş.
    }

    if (provider == WalletPassProvider.google) {
      final added = await _presentGooglePass(response.launchUri);
      if (added == true) return;
      if (added == false) return; // kullanıcı iptal etti, fallback açma
      // null = native başarısız, Chrome fallback'e düş.
    }

    final opened = await launchUrl(
      response.launchUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      context.showErrorSnackBar('walletExportOpenFailed');
    }
  } on WalletPassExportException catch (e) {
    if (loadingShown && Get.isDialogOpen == true) {
      Get.back();
      loadingShown = false;
    }
    if (context.mounted) context.showErrorSnackBar(e.messageKey);
  } catch (e, st) {
    if (loadingShown && Get.isDialogOpen == true) {
      Get.back();
      loadingShown = false;
    }
    debugPrint('Wallet export failed: $e\n$st');
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
    await passKit.addPass(passBytes);
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
    final ok = await channel.invokeMethod<bool>(
      'saveToWallet',
      <String, dynamic>{'jwt': jwt},
    );
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
  final gradients = LinearGradients().linearGradientList;
  final gradient = gradients[card.colorId.clamp(0, gradients.length - 1)];
  final colors = gradient.colors;
  final blended = _blendColors(colors);
  final useDarkText = blended.computeLuminance() > 0.55;
  return _WalletPassColors(
    background: _rgbString(blended),
    foreground: useDarkText ? 'rgb(20,20,20)' : 'rgb(255,255,255)',
    label: useDarkText ? 'rgb(60,60,60)' : 'rgb(235,235,235)',
  );
}

Color _blendColors(List<Color> colors) {
  if (colors.isEmpty) return const Color(0xFF1C1F26);
  if (colors.length == 1) return colors.first;
  var r = 0, g = 0, b = 0;
  for (final c in colors) {
    r += (c.r * 255).round();
    g += (c.g * 255).round();
    b += (c.b * 255).round();
  }
  final n = colors.length;
  return Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
}

String _rgbString(Color c) {
  final r = (c.r * 255).round();
  final g = (c.g * 255).round();
  final b = (c.b * 255).round();
  return 'rgb($r,$g,$b)';
}
