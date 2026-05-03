import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wallet_app/core/utils/loyalty_brand_resolver.dart';
import 'package:wallet_app/feature/add_credit_card/utils/card_bank_detector.dart';

/// Renders a bank's logo by hitting Google's public favicon service
/// (`t3.gstatic.com/faviconV2`). The image is disk-cached via
/// [CachedNetworkImage]: once we've shown a logo it's available offline and
/// on later launches without re-fetching.
///
/// **Failure mode:** if the bank isn't in [CardBankDetector.bankDomainFor],
/// or the image hasn't been cached and we're offline, this widget renders
/// [SizedBox.shrink] — i.e. takes zero space. Whatever sits next to it (the
/// bank name, etc.) stays visible on its own. Set [showWhileLoading] to
/// keep a fixed-size placeholder during the network round-trip; otherwise
/// the widget is invisible until the image is ready.
///
/// Why Google's favicon service: Clearbit's free Logo API was retired
/// after the HubSpot acquisition. Google's `faviconV2` endpoint is free,
/// no key, no rate limit, and returns a properly sized PNG.
class BankLogo extends StatelessWidget {
  /// Card number — preferred source of truth. We run the BIN through
  /// [CardBankDetector.detect] so the logo follows the card number even
  /// when the user has hand-edited the bank name field.
  final String? cardNumber;

  /// IBAN — alternative source of truth for IBAN cards. Decoded by
  /// [CardBankDetector.detectFromIban].
  final String? iban;
  final String? bankName;

  /// Loyalty-program brand (Starbucks, Migros, Nike, ...). Resolved via
  /// [LoyaltyBrandResolver.domainFor]. The widget is named `BankLogo` for
  /// historical reasons but powers any domain-keyed logo lookup.
  final String? loyaltyBrand;
  final String? domain;

  /// Edge length of the inner image. The chrome (white rounded square) is
  /// rendered as `size + 2*padding` when [chrome] is true.
  final double size;

  /// When true, wraps the logo in a white rounded chrome — readable on dark
  /// card gradients. Off by default.
  final bool chrome;

  /// If true, reserve [chrome ? size + 6 : size] worth of space while the
  /// network image is loading. Off by default — most loads finish before a
  /// human eye notices, and reserved-space placeholders look like missing
  /// images on offline cold-starts.
  final bool showWhileLoading;

  const BankLogo({
    Key? key,
    this.cardNumber,
    this.iban,
    this.bankName,
    this.loyaltyBrand,
    this.domain,
    this.size = 20,
    this.chrome = false,
    this.showWhileLoading = false,
  }) : super(key: key);

  /// Resolution order:
  ///   1. Explicit [domain] override (escape hatch for tests).
  ///   2. BIN match from [cardNumber] — credit card flow.
  ///   3. Bank-code match from [iban] — IBAN flow.
  ///   4. Brand lookup from [loyaltyBrand] — loyalty card flow.
  ///   5. Bank-name lookup — last-resort, used when no number is available.
  String? get _domain {
    if (domain != null && domain!.isNotEmpty) return domain;
    if (cardNumber != null && cardNumber!.isNotEmpty) {
      final detected = CardBankDetector.detect(cardNumber!);
      final fromBin = CardBankDetector.bankDomainFor(detected);
      if (fromBin != null) return fromBin;
    }
    if (iban != null && iban!.isNotEmpty) {
      final detected = CardBankDetector.detectFromIban(iban!);
      final fromIban = CardBankDetector.bankDomainFor(detected);
      if (fromIban != null) return fromIban;
    }
    if (loyaltyBrand != null && loyaltyBrand!.isNotEmpty) {
      final fromBrand = LoyaltyBrandResolver.domainFor(loyaltyBrand);
      if (fromBrand != null) return fromBrand;
    }
    return CardBankDetector.bankDomainFor(bankName);
  }

  String _logoUrl(String d) {
    return 'https://t3.gstatic.com/faviconV2'
        '?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL'
        '&url=http://$d&size=128';
  }

  @override
  Widget build(BuildContext context) {
    final d = _domain;
    if (d == null) {
      return const SizedBox.shrink();
    }

    final url = _logoUrl(d);

    final hidden = const SizedBox.shrink();
    final reserved = SizedBox(
      width: chrome ? size + 6 : size,
      height: chrome ? size + 6 : size,
    );

    return CachedNetworkImage(
      imageUrl: url,
      width: chrome ? size + 6 : size,
      height: chrome ? size + 6 : size,
      fit: BoxFit.contain,
      placeholder: (_, __) => showWhileLoading ? reserved : hidden,
      errorWidget: (_, errUrl, error) => hidden,
      memCacheWidth: ((chrome ? size + 6 : size) * 3).round(),
      imageBuilder: (context, image) {
        final inner = Image(image: image, width: size, height: size, fit: BoxFit.contain);
        if (!chrome) return inner;
        return Container(
          width: size + 6,
          height: size + 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(3),
          child: inner,
        );
      },
    );
  }
}
