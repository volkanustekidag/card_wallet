import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/components/dialog/delete_dialog.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/router/getx_bindings.dart';
import 'package:wallet_app/core/services/widget_data_service.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/core/utils/sensitive_clipboard.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/feature/add_loyalty_card/add_loyalty_card_page.dart';
import 'package:wallet_app/feature/loyalty_card/controller/loyalty_card_controller.dart';
import 'package:wallet_app/feature/loyalty_card/utils/loyalty_wallet_action.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/loyalty_card_widget.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/shareable_loyalty_card.dart';

class LoyaltyCardDetailPage extends StatefulWidget {
  final LoyaltyCard card;
  const LoyaltyCardDetailPage({Key? key, required this.card}) : super(key: key);

  @override
  State<LoyaltyCardDetailPage> createState() => _LoyaltyCardDetailPageState();
}

class _LoyaltyCardDetailPageState extends State<LoyaltyCardDetailPage> {
  LoyaltyCard get card => widget.card;

  @override
  void initState() {
    super.initState();
    // Opening the detail (barcode) page IS the "use" event — that's when
    // the cashier sees the code. Fire-and-forget; widget refresh failures
    // shouldn't ever block the page from rendering.
    debugPrint('[LoyaltyCardDetailPage] initState — card=${card.id}/${card.name}');
    WidgetDataService.instance.setLastUsedLoyaltyCard(card);
  }

  @override
  Widget build(BuildContext context) {
    final gradients = LinearGradients().linearGradientList;
    final gradient = gradients[card.colorId.clamp(0, gradients.length - 1)];
    final brand = (card.brand?.isNotEmpty ?? false) ? card.brand! : card.name;
    final hasLogo = LoyaltyBrandResolver.domainFor(brand) != null ||
        (card.website?.isNotEmpty ?? false);

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
                          child: BankLogo(
                            loyaltyBrand: brand,
                            domain: card.website,
                            size: 60,
                          ),
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
                            SensitiveClipboard.copy(card.barcode);
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
                    assetIcon: loyaltyWalletActionAsset(context),
                    label: loyaltyWalletActionLabel(context),
                    onTap: () => addLoyaltyCardToWallet(context, card),
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
    showConfirmActionSheet(
      context: context,
      title: 'deleteCard'.tr(),
      content: 'deleteDataMessage'.tr(),
      onConfirm: () async {
        if (Get.isRegistered<LoyaltyCardController>()) {
          await Get.find<LoyaltyCardController>().removeLoyaltyCard(card);
        }
        Get.back();
      },
    );
  }
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
