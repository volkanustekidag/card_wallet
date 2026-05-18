import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/linear_gradient_color.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/core/widgets/card_network_badge.dart';
import 'package:wallet_app/core/widgets/iban_card_face.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/home/widgets/sections/home_constants.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/feature/loyalty_card/widgets/barcode_renderer.dart';

/// Uniform card-shaped preview used inside the featured carousel. Each kind
/// renders a distinct chrome (chip + number for CC, IBAN block for IBAN,
/// brand label + barcode glyph for loyalty) but the outer dimensions stay
/// fixed so cards line up regardless of type.
class FeaturedCardTile extends StatelessWidget {
  final WalletItem item;
  final double width;
  final double height;

  const FeaturedCardTile({
    Key? key,
    required this.item,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case WalletItemKind.credit:
        return _CreditTile(card: item.card as CreditCard, width: width, height: height);
      case WalletItemKind.iban:
        return _IbanTile(card: item.card as IbanCard, width: width, height: height);
      case WalletItemKind.loyalty:
        return _LoyaltyTile(card: item.card as LoyaltyCard, width: width, height: height);
    }
  }
}

class _CardShell extends StatelessWidget {
  final double width;
  final double height;
  final Gradient gradient;
  final Widget child;

  const _CardShell({
    required this.width,
    required this.height,
    required this.gradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.6,
        ),
        boxShadow: kCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}

class _CreditTile extends StatelessWidget {
  final CreditCard card;
  final double width;
  final double height;
  const _CreditTile({required this.card, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final gradient =
        LinearGradients().linearGradientList[card.cardColorId.clamp(0, LinearGradients().linearGradientList.length - 1)];
    final number = _maskedNumber(card.creditCardNumber);
    final holder = card.cardHolder.isNotEmpty
        ? card.cardHolder.toUpperCase()
        : '----';
    final expiration =
        card.expirationDate.isNotEmpty ? card.expirationDate : 'MM/YY';
    final network = CardBankDetector.networkFor(card.creditCardNumber);

    return _CardShell(
      width: width,
      height: height,
      gradient: gradient,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (network != CardNetwork.unknown)
                  CardNetworkBadge(network: network, height: 22)
                else
                  Text(
                    card.bankName.isNotEmpty ? card.bankName : '',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                const Spacer(),
                Text(
                  'creditCardLabel'.tr().toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            Image.asset(
              'assets/images/chip.png',
              width: 38,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'valid'.tr().toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expiration,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Text(
                    holder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _maskedNumber(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return '•••• •••• •••• ••••';
    if (clean.length < 8) return clean;
    final last4 = clean.substring(clean.length - 4);
    return '•••• •••• •••• $last4';
  }
}

class _IbanTile extends StatelessWidget {
  final IbanCard card;
  final double width;
  final double height;
  const _IbanTile({required this.card, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: IbanCardFace(card: card, boxShadow: kCardShadow),
    );
  }
}

class _LoyaltyTile extends StatelessWidget {
  final LoyaltyCard card;
  final double width;
  final double height;
  const _LoyaltyTile({required this.card, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final gradients = LinearGradients().linearGradientList;
    final gradient = gradients[card.colorId.clamp(0, gradients.length - 1)];
    final brand = (card.brand?.isNotEmpty ?? false) ? card.brand! : card.name;
    final showSubtitle = brand.isNotEmpty && brand != card.name;
    final isQr = card.barcodeFormat == 'QR_CODE';

    return _CardShell(
      width: width,
      height: height,
      gradient: gradient,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _LoyaltyBrandMark(brand: brand, website: card.website),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                          height: 1.1,
                        ),
                      ),
                      if (showSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'loyaltyCardLabel'.tr().toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: BarcodeRenderer(
                        data: card.barcode,
                        format: card.barcodeFormat,
                        qrSize: isQr ? 56 : 240,
                        barcodeHeight: isQr ? 56 : 42,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatBarcodeText(card.barcode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1D24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isQr ? 'QR CODE' : card.barcodeFormat.replaceAll('_', ' '),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: const Color(0xFF1A1D24).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBarcodeText(String raw) {
    if (raw.isEmpty) return '';
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

/// Bank logo (in white chrome) when [bankName] resolves to a known domain;
/// generic account-balance glyph otherwise. Drops in next to the IBAN card
/// header without ever taking zero space — IBANs always need *some* mark
/// in that slot to read like a card.
class _LoyaltyBrandMark extends StatelessWidget {
  final String brand;
  final String? website;
  const _LoyaltyBrandMark({required this.brand, this.website});

  @override
  Widget build(BuildContext context) {
    final hasLogo = LoyaltyBrandResolver.domainFor(brand) != null ||
        (website?.isNotEmpty ?? false);
    if (hasLogo) {
      // 36-dp white chrome to match the original tag-circle footprint —
      // BankLogo's chrome is 26 by default; we wrap it in a sized container
      // so the brand logo lines up with where the tag glyph used to sit.
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(6),
        child: BankLogo(loyaltyBrand: brand, domain: website, size: 24),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.local_offer_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
