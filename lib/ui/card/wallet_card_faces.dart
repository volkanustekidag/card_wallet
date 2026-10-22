import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/domain/models/loyalty_card_model/loyalty_card.dart';
import 'package:wallet_app/core/utils/card_number_layout.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';
import 'package:wallet_app/core/widgets/card_network_badge.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/ui/card/card_face.dart';
import 'package:wallet_app/ui/card/card_material.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/typography.dart';

/// Standard card proportions (ISO/IEC 7810 ID-1).
const double kCardAspect = 1.586;

/// Inner padding shared by stack strips and full faces so the header row
/// sits at the same spot whether a card is tucked away or in front.
const EdgeInsets kCardStripPadding = EdgeInsets.fromLTRB(14, 13, 16, 0);

/// IBAN cards don't store a colour; they share one recognisable material.
const CardMaterial kIbanMaterial = CardMaterial(
  [Color(0xFF2C1458), Color(0xFF6A3BC0), Color(0xFF1F0D44)],
);

CardMaterial materialForItem(WalletItem item) {
  switch (item.kind) {
    case WalletItemKind.credit:
      return CardMaterial.of((item.card as CreditCard).cardColorId);
    case WalletItemKind.iban:
      return kIbanMaterial;
    case WalletItemKind.loyalty:
      final c = item.card as LoyaltyCard;
      final brand = c.brandColor;
      return brand != null
          ? CardMaterial.brand(Color(brand))
          : CardMaterial.of(c.colorId);
  }
}

String typeLabelFor(WalletItemKind kind) {
  switch (kind) {
    case WalletItemKind.credit:
      return 'cwTypeCard'.tr();
    case WalletItemKind.iban:
      return 'cwTypeIban'.tr();
    case WalletItemKind.loyalty:
      return 'cwTypeLoyalty'.tr();
  }
}

String titleForItem(WalletItem item) {
  switch (item.kind) {
    case WalletItemKind.credit:
      final c = item.card as CreditCard;
      return c.bankName.trim().isNotEmpty
          ? c.bankName.trim()
          : 'cwTypeCard'.tr();
    case WalletItemKind.iban:
      final c = item.card as IbanCard;
      return c.bankName.trim().isNotEmpty
          ? c.bankName.trim()
          : 'cwTypeIban'.tr();
    case WalletItemKind.loyalty:
      final c = item.card as LoyaltyCard;
      return c.name.trim().isNotEmpty ? c.name.trim() : (c.brand ?? '');
  }
}

String last4Of(String raw) {
  final d = raw.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
  return d.length <= 4 ? d : d.substring(d.length - 4);
}

/// White rounded logo chip shown on card faces. Falls back to a monogram
/// so a card never shows an empty corner (offline, unknown brand).
class CardLogoChip extends StatelessWidget {
  final WalletItem item;
  final double size;

  const CardLogoChip({super.key, required this.item, this.size = 30});

  /// Logo domain resolved exactly like [BankLogo] does (BIN, IBAN bank
  /// code, brand catalogue, user-entered website, bank name).
  static String? domainOf(WalletItem item) {
    switch (item.kind) {
      case WalletItemKind.credit:
        final c = item.card as CreditCard;
        return BankLogo.domainFor(
            cardNumber: c.creditCardNumber, bankName: c.bankName);
      case WalletItemKind.iban:
        final c = item.card as IbanCard;
        return BankLogo.domainFor(iban: c.iban, bankName: c.bankName);
      case WalletItemKind.loyalty:
        final c = item.card as LoyaltyCard;
        final site = c.website?.trim();
        return BankLogo.domainFor(
          domain: (site != null && site.isNotEmpty) ? site : null,
          loyaltyBrand: (c.brand?.isNotEmpty ?? false) ? c.brand : c.name,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = materialForItem(item);
    final radius = BorderRadius.circular(size * 0.27);
    final monogram = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
      alignment: Alignment.center,
      child: Text(
        titleForItem(item).characters.take(1).toString().toUpperCase(),
        style: TextStyle(
          color: m.base,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.45,
          height: 1,
        ),
      ),
    );
    final d = domainOf(item);
    if (d == null) return monogram;
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return CachedNetworkImage(
      imageUrl: BankLogo.logoUrlFor(d),
      width: size,
      height: size,
      memCacheWidth: px,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) => monogram,
      errorWidget: (_, __, ___) => monogram,
      imageBuilder: (_, image) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
        child: Image(image: image, fit: BoxFit.contain),
      ),
    );
  }
}

/// The header strip every card shows in the wallet stack: logo, name and
/// a right-aligned meta (type, last 4 or a status badge).
class CardStripHeader extends StatelessWidget {
  final WalletItem item;
  final Widget? trailing;

  const CardStripHeader({super.key, required this.item, this.trailing});

  @override
  Widget build(BuildContext context) {
    final fg = materialForItem(item).foreground;
    return Row(
      children: [
        CardLogoChip(item: item),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            titleForItem(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CwType.headline.copyWith(color: fg, fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        trailing ?? _defaultMeta(fg),
      ],
    );
  }

  Widget _defaultMeta(Color fg) {
    switch (item.kind) {
      case WalletItemKind.credit:
        final c = item.card as CreditCard;
        return Text(
          '•• ${last4Of(c.creditCardNumber)}',
          style: CwType.mono(size: 12.5, color: fg.withValues(alpha: 0.85)),
        );
      case WalletItemKind.iban:
      case WalletItemKind.loyalty:
        return Text(
          typeLabelFor(item.kind).toUpperCase(),
          style: CwType.overline.copyWith(color: fg.withValues(alpha: 0.8)),
        );
    }
  }
}

/// Full-size face of any wallet item (used for the open card in the stack,
/// detail headers, paywall fan and share images).
class WalletCardFace extends StatelessWidget {
  final WalletItem item;
  final bool interactive;
  final bool revealNumber;
  final double? width;

  const WalletCardFace({
    super.key,
    required this.item,
    this.interactive = false,
    this.revealNumber = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = width ?? box.maxWidth;
      final h = w / kCardAspect;
      return CardFace(
        material: materialForItem(item),
        width: w,
        height: h,
        interactive: interactive,
        padding: kCardStripPadding.copyWith(bottom: 16),
        child: _body(context, w),
      );
    });
  }

  Widget _body(BuildContext context, double w) {
    final fg = materialForItem(item).foreground;
    final small = CwType.overline.copyWith(
      color: fg.withValues(alpha: 0.62),
      fontSize: 9.5,
    );
    switch (item.kind) {
      case WalletItemKind.credit:
        final c = item.card as CreditCard;
        final network = CardBankDetector.networkFor(c.creditCardNumber);
        final number = revealNumber
            ? CardNumberLayout.format(c.creditCardNumber)
            : '••••  ••••  ••••  ${last4Of(c.creditCardNumber)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardStripHeader(
              item: item,
              trailing: network == CardNetwork.unknown
                  ? null
                  : CardNetworkBadge(network: network, height: 22),
            ),
            const Spacer(),
            Container(
              width: w * 0.11,
              height: w * 0.08,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: const LinearGradient(
                  colors: [Color(0xFFECD592), Color(0xFFB8913C)],
                ),
              ),
            ),
            SizedBox(height: w * 0.04),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                number,
                style:
                    CwType.mono(size: w * 0.052, color: fg, letterSpacing: 0.5),
              ),
            ),
            SizedBox(height: w * 0.03),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('cwCardholder'.tr().toUpperCase(), style: small),
                      Text(
                        c.cardHolder.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CwType.caption.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('cwExpires'.tr().toUpperCase(), style: small),
                    Text(
                      c.expirationDate.replaceAll(' ', ''),
                      style: CwType.mono(size: 12, color: fg),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      case WalletItemKind.iban:
        final c = item.card as IbanCard;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardStripHeader(item: item),
            const Spacer(),
            Text('IBAN', style: small),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatIban(c.iban),
                style:
                    CwType.mono(size: w * 0.045, color: fg, letterSpacing: 1),
              ),
            ),
            SizedBox(height: w * 0.035),
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.cardHolder.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CwType.caption.copyWith(color: fg),
                  ),
                ),
                if (c.swiftCode.trim().isNotEmpty)
                  Text(c.swiftCode.trim().toUpperCase(),
                      style: CwType.mono(size: 12, color: fg)),
              ],
            ),
          ],
        );
      case WalletItemKind.loyalty:
        final c = item.card as LoyaltyCard;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardStripHeader(item: item),
            const Spacer(),
            Row(
              children: [
                CwIcon(
                  c.barcodeFormat == 'QR_CODE' ? CwIcons.qr : CwIcons.barcode,
                  size: 18,
                  color: fg.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.barcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        CwType.mono(size: 13, color: fg.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

String formatIban(String raw) {
  final s = raw.replaceAll(' ', '').toUpperCase();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && i % 4 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

/// Small card thumbnail (material + logo) used as a list leading.
class CardThumb extends StatelessWidget {
  final WalletItem item;
  final double width;

  const CardThumb({super.key, required this.item, this.width = 48});

  @override
  Widget build(BuildContext context) {
    final h = width / kCardAspect;
    return CardFace(
      material: materialForItem(item),
      width: width,
      height: h,
      radius: width * 0.13,
      shadow: false,
      padding: EdgeInsets.all(width * 0.09),
      child: Align(
        alignment: Alignment.topLeft,
        child: CardLogoChip(item: item, size: h * 0.48),
      ),
    );
  }
}
