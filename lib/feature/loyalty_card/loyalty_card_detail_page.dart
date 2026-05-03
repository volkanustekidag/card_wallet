import 'dart:async';
import 'dart:io';

import 'package:apple_passkit/apple_passkit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/services/wallet_pass_export_service.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/loyalty_card_widget.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/shareable_loyalty_card.dart';

class LoyaltyCardDetailPage extends StatelessWidget {
  final LoyaltyCard card;
  const LoyaltyCardDetailPage({Key? key, required this.card}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradients = LinearGradients().linearGradientList;
    final gradient = gradients[card.colorId.clamp(0, gradients.length - 1)];
    final brand = (card.brand?.isNotEmpty ?? false) ? card.brand! : card.name;
    final hasLogo = LoyaltyBrandResolver.domainFor(brand) != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () => _onEdit(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: () => _onDelete(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient shell — Hero target. Animates from the list card's
          // gradient rectangle (rounded, card-sized) up to a full-screen
          // square. The shuttle interpolates the radius and shadow so the
          // morph reads as a card "opening".
          Positioned.fill(
            child: Hero(
              tag: loyaltyCardHeroTag(card),
              flightShuttleBuilder: (
                flightContext,
                animation,
                direction,
                fromContext,
                toContext,
              ) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final t = direction == HeroFlightDirection.push
                        ? animation.value
                        : 1 - animation.value;
                    final radius = 20 * (1 - t);
                    return Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(radius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.16 * (1 - t)),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (hasLogo)
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: BankLogo(loyaltyBrand: brand, size: 60),
                        )
                      else
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.local_offer_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        card.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                          height: 1.15,
                        ),
                      ),
                      if (brand.isNotEmpty && brand != card.name) ...[
                        const SizedBox(height: 4),
                        Text(
                          brand,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BarcodeRenderer(
                              data: card.barcode,
                              format: card.barcodeFormat,
                            ),
                            const SizedBox(height: 18),
                            SelectableText(
                              _formatBarcodeText(card.barcode),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1D24),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              card.barcodeFormat == 'QR_CODE'
                                  ? 'QR CODE'
                                  : card.barcodeFormat.replaceAll('_', ' '),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.6,
                                color: const Color(0xFF1A1D24)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'increaseBrightnessHint'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _GlassButton(
                          icon: Icons.copy_rounded,
                          label: 'copyBarcodeAction'.tr(),
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: card.barcode));
                            HapticFeedback.lightImpact();
                            Get.context?.showSuccessSnackBar('copyInfo');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GlassButton(
                          icon: Icons.ios_share_rounded,
                          label: 'actShare'.tr(),
                          onTap: () => _onShare(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _GlassButton(
                    icon: Icons.account_balance_wallet_rounded,
                    assetIcon: _walletActionAsset(context),
                    label: _walletActionLabel(context),
                    onTap: () => _onAddToWallet(context),
                  ),
                  if (card.notes != null && card.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        card.notes!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _walletActionLabel(BuildContext context) {
    final provider = _providerForPlatform(context);
    if (provider == WalletPassProvider.apple) {
      return 'addToAppleWalletAction'.tr();
    }
    if (provider == WalletPassProvider.google) {
      return 'addToGoogleWalletAction'.tr();
    }
    return 'addToWalletAction'.tr();
  }

  String? _walletActionAsset(BuildContext context) {
    final provider = _providerForPlatform(context);
    if (provider == WalletPassProvider.apple) {
      return 'assets/icons/wallets/apple_wallet.png';
    }
    if (provider == WalletPassProvider.google) {
      return 'assets/icons/wallets/google_wallet.png';
    }
    return null;
  }

  String _formatBarcodeText(String raw) {
    if (raw.length <= 4) return raw;
    final chars = raw.split('');
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(chars[i]);
    }
    return buffer.toString();
  }

  Future<void> _onAddToWallet(BuildContext context) async {
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

      final colors = _walletPassColors();
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
    throw lastError ??
        const WalletPassExportException('walletExportOpenFailed');
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

  _WalletPassColors _walletPassColors() {
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

  Future<void> _onShare(BuildContext context) async {
    HapticFeedback.lightImpact();
    final brandLogo =
        await ShareableLoyaltyCard.precacheBrandLogo(context, card);
    if (!context.mounted) return;
    await shareWidgetAsImage(
      context: context,
      widget: ShareableLoyaltyCard(
        card: card,
        brandLogoImage: brandLogo,
      ),
      size: const Size(
        ShareableLoyaltyCard.width,
        ShareableLoyaltyCard.height,
      ),
      filename: 'loyalty-${card.id}.png',
    );
  }

  void _onEdit() {
    Get.off(
      () => AddLoyaltyCardPage(card: card),
      binding: AddLoyaltyCardBindings(),
    );
  }

  void _onDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => CustomDialog(
        title: 'deleteCard'.tr(),
        content: 'deleteDataMessage'.tr(),
        onConfirm: () async {
          if (Get.isRegistered<LoyaltyCardController>()) {
            await Get.find<LoyaltyCardController>().removeLoyaltyCard(card);
          }
          Get.back();
        },
      ),
    );
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

/// Translucent action button — sits on top of the card-coloured gradient
/// so it has to read against any backdrop. We give it a tinted-white fill
/// + thin white border instead of a solid pill so the gradient still
/// shows through faintly.
class _GlassButton extends StatefulWidget {
  final IconData icon;
  final String? assetIcon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    this.assetIcon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _down = v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.assetIcon != null)
                  Image.asset(
                    widget.assetIcon!,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(widget.icon, size: 16, color: Colors.white),
                  )
                else
                  Icon(widget.icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
