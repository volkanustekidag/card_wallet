import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wallet_app/core/data/local_services/card_services/iban_card/iban_qr_generator.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/utils/iban_country_meta.dart';
import 'package:wallet_app/core/utils/locale_upper.dart';
import 'package:wallet_app/core/widgets/bank_logo.dart';

/// IBAN card laid out for sharing as a PNG: holder, bank + logo, the IBAN in
/// groups of four, SWIFT when present and a small "CardWallet" mark. Premium
/// users also get the payment QR ([qrData]); free users get the same card
/// without it.
///
/// Colours are fixed (not theme-driven) so the image reads the same whether
/// it was made in light or dark mode and wherever it is viewed. Long names
/// wrap to two lines and the IBAN scales down instead of overflowing.
class ShareableIbanCard extends StatelessWidget {
  final IbanCard card;

  /// Payment QR payload ([paymentQrData]). Null renders the card without QR.
  final String? qrData;

  /// Pre-resolved bank logo from [precacheBankLogo]; null shows a bank glyph.
  final ImageProvider? bankLogoImage;

  static const double width = 720;
  static const double heightWithoutQr = 600;
  static const double heightWithQr = 1060;

  static Size sizeFor({required bool withQr}) =>
      Size(width, withQr ? heightWithQr : heightWithoutQr);

  const ShareableIbanCard({
    Key? key,
    required this.card,
    this.qrData,
    this.bankLogoImage,
  }) : super(key: key);

  static const _gradient = LinearGradient(
    colors: [Color(0xFF0E9F8B), Color(0xFF134E5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The payment QR from [IBANQRGenerator] (TR Karekod / EPC / ISO 20022
  /// picked by country), without amount. Null when the IBAN can't be encoded.
  static String? paymentQrData(IbanCard card) {
    final result = IBANQRGenerator.generateQRCode(
      IBANQRGenerator.createPaymentData(
        iban: card.iban,
        beneficiaryName: card.cardHolder,
        currency: currencyForIban(card.iban),
        description: card.bankName,
      ),
    );
    return result.success ? result.data : null;
  }

  /// Puts the bank logo [BankLogo] would show into the image cache so the
  /// off-screen capture doesn't race the network fetch. Null when the bank
  /// isn't mapped or the fetch fails.
  static Future<ImageProvider?> precacheBankLogo(
    BuildContext context,
    IbanCard card,
  ) async {
    final domain =
        BankLogo.domainFor(iban: card.iban, bankName: card.bankName);
    if (domain == null) return null;
    final provider = CachedNetworkImageProvider(BankLogo.logoUrlFor(domain));
    try {
      // ignore: use_build_context_synchronously
      await precacheImage(provider, context);
      return provider;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final holder = card.cardHolder.trim();
    final bank = card.bankName.trim();
    final swift = card.swiftCode.trim().toUpperCase();
    final qr = qrData;

    return Container(
      width: width,
      height: qr != null ? heightWithQr : heightWithoutQr,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(48),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BankMark(image: bankLogoImage),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  bank.isNotEmpty ? bank : 'IBAN',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // "Account holder" in every language (fieldHolder says "Card holder").
          _Label('holderPlaceholder'.tr()),
          const SizedBox(height: 6),
          Text(
            holder.isNotEmpty ? holder : '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 28),
          const _Label('IBAN'),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                IBANQRGenerator.formatIBANForDisplay(card.iban),
                maxLines: 1,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),
          if (swift.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _Label('SWIFT'),
            const SizedBox(height: 6),
            Text(
              swift,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.6,
              ),
            ),
          ],
          if (qr != null) ...[
            const SizedBox(height: 36),
            // White plate keeps the QR scannable on any backdrop.
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: QrImageView(
                  data: qr,
                  size: 340,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          const Align(
            alignment: Alignment.centerRight,
            child: _Brand(),
          ),
        ],
      ),
    );
  }
}

class _BankMark extends StatelessWidget {
  final ImageProvider? image;
  const _BankMark({required this.image});

  @override
  Widget build(BuildContext context) {
    final logo = image;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: logo != null
            ? Colors.white
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(14),
      child: logo != null
          ? Image(
              image: logo,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            )
          : const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 48,
            ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      context.upper(text),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}

/// Small, quiet wordmark: "Card" regular + "Wallet" bold.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.75);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_balance_wallet_rounded, size: 18, color: color),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Card',
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
              const TextSpan(
                text: 'Wallet',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
