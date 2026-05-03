import 'package:easy_localization/easy_localization.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/core/utils/share_origin.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/core/utils/widget_image_share.dart';
import 'package:wallet_app/core/extensions/snack_bars.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/core/widgets/credit_card_back.dart';
import 'package:wallet_app/core/widgets/credit_card_front.dart';
import 'package:wallet_app/feature/home/widgets/sections/card_kind.dart';
import 'package:wallet_app/feature/home/widgets/sections/featured_card_tile.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/iban_card/utils/iban_card_utils.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/shareable_loyalty_card.dart';

/// Animated detail sheet shown when the user taps "Show" on a card. Per
/// kind: credit cards flip to reveal the back, IBAN cards expose the full IBAN
/// plus a QR, loyalty cards display a full-size barcode. The Hero tag is
/// shared with the carousel so the card grows in from its position.
///
/// Open with [showCardDetailSheet] — it wires up the scale + fade transition.
class CardDetailSheet extends StatefulWidget {
  final WalletItem item;
  const CardDetailSheet({Key? key, required this.item}) : super(key: key);

  @override
  State<CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<CardDetailSheet> {
  bool _isFavorite() => isFavoriteCard(widget.item.card);

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    toggleFavoriteTag(widget.item.card);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final cardWidth = (size.width * 0.86).clamp(280.0, 380.0);
    final cardHeight = cardWidth / 1.586;

    // Loyalty cards get a coloured-gradient sheet that mirrors the detail
    // page chrome — barcode reads better on a card-themed surface, and the
    // brand logo + name centred up top reads like a real loyalty card.
    if (widget.item.kind == WalletItemKind.loyalty) {
      return _LoyaltyDetailSheet(
        card: widget.item.card as LoyaltyCard,
        isFavorite: _isFavorite(),
        onToggleFavorite: _toggleFavorite,
        onClose: () => Navigator.of(context).pop(),
        onShare: () => _share(context),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: kSpaceLg,
        vertical: kSpaceXL,
      ),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          kSpaceLg,
          kSpaceMd,
          kSpaceLg,
          kSpaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Handle(
              onClose: () => Navigator.of(context).pop(),
              onFavorite: _toggleFavorite,
              isFavorite: _isFavorite(),
            ),
            const SizedBox(height: kSpaceMd),
            _CardArea(
              item: widget.item,
              width: cardWidth,
              height: cardHeight,
            ),
            const SizedBox(height: kSpaceLg),
            _CardBody(item: widget.item),
            const SizedBox(height: kSpaceLg),
            _ActionBar(item: widget.item),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (widget.item.kind != WalletItemKind.loyalty) return;
    final card = widget.item.card as LoyaltyCard;
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
}

class _Handle extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  const _Handle({
    required this.onClose,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Spacer(),
        if (onFavorite != null) ...[
          _RoundIconButton(
            icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            iconColor: isFavorite
                ? const Color(0xFFFFB800)
                : colorScheme.onSurface.withValues(alpha: 0.7),
            onTap: onFavorite!,
          ),
          const SizedBox(width: 8),
        ],
        _RoundIconButton(
          icon: Icons.keyboard_arrow_down_rounded,
          iconColor: colorScheme.onSurface.withValues(alpha: 0.7),
          onTap: onClose,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _RoundIconButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class _CardArea extends StatelessWidget {
  final WalletItem item;
  final double width;
  final double height;
  const _CardArea({
    required this.item,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: item.heroTag,
        createRectTween: (begin, end) =>
            MaterialRectArcTween(begin: begin, end: end),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: width,
            height: height,
            child: _CardSurface(item: item, width: width, height: height),
          ),
        ),
      ),
    );
  }
}

class _CardSurface extends StatelessWidget {
  final WalletItem item;
  final double width;
  final double height;
  const _CardSurface({
    required this.item,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case WalletItemKind.credit:
        return _FlipCardSurface(card: item.card as CreditCard);
      case WalletItemKind.iban:
      case WalletItemKind.loyalty:
        return FeaturedCardTile(item: item, width: width, height: height);
    }
  }
}

class _FlipCardSurface extends StatelessWidget {
  final CreditCard card;
  const _FlipCardSurface({required this.card});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: FlipCard(
        direction: FlipDirection.HORIZONTAL,
        speed: 600,
        flipOnTouch: true,
        front: CreditCardFront(creditCard: card),
        back: CreditCardBack(creditCard: card),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final WalletItem item;
  const _CardBody({required this.item});

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case WalletItemKind.credit:
        return _CreditBody(card: item.card as CreditCard);
      case WalletItemKind.iban:
        return _IbanBody(card: item.card as IbanCard);
      case WalletItemKind.loyalty:
        return _LoyaltyBody(card: item.card as LoyaltyCard);
    }
  }
}

class _CreditBody extends StatelessWidget {
  final CreditCard card;
  const _CreditBody({required this.card});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'cardDetailFlipHint'.tr(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        if (card.notes != null && card.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: kSpaceMd),
          _NotesPanel(notes: card.notes!),
        ],
      ],
    );
  }
}

class _IbanBody extends StatelessWidget {
  final IbanCard card;
  const _IbanBody({required this.card});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iban = _formatIban(card.iban);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SelectableText(
          iban,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: kSpaceMd),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: QrImageView(
            data: card.iban,
            size: 168,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
          ),
        ),
        if (card.notes != null && card.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: kSpaceMd),
          _NotesPanel(notes: card.notes!),
        ],
      ],
    );
  }

  String _formatIban(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final buffer = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }
}

class _LoyaltyBody extends StatelessWidget {
  final LoyaltyCard card;
  const _LoyaltyBody({required this.card});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: BarcodeRenderer(
            data: card.barcode,
            format: card.barcodeFormat,
            qrSize: 200,
            barcodeHeight: 110,
          ),
        ),
        const SizedBox(height: kSpaceSm),
        SelectableText(
          card.barcode,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _NotesPanel extends StatelessWidget {
  final String notes;
  const _NotesPanel({required this.notes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        notes,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.78),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final WalletItem item;
  const _ActionBar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SquareAction(
            icon: Icons.copy_rounded,
            label: 'actCopy'.tr(),
            onTap: () => _copy(context),
          ),
        ),
        const SizedBox(width: kSpaceSm),
        Expanded(
          child: _SquareAction(
            icon: Icons.ios_share_rounded,
            label: 'actShare'.tr(),
            onTap: () => _share(context),
          ),
        ),
        if (item.kind == WalletItemKind.iban) ...[
          const SizedBox(width: kSpaceSm),
          Expanded(
            child: _SquareAction(
              icon: Icons.fullscreen_rounded,
              label: 'qrCode'.tr(),
              onTap: () => _qrFullscreen(context),
            ),
          ),
        ],
        const SizedBox(width: kSpaceSm),
        Expanded(
          child: _SquareAction(
            icon: Icons.list_alt_rounded,
            label: 'viewAll'.tr(),
            onTap: () => _viewAll(context),
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context) async {
    HapticFeedback.lightImpact();
    final text = _shareText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    context.showSuccessSnackBar('cardCopied');
  }

  Future<void> _share(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (item.kind == WalletItemKind.loyalty) {
      final card = item.card as LoyaltyCard;
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
      return;
    }
    if (!context.mounted) return;
    await Share.share(_shareText(), sharePositionOrigin: shareOriginFromContext(context));
  }

  void _qrFullscreen(BuildContext context) {
    HapticFeedback.lightImpact();
    final iban = (item.card as IbanCard).iban;
    Navigator.of(context).pop();
    IbanCardUtils.showQRFullScreen(
      context,
      qrData: iban,
      beneficiaryName: (item.card as IbanCard).cardHolder,
    );
  }

  void _viewAll(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    String route;
    switch (item.kind) {
      case WalletItemKind.credit:
        route = HomeCardKind.credit.listRoute;
        break;
      case WalletItemKind.iban:
        route = HomeCardKind.iban.listRoute;
        break;
      case WalletItemKind.loyalty:
        route = HomeCardKind.loyalty.listRoute;
        break;
    }
    Get.toNamed(route);
  }

  String _shareText() {
    switch (item.kind) {
      case WalletItemKind.credit:
        final c = item.card as CreditCard;
        return '${c.bankName} • ${c.creditCardNumber} • ${c.cardHolder} • ${c.expirationDate}';
      case WalletItemKind.iban:
        final c = item.card as IbanCard;
        return '${c.bankName}\nIBAN: ${c.iban}\n${c.cardHolder}';
      case WalletItemKind.loyalty:
        final c = item.card as LoyaltyCard;
        final brand = (c.brand?.isNotEmpty ?? false) ? c.brand! : c.name;
        return '$brand • ${c.barcode}';
    }
  }
}

class _SquareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SquareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loyalty-specific detail sheet — gradient backdrop matching the card
/// colour, centred logo + brand header, big white barcode panel, and
/// glass action buttons. Mirrors the layout of [LoyaltyCardDetailPage]
/// but compacted for sheet presentation.
class _LoyaltyDetailSheet extends StatelessWidget {
  final LoyaltyCard card;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onClose;
  final VoidCallback onShare;

  const _LoyaltyDetailSheet({
    required this.card,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onClose,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final gradients = LinearGradients().linearGradientList;
    final gradient = gradients[card.colorId.clamp(0, gradients.length - 1)];
    final brand = (card.brand?.isNotEmpty ?? false) ? card.brand! : card.name;
    final hasLogo = LoyaltyBrandResolver.domainFor(brand) != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: kSpaceLg,
        vertical: kSpaceXL,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(gradient: gradient),
          padding: const EdgeInsets.fromLTRB(
            kSpaceLg,
            kSpaceMd,
            kSpaceLg,
            kSpaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  _GlassIcon(
                    icon: isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    iconColor:
                        isFavorite ? const Color(0xFFFFD466) : Colors.white,
                    onTap: onToggleFavorite,
                  ),
                  const SizedBox(width: 8),
                  _GlassIcon(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: onClose,
                  ),
                ],
              ),
              const SizedBox(height: kSpaceLg),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasLogo)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: BankLogo(loyaltyBrand: brand, size: 56),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    card.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: kSpaceLg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceLg,
                  vertical: kSpaceLg,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BarcodeRenderer(
                      data: card.barcode,
                      format: card.barcodeFormat,
                      qrSize: 200,
                      barcodeHeight: 120,
                    ),
                    const SizedBox(height: 14),
                    SelectableText(
                      _formatBarcodeText(card.barcode),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.barcodeFormat == 'QR_CODE'
                          ? 'QR CODE'
                          : card.barcodeFormat.replaceAll('_', ' '),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: const Color(0xFF1A1D24).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (card.notes != null && card.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: kSpaceMd),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    card.notes!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: kSpaceLg),
              Row(
                children: [
                  Expanded(
                    child: _GlassButton(
                      icon: Icons.copy_rounded,
                      label: 'actCopy'.tr(),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: card.barcode));
                        Get.context?.showSuccessSnackBar('cardCopied');
                      },
                    ),
                  ),
                  const SizedBox(width: kSpaceSm),
                  Expanded(
                    child: _GlassButton(
                      icon: Icons.ios_share_rounded,
                      label: 'actShare'.tr(),
                      onTap: onShare,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  const _GlassIcon({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassButton({
    required this.icon,
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

/// Open the detail sheet with a scale + fade transition. The sheet itself
/// renders inside a [Dialog]; this helper is just the entry point.
Future<void> showCardDetailSheet(BuildContext context, WalletItem item) {
  return showGeneralDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: kSlowAnim,
    pageBuilder: (_, __, ___) => CardDetailSheet(item: item),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: kHomeCurve);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
